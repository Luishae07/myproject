#!/usr/bin/env python3
"""Generates a real, valid Xcode project.pbxproj for the Luismail iOS app,
now with a second target: a WidgetKit extension (home-screen widget showing
unread count + latest message). Hand-generated using the standard
PBXFileReference/PBXBuildFile/PBXGroup object model every Xcode version
understands, same approach as the single-target version, extended with the
extra objects a second (embedded) target requires: PBXContainerItemProxy,
PBXTargetDependency, and a PBXCopyFilesBuildPhase to embed the .appex into
the app bundle.
"""
import uuid


def uid():
    return uuid.uuid4().hex[:24].upper()


APP_SWIFT_FILES = [
    "LuismailApp.swift",
    "Models.swift",
    "APIClient.swift",
    "SessionStore.swift",
    "RootView.swift",
    "LoginView.swift",
    "MainTabView.swift",
    "InboxView.swift",
    "MessageDetailView.swift",
    "ComposeView.swift",
    "SettingsView.swift",
    "InfoView.swift",
    "SpamView.swift",
    "NotificationManager.swift",
    "LuismailIntents.swift",
    "LoopingVideoView.swift",
]

WIDGET_SWIFT_FILES = [
    "LuismailWidget.swift",
]

ids = {}
def new_id(key):
    i = uid()
    ids[key] = i
    return i

# Core project objects
project_id = new_id("project")
main_group_id = new_id("main_group")
products_group_id = new_id("products_group")
app_group_id = new_id("app_group")
assets_group_id = new_id("assets_group")
preview_group_id = new_id("preview_group")
widget_group_id = new_id("widget_group")

target_id = new_id("target")
widget_target_id = new_id("widget_target")

build_config_list_project_id = new_id("build_config_list_project")
build_config_debug_project_id = new_id("build_config_debug_project")
build_config_release_project_id = new_id("build_config_release_project")
build_config_list_target_id = new_id("build_config_list_target")
build_config_debug_target_id = new_id("build_config_debug_target")
build_config_release_target_id = new_id("build_config_release_target")
build_config_list_widget_id = new_id("build_config_list_widget")
build_config_debug_widget_id = new_id("build_config_debug_widget")
build_config_release_widget_id = new_id("build_config_release_widget")

sources_phase_id = new_id("sources_phase")
frameworks_phase_id = new_id("frameworks_phase")
resources_phase_id = new_id("resources_phase")
embed_extensions_phase_id = new_id("embed_extensions_phase")

widget_sources_phase_id = new_id("widget_sources_phase")
widget_frameworks_phase_id = new_id("widget_frameworks_phase")
widget_resources_phase_id = new_id("widget_resources_phase")

container_item_proxy_id = new_id("container_item_proxy")
target_dependency_id = new_id("target_dependency")

assets_ref_id = new_id("assets_ref")
preview_assets_ref_id = new_id("preview_assets_ref")
entitlements_ref_id = new_id("entitlements_ref")
widget_entitlements_ref_id = new_id("widget_entitlements_ref")

file_refs = {}
build_files = {}
for name in APP_SWIFT_FILES:
    file_refs[name] = new_id(f"ref_{name}")
    build_files[name] = new_id(f"build_{name}")

widget_file_refs = {}
widget_build_files = {}
for name in WIDGET_SWIFT_FILES:
    widget_file_refs[name] = new_id(f"wref_{name}")
    widget_build_files[name] = new_id(f"wbuild_{name}")

app_ref_id = new_id("app_product_ref")
widget_ref_id = new_id("widget_product_ref")
widget_embed_build_id = new_id("widget_embed_build")

# ---- PBXBuildFile ----
build_file_lines = []
for name in APP_SWIFT_FILES:
    build_file_lines.append(
        f"\t\t{build_files[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[name]} /* {name} */; }};"
    )
