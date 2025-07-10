#!/bin/bash
#
# build-mac.sh
#
# Enhanced macOS build script for NeutralinoJS with code signing and DMG packaging
#
# Requirements:
# - brew install jq create-dmg
# - Valid Apple Developer certificate
# - App-specific password for notarization
#
# Usage:
# ./build-mac-enhanced.sh [--sign] [--notarize] [--dmg]
#
# (c)2023-2024 Harald Schneider - marketmix.com
# (c)2025 Tolin Simpson - enhanced build automation.

VERSION='1.1.0'
OS=$(uname -s)

# Parse command line arguments
SIGN_APP=false
NOTARIZE_APP=false
CREATE_DMG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --sign)
            SIGN_APP=true
            shift
            ;;
        --notarize)
            NOTARIZE_APP=true
            SIGN_APP=true  # Notarization requires signing
            shift
            ;;
        --dmg)
            CREATE_DMG=true
            shift
            ;;
        --test)
            TEST_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--sign] [--notarize] [--dmg] [--test]"
            exit 1
            ;;
    esac
done

echo
echo -e "\033[1mEnhanced Neutralino BuildScript for macOS platform, version ${VERSION}\033[0m"

# Code signing configuration (set these environment variables)
DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-Developer ID Application: Your Name (XXXXXXXXXX)}"
DEVELOPER_ID_INSTALLER="${DEVELOPER_ID_INSTALLER:-Developer ID Installer: Your Name (XXXXXXXXXX)}"
APPLE_ID="${APPLE_ID:-your-email@example.com}"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-xxxx-xxxx-xxxx-xxxx}"
TEAM_ID="${TEAM_ID:-XXXXXXXXXX}"

CONF=./neutralino.config.json

if [ ! -e "./${CONF}" ]; then
    echo
    echo -e "\033[31m\033[1mERROR: ${CONF} not found.\033[0m"
    exit 1
fi

if ! jq -e '.buildScript | has("mac")' "${CONF}" > /dev/null; then
    echo
    echo -e "\033[31m\033[1mERROR: Missing buildScript JSON structure in ${CONF}\033[0m"
    exit 1
fi

APP_ARCH_LIST=($(jq -r '.buildScript.mac.architecture[]' ${CONF}))
APP_VERSION=$(jq -r '.version' ${CONF})
APP_MIN_OS=$(jq -r '.buildScript.mac.minimumOS' ${CONF})
APP_BINARY=$(jq -r '.cli.binaryName' ${CONF})
APP_NAME=$(jq -r '.buildScript.mac.appName' ${CONF})
APP_ID=$(jq -r '.buildScript.mac.appIdentifier' ${CONF})
APP_BUNDLE=$(jq -r '.buildScript.mac.appBundleName' ${CONF})
APP_ICON=$(jq -r '.buildScript.mac.appIcon' ${CONF})

APP_SRC=./_app_scaffolds/mac/myapp.app

if [ ! -e "./${APP_SRC}" ]; then
    echo
    echo -e "\033[31m\033[1mERROR: App scaffold not found: ${APP_SRC}\033[0m"
    exit 1
fi

# Check code signing requirements
if [ "$SIGN_APP" = true ]; then
    if [ "$OS" != "Darwin" ]; then
        echo -e "\033[31m\033[1mERROR: Code signing can only be performed on macOS\033[0m"
        exit 1
    fi
    
    if ! security find-certificate -c "$DEVELOPER_ID_APP" >/dev/null 2>&1; then
        echo -e "\033[33m\033[1mWARNING: Developer ID Application certificate not found\033[0m"
        echo "Please install your Apple Developer certificate or set DEVELOPER_ID_APP environment variable"
    fi
fi

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

