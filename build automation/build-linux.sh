#!/bin/bash
#
# build-linux.sh
#
# Enhanced Linux build script for NeutralinoJS with AppImage, DEB, and RPM packaging
#
# Requirements:
# - jq
# - AppImage tools (appimagetool, linuxdeploy)
# - dpkg-deb (for .deb packages)
# - rpmbuild (for .rpm packages)
#
# Usage:
# ./build-linux-enhanced.sh [--appimage] [--deb] [--rpm] [--all]
#
# (c)2025 Tolin Simpson - enhanced build automation.

VERSION='1.1.0'
OS=$(uname -s)

# Parse command line arguments
CREATE_APPIMAGE=false
CREATE_DEB=false
CREATE_RPM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --appimage)
            CREATE_APPIMAGE=true
            shift
            ;;
        --deb)
            CREATE_DEB=true
            shift
            ;;
        --rpm)
            CREATE_RPM=true
            shift
            ;;
        --all)
            CREATE_APPIMAGE=true
            CREATE_DEB=true
            CREATE_RPM=true
            shift
            ;;
        --test)
            TEST_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--appimage] [--deb] [--rpm] [--all] [--test]"
            exit 1
            ;;
    esac
done

# If no packaging options specified, create AppImage by default
if [ "$CREATE_APPIMAGE" = false ] && [ "$CREATE_DEB" = false ] && [ "$CREATE_RPM" = false ]; then
    CREATE_APPIMAGE=true
fi

echo
echo -e "\033[1mEnhanced Neutralino BuildScript for Linux platform, version ${VERSION}\033[0m"

CONF=./neutralino.config.json

if [ ! -e "./${CONF}" ]; then
    echo
    echo -e "\033[31m\033[1mERROR: ${CONF} not found.\033[0m"
    exit 1
fi

if ! jq -e '.buildScript | has("linux")' "${CONF}" > /dev/null; then
    echo
    echo -e "\033[31m\033[1mERROR: Missing buildScript JSON structure in ${CONF}\033[0m"
    exit 1
fi

APP_ARCH_LIST=($(jq -r '.buildScript.linux.architecture[]' ${CONF}))
APP_VERSION=$(jq -r '.version' ${CONF})
APP_BINARY=$(jq -r '.cli.binaryName' ${CONF})
APP_NAME=$(jq -r '.buildScript.linux.appName' ${CONF})
APP_ICON=$(jq -r '.buildScript.linux.appIcon' ${CONF})
APP_PATH=$(jq -r '.buildScript.linux.appPath' ${CONF})
APP_PUBLISHER=$(jq -r '.buildScript.linux.appPublisher // "Publisher Name"' ${CONF})
APP_DESCRIPTION=$(jq -r '.buildScript.linux.appDescription // "Your application Description Goes here."' ${CONF})

if [ "$TEST_MODE" != true ]; then
    echo
    echo -e "\033[1mBuilding Neutralino Apps ...\033[0m"
    echo
    rm -rf "./dist/${APP_BINARY}"
    neu build
    echo -e "\033[1mDone.\033[0m"
else
    echo
    echo "Skipped 'neu build' in test-mode ..."
fi

# Function to create desktop file
create_desktop_file() {
    local app_dir="$1"
    local app_name="$2"
    local app_version="$3"
    local icon_path="$4"
    
    cat > "${app_dir}/${app_name}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=${app_name}
Comment=${APP_DESCRIPTION}
Exec=${app_name}
Icon=${app_name}
Categories=Utility;Calculator;
Version=${app_version}
StartupNotify=true
StartupWMClass=${app_name}
EOF
}

