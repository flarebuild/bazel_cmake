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

def cmake_gen(name, config = None):
    _cmake_gen(
        name = name,
        config = config,
        package = native.package_name(),
    )