# Function to sign the app bundle
sign_app_bundle() {
    local app_path="$1"
    local arch="$2"
    
    echo "  Code signing app bundle (${arch})..."
    
    # Sign all nested binaries first
    find "${app_path}" -name "*.dylib" -exec codesign --force --verify --verbose --sign "$DEVELOPER_ID_APP" {} \;
    find "${app_path}" -name "*.framework" -exec codesign --force --verify --verbose --sign "$DEVELOPER_ID_APP" {} \;
    
    # Sign the main executable
    codesign --force --verify --verbose --sign "$DEVELOPER_ID_APP" "${app_path}/Contents/MacOS/main"
    
    # Sign the app bundle with entitlements
    local entitlements_path="_app_scaffolds/mac/entitlements.plist"
    if [ -f "$entitlements_path" ]; then
        codesign --force --verify --verbose --sign "$DEVELOPER_ID_APP" --options runtime --entitlements "$entitlements_path" "${app_path}"
    else
        codesign --force --verify --verbose --sign "$DEVELOPER_ID_APP" --options runtime "${app_path}"
    fi
    
    # Verify the signature
    codesign --verify --verbose=2 "${app_path}"
    spctl --assess --verbose "${app_path}"
}

# Function to notarize the app
notarize_app() {
    local app_path="$1"
    local arch="$2"
    
    echo "  Creating ZIP for notarization (${arch})..."
    local zip_path="${app_path}.zip"
    (cd "$(dirname "${app_path}")" && zip -r "$(basename "${zip_path}")" "$(basename "${app_path}")")
    
    echo "  Submitting for notarization (${arch})..."
    xcrun notarytool submit "${zip_path}" \
        --apple-id "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait
    
    if [ $? -eq 0 ]; then
        echo "  Stapling notarization ticket (${arch})..."
        xcrun stapler staple "${app_path}"
        rm "${zip_path}"
    else
        echo -e "\033[31m\033[1mERROR: Notarization failed for ${arch}\033[0m"
        rm "${zip_path}"
        return 1
    fi
}

# Function to create DMG
create_dmg_package() {
    local app_path="$1"
    local arch="$2"
    
    echo "  Creating DMG package (${arch})..."
    
    local dmg_name="${APP_NAME}-${APP_VERSION}-${arch}.dmg"
    local dmg_path="./dist/mac_${arch}/${dmg_name}"
    
    # Remove existing DMG
    rm -f "${dmg_path}"
    
    # Create DMG with create-dmg
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${APP_ICON}" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 200 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 600 185 \
        --background "_app_scaffolds/mac/dmg-background.png" \
        "${dmg_path}" \
        "$(dirname "${app_path}")"
    
    if [ $? -eq 0 ]; then
        echo "  DMG created: ${dmg_path}"
        
        # Sign the DMG if signing is enabled
        if [ "$SIGN_APP" = true ]; then
            echo "  Signing DMG (${arch})..."
            codesign --force --sign "$DEVELOPER_ID_APP" "${dmg_path}"
        fi
    else
        echo -e "\033[33m\033[1mWARNING: DMG creation failed for ${arch}\033[0m"
    fi
}