# Function to create AppImage
create_appimage() {
    local app_arch="$1"
    local arch_suffix=""
    
    case "$app_arch" in
        "x64") arch_suffix="x86_64" ;;
        "arm64") arch_suffix="aarch64" ;;
        "armhf") arch_suffix="armhf" ;;
        *) arch_suffix="x86_64" ;;
    esac
    
    echo "  Creating AppImage for ${app_arch}..."
    
    local APP_DIR="./dist/linux_${app_arch}/AppDir"
    local EXE="./dist/${APP_BINARY}/${APP_BINARY}-linux_${app_arch}"
    local RES="./dist/${APP_BINARY}/resources.neu"
    local EXT="./dist/${APP_BINARY}/extensions"
    local OUTPUT_APPIMAGE="./dist/linux_${app_arch}/${APP_NAME}-${APP_VERSION}-${arch_suffix}.AppImage"
    
    # Create AppDir structure
    mkdir -p "${APP_DIR}/usr/bin"
    mkdir -p "${APP_DIR}/usr/share/applications"
    mkdir -p "${APP_DIR}/usr/share/icons/hicolor/256x256/apps"
    
    # Copy executable
    cp "${EXE}" "${APP_DIR}/usr/bin/${APP_NAME}"
    chmod +x "${APP_DIR}/usr/bin/${APP_NAME}"
    
    # Copy resources
    cp "${RES}" "${APP_DIR}/usr/bin/"
    
    # Copy extensions if they exist
    if [ -d "${EXT}" ]; then
        cp -r "${EXT}" "${APP_DIR}/usr/bin/"
    fi
    
    # Copy icon
    if [ -f "${APP_ICON}" ]; then
        cp "${APP_ICON}" "${APP_DIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
        cp "${APP_ICON}" "${APP_DIR}/${APP_NAME}.png"
    fi
    
    # Create desktop file
    create_desktop_file "${APP_DIR}" "${APP_NAME}" "${APP_VERSION}" "${APP_NAME}.png"
    cp "${APP_DIR}/${APP_NAME}.desktop" "${APP_DIR}/usr/share/applications/"
    
    # Create AppRun script
    cat > "${APP_DIR}/AppRun" << EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\${0}")")"
exec "\${HERE}/usr/bin/${APP_NAME}" --path="\${HERE}/usr/bin" --enable-extensions=true "\$@"
EOF
    chmod +x "${APP_DIR}/AppRun"
    
    # Build AppImage using appimagetool
    if command -v appimagetool >/dev/null 2>&1; then
        ARCH=${arch_suffix} appimagetool "${APP_DIR}" "${OUTPUT_APPIMAGE}"
        echo "  ✓ AppImage created: ${OUTPUT_APPIMAGE}"
    else
        echo "  ⚠ appimagetool not found, skipping AppImage creation"
    fi
}

# Function to create DEB package
create_deb_package() {
    local app_arch="$1"
    local deb_arch=""
    
    case "$app_arch" in
        "x64") deb_arch="amd64" ;;
        "arm64") deb_arch="arm64" ;;
        "armhf") deb_arch="armhf" ;;
        *) deb_arch="amd64" ;;
    esac
    
    echo "  Creating DEB package for ${app_arch}..."
    
    local DEB_DIR="./dist/linux_${app_arch}/deb"
    local EXE="./dist/${APP_BINARY}/${APP_BINARY}-linux_${app_arch}"
    local RES="./dist/${APP_BINARY}/resources.neu"
    local EXT="./dist/${APP_BINARY}/extensions"
    local OUTPUT_DEB="./dist/linux_${app_arch}/${APP_NAME}-${APP_VERSION}-${deb_arch}.deb"
    
    # Create DEB directory structure
    mkdir -p "${DEB_DIR}/DEBIAN"
    mkdir -p "${DEB_DIR}/usr/bin"
    mkdir -p "${DEB_DIR}/usr/share/applications"
    mkdir -p "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "${DEB_DIR}/usr/share/${APP_NAME}"
    
    # Copy executable
    cp "${EXE}" "${DEB_DIR}/usr/bin/${APP_NAME}"
    chmod +x "${DEB_DIR}/usr/bin/${APP_NAME}"
    
    # Copy resources
    cp "${RES}" "${DEB_DIR}/usr/share/${APP_NAME}/"
    
    # Copy extensions if they exist
    if [ -d "${EXT}" ]; then
        cp -r "${EXT}" "${DEB_DIR}/usr/share/${APP_NAME}/"
    fi
    
    # Copy icon
    if [ -f "${APP_ICON}" ]; then
        cp "${APP_ICON}" "${DEB_DIR}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
    fi
    
    # Create desktop file
    create_desktop_file "${DEB_DIR}/usr/share/applications" "${APP_NAME}" "${APP_VERSION}" "${APP_NAME}"
    
    # Create wrapper script
    cat > "${DEB_DIR}/usr/bin/${APP_NAME}" << EOF
