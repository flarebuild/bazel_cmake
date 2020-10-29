use std::env;
use std::fs;
use std::fmt;
use std::result;
use std::process::{Stdio, Command, Output};
use std::collections::{HashSet, HashMap, BTreeMap};
use serde::{Deserialize, Serialize};
use std::io::{BufReader, BufWriter, Write};
use std::path::{PathBuf};

type Result<T> = core::result::Result<T, Box<dyn std::error::Error>>;

#[derive(Debug)]
struct ExitCodeError(i32, String);
impl fmt::Display for ExitCodeError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{} - {}", self.0, self.1)
    }
}

impl std::error::Error for ExitCodeError {}

fn check_exit_code(out: &Output, print_stderr: bool) -> Result<()> {
    if !out.status.success() {
        return Err(Box::new(ExitCodeError(
            out.status.code().unwrap(),
            if print_stderr {
                String::from_utf8_lossy(&out.stderr).to_string()
            } else {
                "".to_owned()
            }
        )))
    }
    Ok(())
}

fn run_cmd(cmd: &mut Command, args: &Args) -> Result<Output> {
    let mut cmd = cmd;
    if args.config.is_some() {
        cmd = cmd
            .arg("--config")
            .arg(args.config.as_ref().unwrap());
    }
    cmd.stdin(Stdio::inherit());
    cmd.stdout(Stdio::piped());
    cmd.stderr(Stdio::inherit());
    println!("#####################");
    println!("{:?}", cmd);
    let res = cmd.output()?;
    check_exit_code(&res, false)?;
    Ok(res)
}

fn get_bazel_info(args: &Args) -> Result<BazelInfo> {
    let mut base_cmd = Command::new("bazel");
    let cmd = base_cmd.arg("info");
    let output = run_cmd(cmd, args)?;
    let mapped: HashMap<String, String> = String::from_utf8_lossy(&output.stdout)
        .lines()
        .map(|x| x.split(": "))
        .map(|mut x| -> Option<(String, String)> {
            let first = x.next();
            let second = x.next();
            if first.is_none() || second.is_none() {
                None
            } else {
                Some((first.unwrap().to_owned(), second.unwrap().to_owned()))
            }
        })
        .filter(Option::is_some)
        .map(Option::unwrap)
        .collect();
    Ok(BazelInfo{
        bazel_bin: mapped["bazel-bin"].clone(),
        output_base: mapped["output_base"].clone(),
    })
}

fn do_query(
    lookup: &str,
    output: &str,
    args: &Args
) -> Result<Output> {
    let mut base_cmd = Command::new("bazel");
    let cmd = base_cmd
        .arg("cquery")
        .arg(&lookup)
        .arg("--output")
        .arg(output);
    run_cmd(cmd, args)
}

fn do_query_list(
    lookup: &str,
    args: &Args
) -> Result<Vec<String>> {
    let out = do_query(lookup, "label", args)?;
    let res: Vec<String> = String::from_utf8_lossy(&out.stdout)
        .lines()
        .map(str::split_ascii_whitespace)
        .map(|mut x| x.next())
        .filter_map(Option::Some)
        .map(|x| x.unwrap().to_owned())
        .collect();
    Ok(res)
}

fn unwrap_package(pkg: &Option<String>) -> String {
    if pkg.is_none() {
        "//".to_owned()
    } else {
        format!("{}/", pkg.as_ref().unwrap())
    }
}

fn query_cc_targets(args: &Args) -> Result<HashSet<String>> {
    let lookup_libraries = format!("kind(cc_library, {}...)", unwrap_package(&args.package));
    let lookup_binaries = format!("kind(cc_binary, {}...)", unwrap_package(&args.package));
    let res: HashSet<String> = [
        do_query_list(&lookup_libraries, args)?,
        do_query_list(&lookup_binaries, args)?
    ].concat()
        .into_iter()
        .collect();
    Ok(res)
}

fn is_inside_package(dep: &str, package: &str) -> bool {
    dep.starts_with(package)
}