assets_build_id = new_id("assets_build")
preview_assets_build_id = new_id("preview_assets_build")
build_file_lines.append(
    f"\t\t{assets_build_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref_id} /* Assets.xcassets */; }};"
)
build_file_lines.append(
    f"\t\t{preview_assets_build_id} /* Preview Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {preview_assets_ref_id} /* Preview Assets.xcassets */; }};"
)
for name in WIDGET_SWIFT_FILES:
    build_file_lines.append(
        f"\t\t{widget_build_files[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {widget_file_refs[name]} /* {name} */; }};"
    )
build_file_lines.append(
    f"\t\t{widget_embed_build_id} /* LuismailWidgetExtension.appex in Embed Foundation Extensions */ = "
    f"{{isa = PBXBuildFile; fileRef = {widget_ref_id} /* LuismailWidgetExtension.appex */; "
    f"settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};"
)

# ---- PBXFileReference ----
file_ref_lines = []
for name in APP_SWIFT_FILES:
    file_ref_lines.append(
        f'\t\t{file_refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};'
    )
file_ref_lines.append(
    f'\t\t{assets_ref_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};'
)
file_ref_lines.append(
    f'\t\t{preview_assets_ref_id} /* Preview Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Preview Assets.xcassets"; sourceTree = "<group>"; }};'
)
file_ref_lines.append(
    f'\t\t{entitlements_ref_id} /* Luismail.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Luismail.entitlements; sourceTree = "<group>"; }};'
)
file_ref_lines.append(
    f'\t\t{app_ref_id} /* Luismail.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Luismail.app; sourceTree = BUILT_PRODUCTS_DIR; }};'
)
for name in WIDGET_SWIFT_FILES:
    widget_file_refs_line_type = "sourcecode.swift"
    file_ref_lines.append(
        f'\t\t{widget_file_refs[name]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {widget_file_refs_line_type}; path = {name}; sourceTree = "<group>"; }};'
    )
widget_info_plist_ref_id = new_id("widget_info_plist_ref")
file_ref_lines.append(
    f'\t\t{widget_info_plist_ref_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};'
)
file_ref_lines.append(
    f'\t\t{widget_entitlements_ref_id} /* LuismailWidgetExtension.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = LuismailWidgetExtension.entitlements; sourceTree = "<group>"; }};'
)
file_ref_lines.append(
    f'\t\t{widget_ref_id} /* LuismailWidgetExtension.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = LuismailWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};'
)

# ---- Groups ----
app_group_children = ", ".join(f"{file_refs[n]} /* {n} */" for n in APP_SWIFT_FILES)
app_group_children += (
    f", {assets_group_id} /* Assets.xcassets */, {preview_group_id} /* Preview Content */, "
    f"{entitlements_ref_id} /* Luismail.entitlements */"
)

widget_group_children = ", ".join(f"{widget_file_refs[n]} /* {n} */" for n in WIDGET_SWIFT_FILES)
widget_group_children += f", {widget_info_plist_ref_id} /* Info.plist */, {widget_entitlements_ref_id} /* LuismailWidgetExtension.entitlements */"

pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_file_lines)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_ref_lines)}
/* End PBXFileReference section */

