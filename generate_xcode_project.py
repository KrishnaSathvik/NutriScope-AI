#!/usr/bin/env python3
import os
import uuid

ROOT = "/Users/krishnasathvikmantripragada/proteinplate-ai"
SRC = "NutriscopeAI"

swift_files = []
for dirpath, _, filenames in os.walk(os.path.join(ROOT, SRC)):
    for name in sorted(filenames):
        if name.endswith(".swift"):
            rel = os.path.relpath(os.path.join(dirpath, name), ROOT)
            swift_files.append(rel)

resource_files = [
    "NutriscopeAI/Resources/Assets.xcassets",
]
fonts_dir = os.path.join(ROOT, SRC, "Resources", "Fonts")
if os.path.isdir(fonts_dir):
    for name in sorted(os.listdir(fonts_dir)):
        if name.endswith(".ttf"):
            resource_files.append(f"NutriscopeAI/Resources/Fonts/{name}")
info_plist_file = "NutriscopeAI/Resources/Info.plist"
all_files = sorted(set(swift_files + resource_files + [info_plist_file]))


def uid():
    return uuid.uuid4().hex[:24].upper()


file_ids = {path: uid() for path in all_files}
build_file_ids = {path: uid() for path in all_files}

proj_id = uid()
target_id = uid()
sources_phase = uid()
resources_phase = uid()
frameworks_phase = uid()
healthkit_framework = uid()
healthkit_build = uid()
auth_services_framework = uid()
auth_services_build = uid()
product_ref = uid()
proj_config_list = uid()
target_config_list = uid()
debug_proj = uid()
release_proj = uid()
debug_tgt = uid()
release_tgt = uid()
main_group = uid()
products_group = uid()
app_group = uid()

# Build nested groups
group_ids = {}
for path in all_files:
    parts = path.split("/")
    for i in range(1, len(parts)):
        key = "/".join(parts[:i])
        group_ids.setdefault(key, uid())
group_ids[SRC] = app_group

children_main = [group_ids[SRC], products_group]
children_app = sorted(set(group_ids[k] for k in group_ids if k.count("/") == 1 and k.startswith(SRC + "/")), key=lambda x: x)

# simpler: manually structure groups in pbxproj using path groups

def file_ref(path):
    base = os.path.basename(path)
    if path.endswith(".plist"):
        ftype = "text.plist.xml"
    elif path.endswith(".xcassets"):
        ftype = "folder.assetcatalog"
    elif path.endswith(".entitlements"):
        ftype = "text.plist.entitlements"
    elif path.endswith(".ttf"):
        ftype = "file"
    else:
        ftype = "sourcecode.swift"
    return f"\t\t{file_ids[path]} /* {base} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {base}; sourceTree = \"<group>\"; }};"


def build_file(path, phase):
    base = os.path.basename(path)
    return f"\t\t{build_file_ids[path]} /* {base} in {phase} */ = {{isa = PBXBuildFile; fileRef = {file_ids[path]} /* {base} */; }};"


swift_builds = [build_file(p, "Sources") for p in swift_files]
resource_builds = [build_file(p, "Resources") for p in resource_files]

# group entries by directory
from collections import defaultdict

by_dir = defaultdict(list)
for path in all_files:
    by_dir[os.path.dirname(path)].append(path)

group_sections = []
for directory in sorted(by_dir.keys()):
    if directory == SRC:
        continue
    gid = group_ids.get(directory, uid())
    group_ids[directory] = gid
    rel_name = os.path.basename(directory)
    children = []
    for path in sorted(by_dir[directory]):
        children.append(f"{file_ids[path]} /* {os.path.basename(path)} */")
    for subdir in sorted(k for k in by_dir if k.startswith(directory + "/") and k.count("/") == directory.count("/") + 1):
        children.append(group_ids[subdir])
    group_sections.append(
        f"\t\t{gid} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t" + ",\n\t\t\t\t".join(children) + "\n\t\t\t);\n\t\t\tpath = " + rel_name + ";\n\t\t\tsourceTree = \"<group>\";\n\t\t};"
    )

# top-level app group children = Resources, App, Models, etc.
top_children = []
for sub in sorted(d for d in by_dir if d.startswith(SRC + "/") and d.count("/") == 1):
    top_children.append(group_ids[sub])
for path in by_dir.get(SRC, []):
    top_children.append(f"{file_ids[path]} /* {os.path.basename(path)} */")

app_group_section = f"\t\t{app_group} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t" + ",\n\t\t\t\t".join(top_children) + "\n\t\t\t);\n\t\t\tpath = NutriscopeAI;\n\t\t\tsourceTree = \"<group>\";\n\t\t};"

products_group_section = f"\t\t{products_group} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{product_ref} /* NutriscopeAI.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};"

main_group_section = f"\t\t{main_group} = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{app_group} /* NutriscopeAI */,\n\t\t\t\t{products_group} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};"

product_ref_line = f"\t\t{product_ref} /* NutriscopeAI.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = NutriscopeAI.app; sourceTree = BUILT_PRODUCTS_DIR; }};"

pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(swift_builds + resource_builds)}
\t\t{healthkit_build} /* HealthKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {healthkit_framework} /* HealthKit.framework */; }};
\t\t{auth_services_build} /* AuthenticationServices.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {auth_services_framework} /* AuthenticationServices.framework */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{product_ref_line}
{chr(10).join(file_ref(p) for p in all_files)}
\t\t{healthkit_framework} /* HealthKit.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = HealthKit.framework; path = System/Library/Frameworks/HealthKit.framework; sourceTree = SDKROOT; }};
\t\t{auth_services_framework} /* AuthenticationServices.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = AuthenticationServices.framework; path = System/Library/Frameworks/AuthenticationServices.framework; sourceTree = SDKROOT; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{healthkit_build} /* HealthKit.framework in Frameworks */,
\t\t\t\t{auth_services_build} /* AuthenticationServices.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{app_group_section}
{chr(10).join(group_sections)}
{products_group_section}
{main_group_section}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget "NutriscopeAI" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase} /* Sources */,
\t\t\t\t{frameworks_phase} /* Frameworks */,
\t\t\t\t{resources_phase} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = NutriscopeAI;
\t\t\tproductName = NutriscopeAI;
\t\t\tproductReference = {product_ref} /* NutriscopeAI.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1630;
\t\t\t\tLastUpgradeCheck = 1630;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.3;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_config_list} /* Build configuration list for PBXProject "NutriscopeAI" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group};
\t\t\tproductRefGroup = {products_group} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id} /* NutriscopeAI */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(f'\t\t\t\t{build_file_ids[p]} /* {os.path.basename(p)} in Resources */,' for p in resource_files)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(f'\t\t\t\t{build_file_ids[p]} /* {os.path.basename(p)} in Sources */,' for p in swift_files)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_proj} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_proj} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_tgt} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = NutriscopeAI/Resources/NutriscopeAI.entitlements;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Nutriscope AI";
\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "Nutriscope AI uses the camera to scan meals for protein and calorie estimates.";
\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = "Nutriscope AI needs photo access to analyze your meals.";
\t\t\t\tINFOPLIST_KEY_NSMicrophoneUsageDescription = "Nutriscope AI uses the microphone so you can describe meals by voice.";
\t\t\t\tINFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "Nutriscope AI converts your spoken meal description into text for logging.";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nutriscopeai.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_tgt} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = NutriscopeAI/Resources/NutriscopeAI.entitlements;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Nutriscope AI";
\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "Nutriscope AI uses the camera to scan meals for protein and calorie estimates.";
\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = "Nutriscope AI needs photo access to analyze your meals.";
\t\t\t\tINFOPLIST_KEY_NSMicrophoneUsageDescription = "Nutriscope AI uses the microphone so you can describe meals by voice.";
\t\t\t\tINFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "Nutriscope AI converts your spoken meal description into text for logging.";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nutriscopeai.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{proj_config_list} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_proj} /* Debug */,
\t\t\t\t{release_proj} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{target_config_list} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_tgt} /* Debug */,
\t\t\t\t{release_tgt} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {proj_id} /* Project object */;
}}
"""

out = os.path.join(ROOT, "NutriscopeAI.xcodeproj", "project.pbxproj")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    f.write(pbx)

scheme_dir = os.path.join(ROOT, "NutriscopeAI.xcodeproj", "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
with open(os.path.join(scheme_dir, "NutriscopeAI.xcscheme"), "w") as f:
    f.write(f"""<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Scheme
   LastUpgradeVersion = \"1630\"
   version = \"1.7\">
   <BuildAction
      parallelizeBuildables = \"YES\"
      buildImplicitDependencies = \"YES\">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = \"YES\"
            buildForRunning = \"YES\"
            buildForProfiling = \"YES\"
            buildForArchiving = \"YES\"
            buildForAnalyzing = \"YES\">
            <BuildableReference
               BuildableIdentifier = \"primary\"
               BlueprintIdentifier = \"{target_id}\"
               BuildableName = \"NutriscopeAI.app\"
               BlueprintName = \"NutriscopeAI\"
               ReferencedContainer = \"container:NutriscopeAI.xcodeproj\">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = \"Debug\"
      selectedDebuggerIdentifier = \"Xcode.DebuggerFoundation.Debugger.LLDB\"
      selectedLauncherIdentifier = \"Xcode.DebuggerFoundation.Launcher.LLDB\"
      launchStyle = \"0\"
      useCustomWorkingDirectory = \"NO\"
      ignoresPersistentStateOnLaunch = \"NO\"
      debugDocumentVersioning = \"YES\"
      debugServiceExtension = \"internal\"
      allowLocationSimulation = \"YES\">
      <BuildableProductRunnable
         runnableDebuggingMode = \"0\">
         <BuildableReference
            BuildableIdentifier = \"primary\"
            BlueprintIdentifier = \"{target_id}\"
            BuildableName = \"NutriscopeAI.app\"
            BlueprintName = \"NutriscopeAI\"
            ReferencedContainer = \"container:NutriscopeAI.xcodeproj\">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
""")

print(f"Wrote {out}")
print(f"Swift files: {len(swift_files)}")