fn query_cc_targets_deps(args: &Args) -> Result<HashSet<String>> {
    let pkg = unwrap_package(&args.package);
    let lookup = format!("kind(cc_library, deps({}...))", &pkg);
    let res: HashSet<String> = do_query_list(&lookup, args)?
        .into_iter()
        .filter(|x| !is_inside_package(&x, &pkg))
        .collect();
    Ok(res)
}

struct BazelInfo {
    bazel_bin: String,
    output_base: String,
}

#[derive(Debug, PartialEq, Deserialize, Serialize)]
struct LibInfo {
    shared_lib: String,
    static_lib: String,
    link_whole: bool,
}

#[derive(Debug, PartialEq, Deserialize, Serialize)]
struct CmakeInfo {
    label: String,
    deps: Vec<String>,
    libs: Vec<LibInfo>,
    link_flags: Vec<String>,
    copts: Vec<String>,
    defines: Vec<String>,
    local_defines: Vec<String>,
    include_dirs: Vec<String>,
    hdrs: Vec<String>,
    gen_hdrs: BTreeMap<String, String>,
    srcs: Vec<String>,
    gen_srcs: BTreeMap<String, String>,
    is_executable: bool,
    include_prefix: Option<String>,
}

struct Label {
    repo: Option<String>,
    package: PathBuf,
    name: String,
}

fn targetify(val: &str) -> String {
    val.replace("-","_").replace("/", "_")
}

impl Label {
    fn new(target: &str) -> Result<Self> {
        let mut repo: Option<String> = None;
        let mut package = PathBuf::new();
        let mut name = String::new();

        for part in target
            .split("/")
            .map(str::to_owned)
            .filter(|x| !x.is_empty()) {

            if part.starts_with("@") {
                repo = Some(part[1..].to_owned());
            } else if part.contains(":") {
                name = if part.starts_with(":") {
                    part[1..].to_owned()
                } else {
                    let mut split = part.split(":");
                    package = package.join(split.next().unwrap());
                    split.next().unwrap().to_owned()
                };
            } else {
                package = package.join(part);
            }
        }
        Ok(Label{ repo, package, name, })
    }

    fn to_cmake_target_name(&self) -> String {
        let mut res = String::new();
        if self.repo.is_some() {
            res += &targetify(self.repo.as_ref().unwrap());
            res += "_";
        }
        let package_str = self.package.to_str();
        if package_str.is_some() && !package_str.unwrap().is_empty() {
            res += &targetify(package_str.unwrap());
        }
        res += "_";
        res += &self.name;
        res
    }

    fn to_path(&self, postf: &str) -> PathBuf {
        let mut path = PathBuf::new();
        if self.repo.is_some() {
            path = path.join("external").join(self.repo.as_ref().unwrap());
        }
        path = path.join(&self.package);
        path = path.join(format!("{}{}", &self.name, postf));
        path
    }
}

fn read_cmake_info(target: &str, bazel_info: &BazelInfo) -> Result<CmakeInfo> {
    let label = Label::new(target)?;
    let path =  PathBuf::new()
        .join(&bazel_info.bazel_bin)
        .join(label.to_path("_info.json"));
    if !path.exists() {
        return Err(Box::new(ExitCodeError(127, path.to_string_lossy().to_string())));
    }

    let file = fs::File::open(path)?;
    let reader = BufReader::new(file);

    let mut de = serde_json::Deserializer::from_reader(reader);
    Ok(CmakeInfo::deserialize(&mut de)?)
}