/* Begin PBXContainerItemProxy section */
\t\t{container_item_proxy_id} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = {project_id} /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {widget_target_id};
\t\t\tremoteInfo = LuismailWidgetExtension;
\t\t}};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
\t\t{embed_extensions_phase_id} /* Embed Foundation Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{widget_embed_build_id} /* LuismailWidgetExtension.appex in Embed Foundation Extensions */,
\t\t\t);
\t\t\tname = "Embed Foundation Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{widget_frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_group_id} /* Luismail */,
\t\t\t\t{widget_group_id} /* LuismailWidget */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_ref_id} /* Luismail.app */,
\t\t\t\t{widget_ref_id} /* LuismailWidgetExtension.appex */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{app_group_id} /* Luismail */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({app_group_children});
\t\t\tpath = Luismail;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{widget_group_id} /* LuismailWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = ({widget_group_children});
\t\t\tpath = LuismailWidget;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{assets_group_id} /* Assets.xcassets */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{assets_ref_id} /* Assets.xcassets */,
\t\t\t);
\t\t\tname = Assets.xcassets;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{preview_group_id} /* Preview Content */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{preview_assets_ref_id} /* Preview Assets.xcassets */,
\t\t\t);
\t\t\tpath = "Preview Content";
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* Luismail */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {build_config_list_target_id} /* Build configuration list for PBXNativeTarget "Luismail" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t\t{embed_extensions_phase_id} /* Embed Foundation Extensions */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{target_dependency_id} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = Luismail;
\t\t\tproductName = Luismail;
\t\t\tproductReference = {app_ref_id} /* Luismail.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{widget_target_id} /* LuismailWidgetExtension */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {build_config_list_widget_id} /* Build configuration list for PBXNativeTarget "LuismailWidgetExtension" */;
\t\t\tbuildPhases = (
\t\t\t\t{widget_sources_phase_id} /* Sources */,
\t\t\t\t{widget_frameworks_phase_id} /* Frameworks */,
\t\t\t\t{widget_resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = LuismailWidgetExtension;
\t\t\tproductName = LuismailWidgetExtension;
\t\t\tproductReference = {widget_ref_id} /* LuismailWidgetExtension.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1620;
\t\t\t\tLastUpgradeCheck = 1620;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.2;
\t\t\t\t\t}};
\t\t\t\t\t{widget_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.2;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {build_config_list_project_id} /* Build configuration list for PBXProject "Luismail" */;
\t\t\tcompatibilityVersion = "Xcode 15.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id} /* Luismail */,
\t\t\t\t{widget_target_id} /* LuismailWidgetExtension */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{preview_assets_build_id} /* Preview Assets.xcassets in Resources */,
\t\t\t\t{assets_build_id} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{widget_resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(f"\t\t\t\t{build_files[n]} /* {n} in Sources */," for n in APP_SWIFT_FILES)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{widget_sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(f"\t\t\t\t{widget_build_files[n]} /* {n} in Sources */," for n in WIDGET_SWIFT_FILES)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
\t\t{target_dependency_id} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {widget_target_id} /* LuismailWidgetExtension */;
\t\t\ttargetProxy = {container_item_proxy_id} /* PBXContainerItemProxy */;
\t\t}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
\t\t{build_config_debug_project_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{build_config_release_project_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{build_config_debug_target_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Luismail/Luismail.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "\\"Luismail/Preview Content\\"";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleDefault;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Luismail;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.luishae.luismail";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{build_config_release_target_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Luismail/Luismail.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_ASSET_PATHS = "\\"Luismail/Preview Content\\"";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleDefault;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Luismail;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.luishae.luismail";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{build_config_debug_widget_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_ENTITLEMENTS = LuismailWidget/LuismailWidgetExtension.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tINFOPLIST_FILE = LuismailWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.luishae.luismail.LuismailWidget";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{build_config_release_widget_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_ENTITLEMENTS = LuismailWidget/LuismailWidgetExtension.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tINFOPLIST_FILE = LuismailWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 26.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.luishae.luismail.LuismailWidget";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_config_list_project_id} /* Build configuration list for PBXProject "Luismail" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{build_config_debug_project_id} /* Debug */,
\t\t\t\t{build_config_release_project_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{build_config_list_target_id} /* Build configuration list for PBXNativeTarget "Luismail" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{build_config_debug_target_id} /* Debug */,
\t\t\t\t{build_config_release_target_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{build_config_list_widget_id} /* Build configuration list for PBXNativeTarget "LuismailWidgetExtension" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{build_config_debug_widget_id} /* Debug */,
\t\t\t\t{build_config_release_widget_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

with open("Luismail/Luismail.xcodeproj/project.pbxproj", "w") as f:
    f.write(pbxproj)

print("wrote project.pbxproj, root object:", project_id)
print("app target:", target_id)
print("widget target:", widget_target_id)
