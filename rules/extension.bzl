load("@build_bazel_rules_apple//apple:ios.bzl", rules_apple_ios_extension = "ios_extension")
load("//rules:plists.bzl", "info_plists_by_setting")
load("//rules:force_load_direct_deps.bzl", "force_load_direct_deps")
load("//rules/internal:framework_middleman.bzl", "dep_middleman", "framework_middleman")

def ios_extension(name, infoplists_by_build_setting = {}, **kwargs):
    """
    Builds and packages an iOS extension.

    The docs for ios_extension are at rules_apple
    https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-ios.md#ios_extension

    Perhaps we can just remove this wrapper longer term.

    Args:
        name: The name of the iOS extension.
        infoplists_by_build_setting: A dictionary of infoplists grouped by bazel build setting.

                                     Each value is applied if the respective bazel build setting
                                     is resolved during the analysis phase.

                                     If '//conditions:default' is not set the value in 'infoplists'
                                     is set as default.
        **kwargs: Arguments passed to the ios_extension rule as appropriate.
    """

    deps = kwargs.pop("deps", [])
    frameworks = kwargs.pop("frameworks", [])
    testonly = kwargs.pop("testonly", False)

    kwargs["families"] = kwargs.pop("families", ["iphone", "ipad"])

    # Setup force loading here - need to process deps and libs
    force_load_name = name + ".force_load_direct_deps"
    force_load_direct_deps(
        name = force_load_name,
        deps = deps,
        tags = ["manual"],
        testonly = testonly,
    )

    # Setup framework middlemen - need to process deps and libs
    fw_name = name + ".framework_middleman"
    framework_middleman(
        name = fw_name,
        extension_safe = True,
        framework_deps = deps,
        tags = ["manual"],
        testonly = testonly,
    )
    frameworks = [fw_name] + frameworks

    dep_name = name + ".dep_middleman"
    dep_middleman(
        name = dep_name,
        deps = deps,
        tags = ["manual"],
        testonly = testonly,
    )
    deps = [dep_name] + [force_load_name]

    rules_apple_ios_extension(
        name = name,
        deps = deps,
        frameworks = frameworks,
        output_discriminator = None,
        infoplists = info_plists_by_setting(
            name = name,
            infoplists_by_build_setting = infoplists_by_build_setting,
            default_infoplists = kwargs.pop("infoplists", []),
        ),
        testonly = testonly,
        **kwargs
    )