fn get_cmake_infos(
    targets: &HashSet<String>,
    args: &Args,
    bazel_info: &BazelInfo,
    compile: bool
) -> Result<Vec<CmakeInfo>> {
    let mut base_cmd = Command::new("bazel");
    let mut cmd = base_cmd
        .arg("build")
        .args(targets.iter());

    let aspect = if args.link_static {
        "cmake_info_aspect_static"
    } else {
        "cmake_info_aspect_dynamic"
    };

    cmd = cmd
        .arg("--aspects")
        .arg(format!("@build_flare_bazel_cmake//rules:cmake_info_aspect.bzl%{}", aspect));

    if compile {
        cmd = cmd.arg("--output_groups=cmake_info_json,cmake_libs,cmake_gen_hdrs");
    } else {
        cmd = cmd.arg("--output_groups=cmake_info_json,cmake_gen_hdrs,cmake_gen_srcs");
    }

    run_cmd(cmd, args)?;
    let (res, errors): (Vec<_>, Vec<_>) = targets
        .iter()
        .map(|x| read_cmake_info(&x, bazel_info))
        .partition(Result::is_ok);

    for err in errors { err?; }

    Ok(res.into_iter().map(Result::unwrap).collect())
}

fn change_rpath(at: PathBuf, from: &str) -> Result<()> {
    let mut perms = fs::metadata(&at)?.permissions();
    if perms.readonly() {
        perms.set_readonly(false);
        fs::set_permissions(&at, perms)?;
    }
    let input = at.to_str().unwrap().to_owned();
    let res = Command::new("install_name_tool")
        .arg("-change")
        .arg(from)
        .arg(&input)
        .arg(&input)
        .output()?;
    check_exit_code(&res, true)?;
    let res = Command::new("install_name_tool")
        .arg("-id")
        .arg(&input)
        .arg(&input)
        .output()?;
    check_exit_code(&res, true)?;
    Ok(())
}

fn copy_gens(cmake_dir: &str, info: &CmakeInfo, is_interface: bool) -> Result<()> {
    let cmake_dir = PathBuf::new().join(cmake_dir);
    let gens = if is_interface {
        info.gen_hdrs.clone().into_iter()
    } else {
        let mut concat = BTreeMap::new();
        concat.extend(info.gen_hdrs.clone().into_iter());
        concat.extend(info.gen_srcs.clone().into_iter());
        concat.into_iter()
    };
    for (gen_rel, gen_src) in gens {
        let out_path = cmake_dir.join(gen_rel);
        if !out_path.parent().unwrap().exists() {
            fs::create_dir_all(out_path.parent().unwrap())?;
        }
        println!("Copying gen source: {} to {:?}", gen_src, &out_path);
        fs::hard_link(gen_src, out_path)?
    }
    Ok(())
}

fn unwrap_include_path(label: &Label, inpath: &str, bazel_info: &BazelInfo) -> Result<PathBuf> {
    let mut path = PathBuf::new();
    if label.repo.is_some() {
        path = path
            .join(&bazel_info.output_base)
            .join("external")
            .join(label.repo.as_ref().unwrap().to_owned())
    }
    path = if inpath == "." {
        path.join(&label.package)
    } else {
        path.join(inpath)
    };

    Ok(path.canonicalize()?)
}

