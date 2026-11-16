import uuid
import os

def gen_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    proj_dir = os.path.join(base_dir, "LuminaStudio.xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)
    
    files = [
        ("LuminaStudioApp.swift", "LuminaStudio/App/LuminaStudioApp.swift"),
        ("RootCoordinator.swift", "LuminaStudio/App/RootCoordinator.swift"),
        ("PhotoEditorViewModel.swift", "LuminaStudio/ViewModels/PhotoEditorViewModel.swift"),
        ("WorkspaceContainerView.swift", "LuminaStudio/Views/WorkspaceContainerView.swift"),
        ("PhotoWorkspaceView.swift", "LuminaStudio/Views/Photo/PhotoWorkspaceView.swift"),
        ("MetalCanvasRepresentable.swift", "LuminaStudio/Views/Photo/MetalCanvasRepresentable.swift"),
        ("LayerPanelView.swift", "LuminaStudio/Views/Photo/LayerPanelView.swift"),
        ("HistoryPanelView.swift", "LuminaStudio/Views/Photo/HistoryPanelView.swift"),
        ("NewCanvasSheetView.swift", "LuminaStudio/Views/Photo/NewCanvasSheetView.swift"),
        ("ExportSheetView.swift", "LuminaStudio/Views/Photo/ExportSheetView.swift"),
        ("ToolSidebarView.swift", "LuminaStudio/Views/Photo/ToolSidebarView.swift"),
        ("ToolOptionsBarView.swift", "LuminaStudio/Views/Photo/ToolOptionsBarView.swift"),
        ("SelectionOverlayView.swift", "LuminaStudio/Views/Photo/SelectionOverlayView.swift"),
        ("TransformOverlayView.swift", "LuminaStudio/Views/Photo/TransformOverlayView.swift"),
        ("CropOverlayView.swift", "LuminaStudio/Views/Photo/CropOverlayView.swift"),
        ("BrushSettingsSheetView.swift", "LuminaStudio/Views/Photo/BrushSettingsSheetView.swift"),
        ("VectorWorkspacePlaceholderView.swift", "LuminaStudio/Views/Vector/VectorWorkspacePlaceholderView.swift"),
        ("CollageWorkspacePlaceholderView.swift", "LuminaStudio/Views/Collage/CollageWorkspacePlaceholderView.swift"),
    ]
    
    file_entries = {}
    for name, rel_path in files:
        f_ref = gen_id()
        b_ref = gen_id()
        file_entries[name] = {"path": rel_path, "f_ref": f_ref, "b_ref": b_ref}
        
    info_f_ref = gen_id()
    app_f_ref = gen_id()
    
    sources_phase_id = gen_id()
    resources_phase_id = gen_id()
    frameworks_phase_id = gen_id()
    target_id = gen_id()
    project_id = gen_id()
    main_group_id = gen_id()
    sources_group_id = gen_id()
    products_group_id = gen_id()
    
    debug_cfg_target_id = gen_id()
    release_cfg_target_id = gen_id()
    cfg_list_target_id = gen_id()
    
    debug_cfg_proj_id = gen_id()
    release_cfg_proj_id = gen_id()
    cfg_list_proj_id = gen_id()
    
    group_str = '<group>'
    
    pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
"""
    for name, d in file_entries.items():
        pbx += f'\t\t{d["b_ref"]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {d["f_ref"]} /* {name} */; }};\n'

    pbx += """/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""
    for name, d in file_entries.items():
        pbx += f'\t\t{d["f_ref"]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{d["path"]}"; sourceTree = "{group_str}"; }};\n'

    pbx += f'\t\t{info_f_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "LuminaStudio/Resources/Info.plist"; sourceTree = "{group_str}"; }};\n'
    pbx += f'\t\t{app_f_ref} /* LuminaStudio.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = LuminaStudio.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
    pbx += """/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
"""
    pbx += f"""\t\t{frameworks_phase_id} /* Frameworks */ = {{
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
\t\t\t\t{sources_group_id} /* LuminaStudio */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "{group_str}";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_f_ref} /* LuminaStudio.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "{group_str}";
\t\t}};
\t\t{sources_group_id} /* LuminaStudio */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""
    for name, d in file_entries.items():
        pbx += f'\t\t\t\t{d["f_ref"]} /* {name} */,\n'
    pbx += f'\t\t\t\t{info_f_ref} /* Info.plist */,\n'
    pbx += f"""\t\t\t);
\t\t\tname = LuminaStudio;
\t\t\tsourceTree = "{group_str}";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* LuminaStudio */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {cfg_list_target_id} /* Build configuration list for PBXNativeTarget "LuminaStudio" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = LuminaStudio;
\t\t\tproductName = LuminaStudio;
\t\t\tproductReference = {app_f_ref} /* LuminaStudio.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{target_id} = {{
\t\t\t\t\t\tCreatedOnToolsConfirmation = 1;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {cfg_list_proj_id} /* Build configuration list for PBXProject "LuminaStudio" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
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
\t\t\t\t{target_id} /* LuminaStudio */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
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
"""
    for name, d in file_entries.items():
        pbx += f'\t\t\t\t{d["b_ref"]} /* {name} in Sources */,\n'

    pbx += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_cfg_proj_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_cfg_proj_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_cfg_target_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "LuminaStudio/Resources/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.lumina.studio";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_cfg_target_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "LuminaStudio/Resources/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "com.lumina.studio";
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{cfg_list_proj_id} /* Build configuration list for PBXProject "LuminaStudio" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_cfg_proj_id} /* Debug */,
\t\t\t\t{release_cfg_proj_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{cfg_list_target_id} /* Build configuration list for PBXNativeTarget "LuminaStudio" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_cfg_target_id} /* Debug */,
\t\t\t\t{release_cfg_target_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {project_id} /* Project object */;
}}
"""
    pbx_path = os.path.join(proj_dir, "project.pbxproj")
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write(pbx)
    print(f"Generated {pbx_path}")

if __name__ == "__main__":
    main()
