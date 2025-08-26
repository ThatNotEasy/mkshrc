#!/system/bin/sh

# =============================================================================
# Android Environment Installer Script
# =============================================================================
# @name         Android Environment Installer
# @namespace    https://github.com/user/mkshrc/
# @version      1.2
# @description  Comprehensive development and debugging environment setup for Android devices
# @author       user
# @match        Android
# 
# Purpose:      Installs a complete shell environment with development tools, debugging utilities,
#               and system binaries on Android devices via ADB or terminal.
# 
# Features:
# - mkshrc shell environment customization
# - Frida dynamic instrumentation toolkit
# - BusyBox multi-call binary with Unix utilities
# - Vim advanced text editor with configuration
# - htop interactive process viewer
# - Git version control system
# - curl and OpenSSL for network operations
# - Architecture-specific binary support (ARM, x86)
# =============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Color functions
_info() { echo -e "${BLUE}[I]${NC} $1"; }
_success() { echo -e "${GREEN}[✓]${NC} $1"; }
_warning() { echo -e "${YELLOW}[W]${NC} $1"; }
_error() { echo -e "${RED}[E]${NC} $1"; }
_step() { echo -e "${CYAN}[→]${NC} $1"; }
_highlight() { echo -e "${WHITE}${1}${NC}"; }

# Check if a command exists in PATH
# Usage: _exist command_name
# Returns: 0 if exists, 1 if not found
_exist() {
  command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# CONFIGURATION SETTINGS
# =============================================================================
TMPDIR='/data/local/tmp'                  # Temporary directory for installation
CPU_ABI="$(getprop ro.product.cpu.abi)"   # Detect device CPU architecture
FRIDA=${1:-'17.2.16'}                     # Default Frida version if not provided

rc_package="$TMPDIR/package"              # Source package folder
rc_bin="$TMPDIR/bin"                      # Destination folder for binaries

echo ""
_info "Temporary directory: $TMPDIR"
_info "Detected CPU ABI: $CPU_ABI"
_info "Frida version: $FRIDA"

# =============================================================================
# ARCHITECTURE DETECTION AND VALIDATION
# =============================================================================
# Map Android ABI to package directory structure
# Supported architectures: arm64-v8a, armeabi-v7a, x86, x86_64
case "$CPU_ABI" in
  arm64-v8a)
    PACKAGE_ABI="arm64-v8a"
    ;;
  armeabi-v7a)
    PACKAGE_ABI="armeabi-v7a"
    ;;
  x86)
    PACKAGE_ABI="x86"
    ;;
  x86_64)
    PACKAGE_ABI="x86_64"
    ;;
  *)
    _error "Unsupported CPU ABI architecture: $CPU_ABI"
    _info "Supported architectures: arm64-v8a, armeabi-v7a, x86, x86_64"
    exit 1
    ;;
esac

_success "Using package architecture: $PACKAGE_ABI"

# Verify CPU ABI support and exit if not supported
[ ! -d "$rc_package/$PACKAGE_ABI" ] && {
  _error "Package directory not found for architecture: $PACKAGE_ABI"
  _error "Expected directory: $rc_package/$PACKAGE_ABI"
  _info "Available architectures:"
  ls -1 "$rc_package/" 2>/dev/null | grep -E '^(arm|x86)' | sed 's/^/       /'
  exit 1
}

# =============================================================================
# CLEANUP AND INITIALIZATION
# =============================================================================
_step "Cleaning previous installation..."
rm -rf "$rc_bin"
mkdir -p "$rc_bin"
_success "Clean installation directory prepared"

# =============================================================================
# SUPOLICY INSTALLATION (Magisk compatibility)
# =============================================================================
# Provides policy manipulation utilities for rooted devices
_exist supolicy || {
  _step "Installing supolicy binaries..."
  cp -f "$rc_package/$PACKAGE_ABI/supolicy/supolicy" "$rc_bin/supolicy" 2>/dev/null || _warning "supolicy not found for $PACKAGE_ABI"
  cp -f "$rc_package/$PACKAGE_ABI/supolicy/libsupol.so" "$rc_bin/libsupol.so" 2>/dev/null || _warning "libsupol.so not found for $PACKAGE_ABI"
  _success "Security policy tools installed"
}

# =============================================================================
# FRIDA SERVER INSTALLATION
# =============================================================================
# Dynamic instrumentation toolkit for developers and reverse engineers
_step "Installing Frida server version $FRIDA for $CPU_ABI..."
frida=$(find "$rc_package/$PACKAGE_ABI/frida" -type f -name "frida-server-$FRIDA*android-*" 2>/dev/null | head -n 1)