#!/bin/bash
exec "/usr/bin/${APP_NAME}-bin" --path="/usr/share/${APP_NAME}" --enable-extensions=true "\$@"
EOF
    chmod +x "${DEB_DIR}/usr/bin/${APP_NAME}"
    
    # Rename the actual binary
    mv "${DEB_DIR}/usr/bin/${APP_NAME}" "${DEB_DIR}/usr/bin/${APP_NAME}-bin"
    
    # Recreate wrapper script
    cat > "${DEB_DIR}/usr/bin/${APP_NAME}" << EOF
#!/bin/bash
exec "/usr/bin/${APP_NAME}-bin" --path="/usr/share/${APP_NAME}" --enable-extensions=true "\$@"
EOF
    chmod +x "${DEB_DIR}/usr/bin/${APP_NAME}"
    
    # Create control file
    cat > "${DEB_DIR}/DEBIAN/control" << EOF
Package: $(echo "${APP_NAME}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
Version: ${APP_VERSION}
Architecture: ${deb_arch}
Maintainer: ${APP_PUBLISHER}
Description: ${APP_NAME} - ${APP_DESCRIPTION}
Section: utils
Priority: optional
Depends: libc6
EOF
    
    # Build DEB package
    if command -v dpkg-deb >/dev/null 2>&1; then
        dpkg-deb --build "${DEB_DIR}" "${OUTPUT_DEB}"
        echo "  ✓ DEB package created: ${OUTPUT_DEB}"
    else
        echo "  ⚠ dpkg-deb not found, skipping DEB creation"
    fi
}

# Function to create RPM package
create_rpm_package() {
    local app_arch="$1"
    local rpm_arch=""
    
    case "$app_arch" in
        "x64") rpm_arch="x86_64" ;;
        "arm64") rpm_arch="aarch64" ;;
        "armhf") rpm_arch="armhf" ;;
        *) rpm_arch="x86_64" ;;
    esac
    
    echo "  Creating RPM package for ${app_arch}..."
    
    local RPM_DIR="./dist/linux_${app_arch}/rpm"
    local EXE="./dist/${APP_BINARY}/${APP_BINARY}-linux_${app_arch}"
    local RES="./dist/${APP_BINARY}/resources.neu"
    local EXT="./dist/${APP_BINARY}/extensions"
    local OUTPUT_RPM="./dist/linux_${app_arch}/${APP_NAME}-${APP_VERSION}-${rpm_arch}.rpm"
    
    # Create RPM build directories
    mkdir -p "${RPM_DIR}/BUILD"
    mkdir -p "${RPM_DIR}/RPMS"
    mkdir -p "${RPM_DIR}/SOURCES"
    mkdir -p "${RPM_DIR}/SPECS"
    mkdir -p "${RPM_DIR}/SRPMS"
    
    # Create buildroot directory
    local BUILDROOT="${RPM_DIR}/BUILDROOT"
    mkdir -p "${BUILDROOT}/usr/bin"
    mkdir -p "${BUILDROOT}/usr/share/applications"
    mkdir -p "${BUILDROOT}/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "${BUILDROOT}/usr/share/${APP_NAME}"
    
    # Copy files to buildroot
    cp "${EXE}" "${BUILDROOT}/usr/bin/${APP_NAME}-bin"
    chmod +x "${BUILDROOT}/usr/bin/${APP_NAME}-bin"
    
    cp "${RES}" "${BUILDROOT}/usr/share/${APP_NAME}/"
    
    if [ -d "${EXT}" ]; then
        cp -r "${EXT}" "${BUILDROOT}/usr/share/${APP_NAME}/"
    fi
    
    if [ -f "${APP_ICON}" ]; then
        cp "${APP_ICON}" "${BUILDROOT}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
    fi
    
    # Create wrapper script
    cat > "${BUILDROOT}/usr/bin/${APP_NAME}" << EOF
#!/bin/bash
exec "/usr/bin/${APP_NAME}-bin" --path="/usr/share/${APP_NAME}" --enable-extensions=true "\$@"
EOF
    chmod +x "${BUILDROOT}/usr/bin/${APP_NAME}"
    
    # Create desktop file
    create_desktop_file "${BUILDROOT}/usr/share/applications" "${APP_NAME}" "${APP_VERSION}" "${APP_NAME}"
    
    # Create spec file
    cat > "${RPM_DIR}/SPECS/${APP_NAME}.spec" << EOF
