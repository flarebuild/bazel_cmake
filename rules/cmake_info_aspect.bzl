load("cmake_info.bzl", "get_cmake_info", "cmake_info_to_json")

def _cmake_info_aspect_impl(target, ctx, linkstatic):
    out = ctx.actions.declare_file(target.label.name + "_info.json")
    info = get_cmake_info(target, ctx)
    ctx.actions.write(out, cmake_info_to_json(info, ctx))
    return [ 
        info,
        OutputGroupInfo(
            cmake_info_json = depset([out]),
            cmake_libs = depset([(l.static if linkstatic else l.shared) for l in info.libs]),
            cmake_gen_hdrs = depset(info.gen_hdrs),
            cmake_gen_srcs = depset(info.gen_srcs),
        ) 
    ]

def _cmake_info_aspect_impl_static(target, ctx):
    return _cmake_info_aspect_impl(target, ctx, True)

def _cmake_info_aspect_impl_shared(target, ctx):
    return _cmake_info_aspect_impl(target, ctx, False)

cmake_info_aspect_static =  aspect(
    implementation = _cmake_info_aspect_impl_static,
)
cmake_info_aspect_shared =  aspect(
    implementation = _cmake_info_aspect_impl_shared,
)