if [ -z "$frida" ]; then
  _warning "Frida version $FRIDA not available for $PACKAGE_ABI"
  _info "Available Frida versions:"
  find "$rc_package/$PACKAGE_ABI/frida" -type f -name "frida-server-*" 2>/dev/null | sed 's/.*frida-server-//' | sed 's/-android.*//' | sort -u | sed 's/^/       /'
else
  cp -f "$frida" "$rc_bin/frida-server"
  chmod +x "$rc_bin/frida-server"
  _success "Installed: $(basename "$frida")"
fi

# Install frida wrapper script
if [ -f "$rc_package/$PACKAGE_ABI/frida/frida" ]; then
  cp -f "$rc_package/$PACKAGE_ABI/frida/frida" "$rc_bin/frida"
  chmod +x "$rc_bin/frida"
  _success "Frida wrapper script installed"
else
  _warning "Frida wrapper script not found for $PACKAGE_ABI"
fi

# =============================================================================
# CORE UTILITIES INSTALLATION
# =============================================================================
_step "Installing additional binaries..."

# BusyBox - Multi-call binary combining many common Unix utilities
cp -f "$rc_package/$PACKAGE_ABI/busybox/libbusybox.so" "$rc_bin/busybox" 2>/dev/null || _warning "busybox not found for $PACKAGE_ABI"

# curl - Command line tool for transferring data with URL syntax
cp -f "$rc_package/$PACKAGE_ABI/curl/curl" "$rc_bin/curl" 2>/dev/null || _warning "curl not found for $PACKAGE_ABI"

# OpenSSL - Cryptography and SSL/TLS toolkit
cp -f "$rc_package/$PACKAGE_ABI/openssl/openssl" "$rc_bin/openssl" 2>/dev/null || _warning "openssl not found for $PACKAGE_ABI"

_success "Core utilities installed"

# =============================================================================
# GIT VERSION CONTROL SYSTEM
# =============================================================================
_step "Installing Git version control system..."