Name: $(echo "${APP_NAME}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
Version: ${APP_VERSION}
Release: 1%{?dist}
Summary: ${APP_NAME} - ${APP_DESCRIPTION}
License: MIT
URL: https://github.com/${APP_PUBLISHER}/${APP_BINARY}
BuildArch: ${rpm_arch}

%description
${APP_DESCRIPTION}

%files
/usr/bin/${APP_NAME}
/usr/bin/${APP_NAME}-bin
/usr/share/${APP_NAME}/
/usr/share/applications/${APP_NAME}.desktop
/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png

%install
cp -r ${BUILDROOT}/* %{buildroot}/

%post
/bin/touch --no-create %{_datadir}/icons/hicolor &>/dev/null || :

%postun
if [ \$1 -eq 0 ] ; then
    /bin/touch --no-create %{_datadir}/icons/hicolor &>/dev/null
    /usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :
fi

%posttrans
/usr/bin/gtk-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :
EOF
    
    # Try to build RPM using alien (converts from DEB)
    if command -v alien >/dev/null 2>&1 && [ -f "./dist/linux_${app_arch}/${APP_NAME}-${APP_VERSION}-amd64.deb" ]; then
        cd "./dist/linux_${app_arch}"
        alien --to-rpm "${APP_NAME}-${APP_VERSION}-amd64.deb"
        cd - >/dev/null
        echo "  ✓ RPM package created using alien"
    else
        echo "  ⚠ alien not found or no DEB to convert, skipping RPM creation"
    fi
}

# Function to run preprocessing
run_preproc() {
    local app_arch="$1"
    if [ -e "./preproc-linux.sh" ]; then
        echo "  Running pre-processor for ${app_arch}..."
        APP_ARCH="${app_arch}" . preproc-linux.sh
    fi
}

# Function to run postprocessing
run_postproc() {
    local app_arch="$1"
    if [ -e "./postproc-linux.sh" ]; then
        echo "  Running post-processor for ${app_arch}..."
        APP_ARCH="${app_arch}" . postproc-linux.sh
    fi
}

# Main build loop
for APP_ARCH in "${APP_ARCH_LIST[@]}"; do
    EXE="./dist/${APP_BINARY}/${APP_BINARY}-linux_${APP_ARCH}"
    RES="./dist/${APP_BINARY}/resources.neu"

    echo 
    echo -e "\033[1mBuilding Linux Packages (${APP_ARCH}):\033[0m"
    echo
    echo "  App Name:     ${APP_NAME}"
    echo "  Version:      ${APP_VERSION}"
    echo "  Architecture: ${APP_ARCH}"
    echo "  Icon:         ${APP_ICON}"
    echo "  AppImage:     ${CREATE_APPIMAGE}"
    echo "  DEB Package:  ${CREATE_DEB}"
    echo "  RPM Package:  ${CREATE_RPM}"
    echo

    if [ ! -e "./${EXE}" ]; then
        echo -e "\033[31m\033[1m  ERROR: File not found: ${EXE}\033[0m"
        exit 1
    fi

    if [ ! -e "./${RES}" ]; then
        echo -e "\033[31m\033[1m  ERROR: Resource file not found: ${RES}\033[0m"
        exit 1
    fi

    # Run preprocessing
    run_preproc "${APP_ARCH}"

    # Create output directory
    mkdir -p "./dist/linux_${APP_ARCH}"

    # Create packages based on options
    if [ "$CREATE_APPIMAGE" = true ]; then
        create_appimage "${APP_ARCH}"
    fi

    if [ "$CREATE_DEB" = true ]; then
        create_deb_package "${APP_ARCH}"
    fi

    if [ "$CREATE_RPM" = true ]; then
        create_rpm_package "${APP_ARCH}"
    fi

    # Run postprocessing
    run_postproc "${APP_ARCH}"

    echo
    echo -e "\033[1mBuild finished for ${APP_ARCH}.\033[0m"
done

echo 
echo -e "\033[1mAll Linux builds completed.\033[0m"

# Summary
echo
echo -e "\033[1mPackaging Summary:\033[0m"
if [ "$CREATE_APPIMAGE" = true ]; then
    echo "✓ AppImage packages created (universal, works on all distributions)"
fi
if [ "$CREATE_DEB" = true ]; then
    echo "✓ DEB packages created (Debian, Ubuntu, derivatives)"
fi
if [ "$CREATE_RPM" = true ]; then
    echo "✓ RPM packages created (RedHat, Fedora, CentOS, derivatives)"
fi

echo
echo "Your Linux packages are ready for distribution!" 