fn gen_libs(cmake_dir: &str, infos: Vec<CmakeInfo>, args: &Args, bazel_info: &BazelInfo, is_external: bool) -> Result<Vec<String>> {
    let mut res = Vec::new();
    for info in infos.into_iter() {
        println!("Processing target: {}", &info.label);
        if info.include_prefix.is_some() {
            println!("include_prefix: {}", info.include_prefix.as_ref().unwrap());
        }

        let label = Label::new(&info.label)?;
        let cmake_name = label.to_cmake_target_name();
        let out_dir_rel = label.to_path("");
        let out_dir = PathBuf::new().join(cmake_dir).join(out_dir_rel.clone());
        fs::create_dir_all(out_dir.as_path())?;
        let cmake_path_rel = out_dir_rel.join(format!("{}.cmake", &label.name));
        let cmake_path = PathBuf::new()
            .join(cmake_dir)
            .join(cmake_path_rel.clone());
        let cmake_file = fs::File::create(cmake_path)?;
        res.push(cmake_path_rel.to_str().unwrap().to_owned());
        let mut f = BufWriter::new(cmake_file);

        let is_interface = is_external || (!info.is_executable && info.libs.is_empty());

        if is_interface {
            writeln!(f, "add_library({} INTERFACE)\n", &cmake_name)?;
        } else if info.is_executable {
            writeln!(f, "add_executable({})\n", &cmake_name)?;
        } else {
            writeln!(
                f,
                "add_library({} {})\n",
                &cmake_name,
                if args.link_static { "STATIC" }
                else { "SHARED" }
            )?;
        }

        if !info.deps.is_empty() || !info.link_flags.is_empty() || (is_interface && !info.libs.is_empty()) {
            writeln!(f, "target_link_libraries({} {}", &cmake_name, if is_interface { "INTERFACE" } else { "PUBLIC" })?;
            for link_opt in info.link_flags.iter() {
                writeln!(f, "    {}", link_opt)?;
            }
            for dep in info.deps.iter() {
                writeln!(f, "    {}", Label::new(dep)?.to_cmake_target_name())?;
            }
            if is_interface {
                for lib in info.libs.iter() {
                    let lib_name = format!(
                        "lib{}.{}",
                        &label.name,
                        if args.link_static { "a" }
                        else { "so" }
                    );
                    let out_lib = out_dir.join(&lib_name);
                    println!("Copying lib: {}", if args.link_static {&lib.static_lib} else {&lib.shared_lib});
                    if args.link_static {
                        fs::hard_link(&lib.static_lib, &out_lib)?;
                    } else {
                        fs::copy(&lib.shared_lib, &out_lib)?;
                        change_rpath(out_lib, &lib.shared_lib)?;
                    }
                    writeln!(
                        f,
                        "    {}${{CMAKE_CURRENT_LIST_DIR}}/{}",
                        if lib.link_whole { "-Wl,-force_load," }
                        else { " "},
                        &lib_name
                    )?;
                }
            }
            writeln!(f, ")\n")?;
        }
        if !is_interface && !info.copts.is_empty() {
            writeln!(f, "target_compile_options({} {}", &cmake_name, "PRIVATE")?;
            for copt in info.copts.iter() {
                writeln!(f, "    {}", copt)?;
            }
            writeln!(f, ")\n")?;
        }
        if !info.defines.is_empty() {
            writeln!(f, "target_compile_definitions({} {}", &cmake_name, if is_interface { "INTERFACE" } else { "PUBLIC" })?;
            for def in info.defines.iter() {
                writeln!(f, "    {}", def)?;
            }
            writeln!(f, ")\n")?;
        }
        if !is_interface && !info.local_defines.is_empty() {
            writeln!(f, "target_compile_definitions({} PRIVATE", &cmake_name)?;
            for def in info.local_defines.iter() {
                writeln!(f, "    {}", def)?;
            }
            writeln!(f, ")\n")?;
        }

        if !info.include_dirs.is_empty() || !info.gen_hdrs.is_empty() {
            let dirs: Vec<String> = info.include_dirs.clone()
                .into_iter()
                .map(|x|  unwrap_include_path(&label, &x, bazel_info))
                .filter(result::Result::is_ok)
                .map(result::Result::unwrap)
                .map(|x| x.to_str().map(str::to_owned))
                .filter(Option::is_some)
                .map(Option::unwrap)
                .collect();

            if !dirs.is_empty() {
                writeln!(f, "target_include_directories({} {}", &cmake_name, if is_interface { "INTERFACE" } else { "PUBLIC" })?;
                for dir in dirs.iter() {
                    writeln!(f, "    {}",dir)?;
                }
                writeln!(f, ")\n")?;
            }
        }

        if (!is_interface || !info.gen_hdrs.is_empty())
            && (!info.hdrs.is_empty()
            || !info.srcs.is_empty()
            || !info.gen_hdrs.is_empty()
            || !info.gen_srcs.is_empty()
        ) {
            writeln!(f, "target_sources({} {}", &cmake_name, if is_interface { "INTERFACE" } else { "PUBLIC" })?;

            copy_gens(cmake_dir, &info, is_external)?;
            for hdr in info.gen_hdrs.keys() {
                writeln!(f, "    {}/{}", cmake_dir, hdr)?;
            }

            if !is_interface {
                for hdr in info.hdrs.iter() {
                    writeln!(f, "    ${{WORKSPACE_DIR}}/{}", hdr)?;
                }
                for src in info.srcs.iter() {
                    writeln!(f, "    ${{WORKSPACE_DIR}}/{}", src)?;
                }
                for src in info.gen_srcs.keys().filter(|x| !info.gen_hdrs.contains_key(*x)) {
                    writeln!(f, "    {}/{}", cmake_dir, src)?;
                }
            }

            writeln!(f, ")\n")?;
        }
    }
    Ok(res)
}