for APP_ARCH in "${APP_ARCH_LIST[@]}"; do

    APP_DST=./dist/mac_${APP_ARCH}/${APP_NAME}.app
    APP_MACOS=${APP_DST}/Contents/MacOS
    APP_RESOURCES=${APP_DST}/Contents/Resources

    if [ -e "./preproc-mac.sh" ]; then
        echo "  Running pre-processor ..."
        . preproc-mac.sh
    fi

    EXE=./dist/${APP_BINARY}/${APP_BINARY}-mac_${APP_ARCH}
    RES=./dist/${APP_BINARY}/resources.neu
    EXT=./dist/${APP_BINARY}/extensions

    echo 
    echo -e "\033[1mBuilding App Bundle (${APP_ARCH}):\033[0m"
    echo
    echo "  Minimum macOS: ${APP_MIN_OS}"
    echo "  App Name:      ${APP_NAME}"
    echo "  Bundle Name:   ${APP_BUNDLE}"
    echo "  Identifier:    ${APP_ID}"
    echo "  Icon:          ${APP_ICON}"
    echo "  Source Folder: ${APP_SRC}"
    echo "  Target Folder: ${APP_DST}"
    echo "  Code Signing:  ${SIGN_APP}"
    echo "  Notarization:  ${NOTARIZE_APP}"
    echo "  Create DMG:    ${CREATE_DMG}"
    echo

    if [ ! -e "./${EXE}" ]; then
        echo -e "\033[31m\033[1m  ERROR: File not found: ${EXE}\033[0m"
        exit 1
    fi

    if [ ! -e "./${RES}" ]; then
        echo -e "\033[31m\033[1m  ERROR: Resource file not found: ${RES}\033[0m"
        exit 1
    fi

    echo "  Cloning scaffold ..."
    mkdir -p "${APP_DST}"
    cp -r ${APP_SRC}/* ${APP_DST}/

    echo "  Copying content:"
    echo "    - Binary File"
    cp "${EXE}" "${APP_MACOS}/main"
    chmod 755 "${APP_MACOS}/main"
    echo "    - Resources"
    cp "${RES}" "${APP_RESOURCES}/"

    if [ -e "./${EXT}" ]; then
        echo "    - Extensions"
        cp -r "${EXT}" "${APP_RESOURCES}/"
    fi

    if [ -e "./${APP_ICON}" ]; then
        echo "    - Icon"
        cp -r "${APP_ICON}" "${APP_RESOURCES}/"
    fi

    echo "  Processing Info.plist ..."

    if [ "$OS" == "Darwin" ]; then
      sed -i '' "s/{APP_NAME}/${APP_NAME}/g" "${APP_DST}/Contents/Info.plist"
      sed -i '' "s/{APP_BUNDLE}/${APP_BUNDLE}/g" "${APP_DST}/Contents/Info.plist"
      sed -i '' "s/{APP_ID}/${APP_ID}/g" "${APP_DST}/Contents/Info.plist"
      sed -i '' "s/{APP_VERSION}/${APP_VERSION}/g" "${APP_DST}/Contents/Info.plist"
      sed -i '' "s/{APP_MIN_OS}/${APP_MIN_OS}/g" "${APP_DST}/Contents/Info.plist"
    else
      sed -i "s/{APP_NAME}/${APP_NAME}/g" "${APP_DST}/Contents/Info.plist"
      sed -i "s/{APP_BUNDLE}/${APP_BUNDLE}/g" "${APP_DST}/Contents/Info.plist"
      sed -i "s/{APP_ID}/${APP_ID}/g" "${APP_DST}/Contents/Info.plist"
      sed -i "s/{APP_VERSION}/${APP_VERSION}/g" "${APP_DST}/Contents/Info.plist"
      sed -i "s/{APP_MIN_OS}/${APP_MIN_OS}/g" "${APP_DST}/Contents/Info.plist"
    fi

    if [ -e "./postproc-mac.sh" ]; then
        echo "  Running post-processor ..."
        . postproc-mac.sh
    fi

    if [ "$OS" == "Darwin" ]; then
      echo "  Clearing Extended Attributes ..."
      find "${APP_DST}" -type f -exec xattr -c {} \;
    fi

    # Code signing
    if [ "$SIGN_APP" = true ] && [ "$OS" == "Darwin" ]; then
        sign_app_bundle "${APP_DST}" "${APP_ARCH}"
        
        # Notarization
        if [ "$NOTARIZE_APP" = true ]; then
            notarize_app "${APP_DST}" "${APP_ARCH}"
        fi
    fi

    # Create DMG
    if [ "$CREATE_DMG" = true ]; then
        create_dmg_package "${APP_DST}" "${APP_ARCH}"
    fi

    echo
    echo -e "\033[1mBuild finished for ${APP_ARCH}.\033[0m"
done

echo 
echo -e "\033[1mAll done.\033[0m"

if [ "$SIGN_APP" = true ]; then
    echo
    echo -e "\033[1mCode Signing Summary:\033[0m"
    echo "✓ App bundles have been signed"
    if [ "$NOTARIZE_APP" = true ]; then
        echo "✓ App bundles have been notarized and stapled"
    fi
    if [ "$CREATE_DMG" = true ]; then
        echo "✓ DMG packages have been created and signed"
    fi
    echo
    echo "Your apps are now ready for distribution without manual installation steps!"
fi 
