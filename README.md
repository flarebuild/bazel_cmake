Tooling to generate corresponding cmake targets from bazel’s cc_library & cc_binary ones. 
Clion bazel plugin has very limited functionality on mac os x (e.g. no debugging), and not officially supported by google. 
Cmake generation can help here to provide full ide support while keeping bazel the main source of proof. 
This cmake generation appreach support external repositories, with optional cmake generation for them, or if not, just import prebuilt by bazel binaries. T
he goal is to keep integration as simple and not verbose as possible, like in example:
https://github.com/flarebuild/bazel_cmake/blob/master/example/BUILD.bazel
https://github.com/flarebuild/bazel_cmake/blob/master/example/CMakeLists.txt
Project with this CmakeList can be simply imported from Clion, and internal rust and bazel’s aspects tooling will do all other stuff.