fn write_deps(includes: Vec<String>, to: PathBuf, gen_dir_name: &str) -> Result<()> {
    let cmake_file = fs::File::create(&to)?;
    let mut f = BufWriter::new(cmake_file);
    writeln!(f, "include_directories(${{CMAKE_CURRENT_LIST_DIR}})")?;
    for inc in includes.into_iter() {
        writeln!(f,"include(${{CMAKE_CURRENT_SOURCE_DIR}}/{}/{})", gen_dir_name, inc)?;
    }
    Ok(())
}

fn write_all(includes: Vec<String>, workspace_dir: &str, to: PathBuf, gen_dir_name: &str) -> Result<()> {
    let cmake_file = fs::File::create(&to)?;
    let mut f = BufWriter::new(cmake_file);
    writeln!(f, "set(WORKSPACE_DIR {})", workspace_dir)?;
    writeln!(f, "include_directories({} ${{CMAKE_CURRENT_LIST_DIR}})", workspace_dir)?;
    for inc in includes.into_iter() {
        writeln!(f,"include(${{CMAKE_CURRENT_SOURCE_DIR}}/{}/{})", gen_dir_name, inc)?;
    }
    Ok(())
}

struct Args {
    package: Option<String>,
    name: String,
    config: Option<String>,
    link_static: bool,
}

fn main() -> Result<()> {
    let workspace_dir = env::var("BUILD_WORKSPACE_DIRECTORY")?;
    env::set_current_dir(&workspace_dir)?;

    let mut args = pico_args::Arguments::from_env();
    let args = Args {
        package: args.opt_value_from_str("-p")?,
        name: args.value_from_str("-n")?,
        config: args.opt_value_from_str("-c")?,
        link_static: args.value_from_str("-l")?,
    };
    let bazel_info = get_bazel_info(&args)?;

    let package_dir = if args.package.is_none() {
        workspace_dir.clone()
    } else {
        format!("{}/{}", &workspace_dir, args.package.as_ref().unwrap())
    };

    let cmake_dir = format!("{}/{}", &package_dir, &args.name);

    if fs::metadata(&cmake_dir).is_ok() {
        fs::remove_dir_all(&cmake_dir)?;
    }
    fs::create_dir(&cmake_dir)?;

    let targets_deps = query_cc_targets_deps(&args)?;
    let deps_infos =  get_cmake_infos(&targets_deps, &args, &bazel_info, true)?;
    let deps_gen = gen_libs(&cmake_dir, deps_infos, &args, &bazel_info, true)?;
    let all_deps_gen_file = PathBuf::new()
        .join(&cmake_dir)
        .join("all_deps.cmake");
    write_deps(deps_gen, all_deps_gen_file, &args.name)?;

    let targets = query_cc_targets(&args)?;
    let infos = get_cmake_infos(&targets, &args, &bazel_info, false)?;
    let gen =  gen_libs(&cmake_dir, infos,  &args, &bazel_info, false)?;
    let all_gen_file = PathBuf::new()
        .join(&cmake_dir)
        .join("all.cmake");
    write_all(
        gen,
        &workspace_dir,
        all_gen_file,
        &args.name
    )?;

    Ok(())
}