[ -f "$rc_package/$PACKAGE_ABI/git/git" ] && {
  cp -f "$rc_package/$PACKAGE_ABI/git/git" "$rc_bin/git"
  chmod +x "$rc_bin/git"

  # Install git shared libraries if available
  if [ -d "$rc_package/$PACKAGE_ABI/git/lib" ]; then
    mkdir -p "$rc_bin/../lib"
    cp -f "$rc_package/$PACKAGE_ABI/git/lib"/* "$rc_bin/../lib/" 2>/dev/null || true
    _success "Git installed with shared libraries"
  else
    _success "Git version control system installed"
  fi

  # Create git wrapper script for library dependencies
  if [ -d "$rc_bin/../lib" ] && [ "$(ls -A "$rc_bin/../lib" 2>/dev/null)" ]; then
    cat > "$rc_bin/git-wrapper" << 'EOF'
#!/system/bin/sh
# Git wrapper script to handle shared library dependencies

# Set library path for git dependencies
export LD_LIBRARY_PATH="/data/local/tmp/lib:$LD_LIBRARY_PATH"

# Execute git with proper library path
exec /data/local/tmp/bin/git "$@"
EOF
    chmod +x "$rc_bin/git-wrapper"
    _success "Git wrapper script created for library dependencies"
  fi

  # Install additional git utilities
  [ -f "$rc_package/$PACKAGE_ABI/git/git-upload-pack" ] && cp -f "$rc_package/$PACKAGE_ABI/git/git-upload-pack" "$rc_bin/git-upload-pack"
  [ -f "$rc_package/$PACKAGE_ABI/git/git-receive-pack" ] && cp -f "$rc_package/$PACKAGE_ABI/git/git-receive-pack" "$rc_bin/git-receive-pack"
  [ -f "$rc_package/$PACKAGE_ABI/git/git-shell" ] && cp -f "$rc_package/$PACKAGE_ABI/git/git-shell" "$rc_bin/git-shell"
}

# =============================================================================
# TEXT EDITORS AND SYSTEM TOOLS
# =============================================================================
_step "Installing text editors and system tools..."

# Vim - Advanced text editor with extensive customization
[ -f "$rc_package/$PACKAGE_ABI/vim/vim" ] && {
  cp -f "$rc_package/$PACKAGE_ABI/vim/vim" "$rc_bin/vim"
  chmod +x "$rc_bin/vim"
  
  # Vimtutor - Interactive tutorial for learning Vim
  [ -f "$rc_package/$PACKAGE_ABI/vim/vimtutor" ] && cp -f "$rc_package/$PACKAGE_ABI/vim/vimtutor" "$rc_bin/vimtutor"

  # Vim configuration files and runtime environment
  if [ -d "$rc_package/$PACKAGE_ABI/vim/vim_config/usr/share/vim" ]; then
    _step "Installing vim configuration files..."
    mkdir -p "$rc_bin/../share"
    cp -rf "$rc_package/$PACKAGE_ABI/vim/vim_config/usr/share/vim" "$rc_bin/../share/"

    # Set VIM environment variables
    echo "export VIM=\"$rc_bin/../share/vim\"" >> "$rc_bin/../.vimrc_env"
    echo "export VIMRUNTIME=\"\$VIM/vim91\"" >> "$rc_bin/../.vimrc_env"

    # Install basic vimrc configuration
    [ -f "$rc_package/$PACKAGE_ABI/vim/vimrc_basic" ] && cp -f "$rc_package/$PACKAGE_ABI/vim/vimrc_basic" "$rc_bin/../.vimrc"
  fi

  _success "Vim editor installed (with vimtutor and configuration)"
}

# htop - Interactive process viewer and system monitor
[ -f "$rc_package/$PACKAGE_ABI/htop/htop" ] && {
  cp -f "$rc_package/$PACKAGE_ABI/htop/htop" "$rc_bin/htop"
  chmod +x "$rc_bin/htop"

  # Install ncursesw terminfo files for proper terminal support
  if [ -d "$rc_package/$PACKAGE_ABI/htop/usr/share" ]; then
    _step "Installing terminfo files for htop..."
    mkdir -p "$rc_bin/../share"
    cp -rf "$rc_package/$PACKAGE_ABI/htop/usr/share"/* "$rc_bin/../share/"

    # Set TERMINFO environment variable
    echo "export TERMINFO=\"$rc_bin/../share/terminfo\"" >> "$rc_bin/../.htoprc_env"
    _success "Htop installed with terminfo support"
  else
    _success "Htop process viewer installed"
  fi
}

# =============================================================================
# SECURITY AND CERTIFICATE MANAGEMENT
# =============================================================================
# Certificate update script for managing trusted CA certificates
[ -f "$rc_package/update-ca-certificate.sh" ] && {
  cp "$rc_package/update-ca-certificate.sh" "$rc_bin/update-ca-certificate"
  chmod +x "$rc_bin/update-ca-certificate"
  _success "Certificate management script installed"
}

# =============================================================================
# PERMISSIONS AND FINAL SETUP
# =============================================================================
# Set ownership and permissions for security and accessibility
_step "Setting permissions..."
chown -R shell:shell "$rc_bin"
chmod -R 755 "$rc_bin"
_success "Permissions set correctly"

# BusyBox applet setup - Create symlinks for all available utilities
_step "Setting up BusyBox commands..."
if [ -f "$rc_bin/busybox" ]; then
  busybox="$rc_bin/busybox"
  chmod +x "$busybox"
  for applet in $("$busybox" --list | grep -vE '^man$'); do
    _exist "$applet" || ln -s "$busybox" "$rc_bin/$applet"
  done
  _success "BusyBox applets configured"
else
  _warning "BusyBox not available for setting up applets"
fi

# =============================================================================
# SHELL ENVIRONMENT CONFIGURATION
# =============================================================================
# Install and load mkshrc configuration script
rc_path="$TMPDIR/mkshrc"
rm -f "$rc_path"
[ -f "$rc_package/mkshrc.sh" ] && {
  cp -f "$rc_package/mkshrc.sh" "$rc_path"
  _success "RC script installed at $rc_path"
  
  # Load environment configuration
  _step "Loading shell environment..."
  . "$rc_path"
  _success "Shell environment loaded"
}

# =============================================================================
# INSTALLATION SUMMARY
# =============================================================================
echo ""
_info "Available tools:"
[ -f "$rc_bin/vim" ] && {
  _highlight "  ✦ vim - Advanced text editor (:q to quit, :wq to save)"
  [ -f "$rc_bin/vimtutor" ] && _highlight "  ✦ vimtutor - Interactive tutorial (run: vimtutor)"
}
[ -f "$rc_bin/htop" ] && {
  _highlight "  ✦ htop - Interactive process viewer (q to quit, F1 for help)"
}
[ -f "$rc_bin/git" ] && {
  _highlight "  ✦ git - Version control system"
  _highlight "  ✦ gitinfo - Repository information"
  _highlight "  ✦ gitclone - Enhanced cloning"
}
[ -f "$rc_bin/curl" ] && _highlight "  ✦ curl - Data transfer tool"
[ -f "$rc_bin/openssl" ] && _highlight "  ✦ openssl - Cryptography toolkit"
[ -f "$rc_bin/frida-server" ] && _highlight "  ✦ frida-server - Dynamic instrumentation"
[ -f "$rc_bin/busybox" ] && _highlight "  ✦ busybox - Unix utilities collection"

# =============================================================================
# CLEANUP AND COMPLETION
# =============================================================================
echo ""
_step "Cleaning up deployment package..."
rm -rf "$rc_package" "$TMPDIR/install.sh"
_success "Cleanup completed"

_success "mkshrc environment is now active!"
_highlight "✨ Enjoy your enhanced development environment! ✨"
echo ""