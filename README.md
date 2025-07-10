# Neutralino App Template

This is a template for creating cross-platform desktop applications using [Neutralino.js](https://neutralino.js.org/) with comprehensive build automation and packaging tools.

## Template Placeholders

Before using this template, replace the following placeholders throughout the project files:

- `{{APP_DISPLAY_NAME}}` - The human-readable name of your app (e.g., "My Awesome App")
- `{{APP_BINARY_NAME}}` - The binary/executable name (e.g., "MyAwesomeApp", no spaces)
- `{{APP_NAME_LOWERCASE}}` - Lowercase app name for identifiers (e.g., "myawesomeapp")
- `{{APP_VERSION}}` - Your app version (e.g., "1.0.0")
- `{{APP_PUBLISHER}}` - Your name or company name
- `{{APP_YEAR}}` - Current year for copyright

### Files to Update

1. `neutralino.config.json` - Main configuration file
2. `resources/index.html` - Main HTML file
3. `resources/styles.css` - CSS styles
4. `resources/js/main.js` - Main JavaScript file
5. `build automation/template.iss` - Windows installer script
6. `_app_scaffolds/` - Platform-specific packaging files
7. `build automation/build-*.sh` - Build scripts
8. `build automation/setup-macos-signing.sh` - macOS signing script
9. `.github/workflows/build-linux.yml` - linux GitHub action script
10. `.github/workflows/build-macos.yml` - macos GitHub action script
11. `.github/workflows/build-windows.yml` - windows GitHub action script
12. `.github/workflows/release-all-platforms.yml` - all platforms GitHub action script

**Additional placeholders for build automation:**
- `{{APP_DESCRIPTION}}` - App description for package metadata
- `{{GITHUB_USERNAME}}` - Your GitHub username
- `{{GITHUB_REPO}}` - Your GitHub repository name

## Quick Start

1. **Replace Placeholders**: Use find and replace to update all placeholders with your app's information
2. **Add Your Icons**: Replace placeholder icons in `resources/icons/` with your app icons
3. **Install Neutralino CLI**: `npm install -g @neutralinojs/neu`
4. **Initialize**: Run `neu update` to download Neutralino binaries
5. **Develop**: Run `neu run` to start development
6. **Build**: Use the build automation scripts for distribution

## Project Structure

```
neutralino-template/
├── .github/workflows/        # GitHub Actions CI/CD workflows
├── build automation/          # Build scripts and automation
│   ├── template.iss          # Windows installer script
│   ├── build-*.sh           # Platform build scripts
│   ├── GITHUB_ACTIONS_SETUP.md # GitHub Actions setup guide
│   └── *.py                 # Utility scripts
├── _app_scaffolds/           # Platform-specific packaging
│   ├── linux/               # Linux .desktop and install scripts
│   ├── mac/                 # macOS app bundle and packaging
│   └── win/                 # Windows-specific files
├── resources/               # App resources
│   ├── icons/              # App icons (add your icons here)
│   ├── js/                 # JavaScript files
│   ├── index.html          # Main HTML file
│   └── styles.css          # Main CSS file
├── neutralino.config.json   # Neutralino configuration
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Development Commands

- `neu run` - Run the app in development mode
- `neu build` - Build the app for current platform
- `neu build --release` - Build optimized release version

## Build Automation

This template includes comprehensive build automation for all platforms using **GitHub Actions** CI/CD:

### Windows
- Uses `template.iss` for Inno Setup installer
- Builds x64 executable
- Creates installer executable

### macOS
- Creates .app bundle
- Code signing support (configure in build scripts)
- DMG creation

### Linux
- Creates .deb packages
- AppImage support
- Desktop file integration

## GitHub Actions CI/CD

This template includes pre-configured GitHub Actions workflows for automated building and releasing:

### Features
- **Automated Builds**: Triggers on push to main branch and pull requests
- **Multi-Platform**: Builds for Windows, macOS, and Linux simultaneously
- **Release Management**: Automatically creates releases with built binaries
- **Code Signing**: Support for signing binaries on all platforms
- **Artifact Storage**: Stores build artifacts for download

### Setup
1. Push your project to a GitHub repository
2. Configure secrets for code signing (optional)
3. Review and customize the workflow in `.github/workflows/`
4. See `build automation/GITHUB_ACTIONS_SETUP.md` for detailed setup instructions

### Workflow Triggers
- Push to `main` branch
- Pull requests
- Manual workflow dispatch
- Tag creation for releases

## Icon Requirements

Add your app icons to `resources/icons/` in the following formats:

- `appIcon.png` - Main app icon (512x512 recommended)
- `icon.ico` - Windows icon file
- `icon.icns` - macOS icon file
- `favicon.ico` - Browser/window icon

## Configuration

### Neutralino Config (`neutralino.config.json`)
- Set app metadata
- Configure window properties
- Define build targets
- Set permissions and API access

### Build Scripts & GitHub Actions
- Customize build automation in `build automation/`
- Configure GitHub Actions workflows for automated builds
- Set up code signing for all platforms
- Automated release creation and distribution
- Cross-platform builds in the cloud

## Getting Started with Development

1. **Install Dependencies**
   ```bash
   npm install -g @neutralinojs/neu
   ```

2. **Update Neutralino**
   ```bash
   neu update
   ```

3. **Start Development**
   ```bash
   neu run
   ```

4. **Build for Distribution**
   ```bash
   # Local builds - Run appropriate build script from build automation/
   ./build automation/build-linux.sh    # Linux
   ./build automation/build-mac.sh      # macOS
   # Use Inno Setup with template.iss for Windows
   
   # Or use GitHub Actions for automated cloud builds
   # See build automation/GITHUB_ACTIONS_SETUP.md for configuration
   ```

## Features Included

- ✅ Cross-platform desktop app framework
- ✅ Modern UI with responsive design
- ✅ Platform detection
- ✅ System notifications
- ✅ Window management
- ✅ GitHub Actions CI/CD automation
- ✅ Build automation for all platforms
- ✅ Installer/package creation
- ✅ Icon and branding support
- ✅ Development tools integration
- ✅ Automated release management

## Customization

### Adding New Features
1. Add HTML elements to `resources/index.html`
2. Style them in `resources/styles.css`
3. Add functionality in `resources/js/main.js`
4. Use Neutralino APIs for system integration

### Platform-Specific Features
- Use `Neutralino.os.getPlatform()` to detect platform
- Add conditional code for platform-specific functionality
- Customize build scripts for platform requirements

## License

This template is provided as-is. Add your own license for your application.

## Support

- [Neutralino.js Documentation](https://neutralino.js.org/docs/)
- [Neutralino.js GitHub](https://github.com/neutralinojs/neutralinojs)
- [Community Forum](https://github.com/neutralinojs/neutralinojs/discussions)

---

**Happy coding!** 🚀 
