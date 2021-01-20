_CmakeGenRunArgs = provider(
    fields = [
        "target_dir",
        "query_packages",
        "config",
        "additional_build_args",
        "link_static",
        "compile_external",
        "additional_always_links",
        "repo_path_mapping",
    ]
)

def _cmake_gen_impl(ctx):
    run_script = ctx.actions.declare_file(ctx.attr.name + ".sh")
    args_json_file = ctx.actions.declare_file(ctx.attr.name + ".args.json")

    ctx.actions.write(
        output = args_json_file,
        content = ctx.attr.input_args_json,
    )

    ctx.actions.expand_template(
        template = ctx.file._templ,
        output = run_script,
        substitutions = {
            "{TOOL}": ctx.executable._tool.short_path,
            "{ARGS_JSON}": args_json_file.path,
        },
        is_executable = True,
    )
    return DefaultInfo(
        executable = run_script, 
        runfiles = ctx.runfiles(files=[
            ctx.executable._tool,
            args_json_file,
        ])
    )

_cmake_gen = rule(
    attrs = {
        "input_args_json": attr.string(),
        "_templ": attr.label(
            default = Label("//rules:cmake_gen_run.templ"),
            allow_single_file = True,
        ),
        "_tool": attr.label(
            default = Label("//tools/cmake_gen"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
    },
    executable = True,
    implementation = _cmake_gen_impl,
)

def cmake_gen(
    name,
    query_packages = [],
    config = None,
    additional_build_args = [],
    link_static = True,
    compile_external = [],
    repo_path_mapping = {},
    additional_always_links = [],
):
    package_name = native.package_name()
    if package_name:
        target_dir = "%s/%s" % (
            native.package_name(),
            name,
        )
    else:
        target_dir = name

    if not query_packages:
        query_packages = [ package_name ]

    _cmake_gen(
        name = name,
        input_args_json = _CmakeGenRunArgs(
            target_dir = target_dir,
            query_packages = query_packages,
            config = config,
            additional_build_args = additional_build_args,
            link_static = link_static,
            compile_external = compile_external,
            repo_path_mapping = repo_path_mapping,
            additional_always_links = additional_always_links,
        ).to_json(),        
    )