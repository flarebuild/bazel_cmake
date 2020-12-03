def _cmake_gen_impl(ctx):
    run_script = ctx.actions.declare_file(ctx.attr.name + ".sh")
    substitutions = {
        "{TOOL}": ctx.executable._tool.short_path,
        "{NAME}": ctx.attr.name,
        "{LINKSTATIC}": "true" if ctx.attr.linkstatic else "false",
    }

    if not len(ctx.attr.package):
        substitutions.update({"{PACKAGE}": ""})
    else:
        substitutions.update({"{PACKAGE}": "-p //" + ctx.attr.package})

    if not ctx.attr.config:
        substitutions.update({"{CONFIG}": ""})
    else:
        substitutions.update({"{CONFIG}": "-c " + ctx.attr.config})

    if not ctx.attr.additional_build_args:
        substitutions.update({"{ADDITIONAL_BUILD_ARGS}": ""})
    else:
        substitutions.update({"{ADDITIONAL_BUILD_ARGS}": "-b " + ",".join(ctx.attr.additional_build_args)})

    if not ctx.attr.compile_external:
        substitutions.update({"{COMPILE_EXTERNAL}": ""})
    else:
        substitutions.update({"{COMPILE_EXTERNAL}": "-e " + ",".join(ctx.attr.compile_external)})

    if not ctx.attr.additional_allwayslinks:
        substitutions.update({"{ADDITIONAL_ALLWAYS_LINKS}": ""})
    else:
        substitutions.update({"{ADDITIONAL_ALLWAYS_LINKS}": "-a " + ",".join(ctx.attr.additional_allwayslinks)})

    if not ctx.attr.repo_path_mapping:
        substitutions.update({"{REPO_PATH_MAPPING}": ""})
    else:
        substitutions.update({"{REPO_PATH_MAPPING}": "-m " + ",".join(
            [ "%s:%s" % (k,v) for k,v in ctx.attr.repo_path_mapping.items() ]
        )})

    ctx.actions.expand_template(
        template = ctx.file._templ,
        output = run_script,
        substitutions = substitutions,
        is_executable = True,
    )
    return DefaultInfo(
        executable = run_script, 
        runfiles = ctx.runfiles(files=[ctx.executable._tool])
    )

_cmake_gen = rule(
    attrs = {
        "package": attr.string(
            mandatory = True,
        ),
        "linkstatic": attr.bool(
            default = True,
        ),
        "config": attr.string(
            mandatory = False,
        ),
        "additional_build_args": attr.string_list(
            default = [],
        ),
        "compile_external": attr.string_list(
            default = [],
        ),
        "additional_allwayslinks": attr.string_list(
            default = [],
        ),
        "repo_path_mapping": attr.string_dict(
            default = {},
        ),
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
    config = None,
    additional_build_args = [],
    compile_external = [],
    repo_path_mapping = {},
    additional_allwayslinks = [],
):
    _cmake_gen(
        name = name,
        config = config,
        additional_build_args = additional_build_args,
        compile_external = compile_external,
        repo_path_mapping = repo_path_mapping,
        additional_allwayslinks = additional_allwayslinks,
        package = native.package_name(),
    )