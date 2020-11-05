load("@bazel_skylib//lib:sets.bzl", "sets")

_LibInfo = provider(
    fields = [
        "shared",
        "static",
        "link_whole",
    ],
)

_CmakeInfo = provider(
    fields = [
        "label",
        "deps",
        "libs",
        "link_flags",
        "copts",
        "defines",
        "local_defines",
        "include_dirs",
        "hdrs",
        "gen_hdrs",
        "srcs",
        "gen_srcs",
        "is_executable",
        "include_prefix",
        "tags",
    ]
)

def _unique(arr):
    return sets.to_list(sets.make(arr))

def _get_deps(target, ctx):
    return [d.label for d in getattr(ctx.rule.attr, "deps", [])]

def _get_libs(target, ctx):
    result = []
    libraries_to_link = target[CcInfo].linking_context.libraries_to_link
    if libraries_to_link:
        for lib in libraries_to_link.to_list():
            is_own_lib = (
                (lib.static_library and lib.static_library.owner == target.label) or
                (lib.pic_static_library and lib.pic_static_library.owner == target.label) or
                (lib.dynamic_library and lib.dynamic_library.owner == target.label)
            )
            if is_own_lib:
                result.append(_LibInfo(
                    shared = lib.dynamic_library,
                    static = lib.pic_static_library if lib.pic_static_library else lib.static_library,
                    link_whole = lib.alwayslink,
                ))
    return result

def _get_link_flags(target, ctx):
    link_flags = []

    if CcInfo in target:
        link_flags += target[CcInfo].linking_context.user_link_flags

    link_flags_set = sets.make(link_flags)
    if sets.contains(link_flags_set, "-framework"):
        link_flags_new = []
        need_splash = False
        for link_flag in link_flags:
            if need_splash:
                link_flags_new.append("\"-framework %s\"" % link_flag)
                need_splash = False
            elif link_flag == "-framework":
                need_splash = True
            else:
                link_flags_new.append(link_flag)
        link_flags = sets.to_list(sets.make(link_flags_new))

    return _unique(link_flags)

def _get_copts(target, ctx):
    return getattr(ctx.rule.attr, "copts", [])

def _get_defines(target, ctx):
    return getattr(ctx.rule.attr, "defines", [])

def _get_local_defines(target, ctx):
    return getattr(ctx.rule.attr, "local_defines", [])

def _get_include_dirs(target, ctx):
    return getattr(ctx.rule.attr, "includes", [])

def _get_hdrs(target, ctx):
    result = []
    for hdr in getattr(ctx.rule.attr, "hdrs", []):
        for file in hdr[DefaultInfo].files.to_list():
            result.append(file)
    return _unique(result)

def _get_srcs(target, ctx):
    result = []
    for src in getattr(ctx.rule.attr, "srcs", []):
        for file in src[DefaultInfo].files.to_list():
            result.append(file)
    return _unique(result)

def _get_is_executable(target, ctx):
    if target[DefaultInfo].files_to_run.executable:
        return True
    return False

def _get_include_prefix(target, ctx):
    return getattr(ctx.rule.attr, "include_prefix", None)

def _get_tags(target, ctx):
    return getattr(ctx.rule.attr, "tags", [])

def get_cmake_info(target, ctx):
    hdrs = _get_hdrs(target, ctx)
    srcs = _get_srcs(target, ctx)
    return _CmakeInfo(
        label = target.label,
        deps = _get_deps(target, ctx),
        libs = _get_libs(target, ctx),
        link_flags = _get_link_flags(target, ctx),
        copts = _get_copts(target, ctx),
        defines = _get_defines(target, ctx),
        local_defines = _get_local_defines(target, ctx),
        include_dirs = _get_include_dirs(target, ctx),
        hdrs = [h for h in hdrs if h.is_source],
        gen_hdrs = [h for h in hdrs if not h.is_source],
        srcs = [s for s in srcs if s.is_source],
        gen_srcs = [s for s in srcs if not s.is_source],
        is_executable = _get_is_executable(target, ctx),
        include_prefix = _get_include_prefix(target, ctx),
        tags =  _get_tags(target, ctx),
    )

def strip_virt_include(path):
    if not "_virtual_imports" in path:
        return path
    
    return path [ path.find("/",  path.find("_virtual_imports") + 17) + 1: ]


def compose_gen_srcs(ctx, ci, srcs):
    gens = [ s for s in srcs if not s.is_source ]
    if not ci.label.workspace_name:
        return dict([ (strip_virt_include(s.short_path), s.path) for s in gens ])
    
    res = {}
    for s in gens:
        path = s.dirname
        path = path[ path.find("external"): ]
        if ci.include_prefix:
            path += "/" + ci.include_prefix
        path += "/" + s.basename
        res[strip_virt_include(path)] = s.path
    return res

def cmake_info_to_json(ci, ctx):
    args = {
        "label": str(ci.label),
        "deps": [ str(d) for d in ci.deps ],
        "libs": [
            struct(
                shared_lib = l.shared.path if l.shared else None,
                static_lib = l.static.path if l.static else None,
                link_whole = l.link_whole,
            ) for l in ci.libs
        ],
        "link_flags": ci.link_flags,
        "copts": ci.copts,
        "defines": ci.defines,
        "local_defines": ci.local_defines,
        "include_dirs": ci.include_dirs,
        "hdrs": [ h.path for h in ci.hdrs if h.is_source ],
        "gen_hdrs": compose_gen_srcs(ctx, ci, ci.gen_hdrs),
        "srcs": [ s.path for s in ci.srcs if s.is_source],
        "gen_srcs": compose_gen_srcs(ctx, ci, ci.gen_srcs),
        "is_executable": ci.is_executable,
        "tags": ci.tags,
    }
    if ci.include_prefix:
        args["include_prefix"] = ci.include_prefix

    return struct(**args).to_json()