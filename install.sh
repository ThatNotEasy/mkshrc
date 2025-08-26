#!/system/bin/sh

# ==UserScript==
# @name         Android Environment Installer
# @namespace    https://github.com/user/mkshrc/
# @version      1.2
# @description  Installs mkshrc shell environment, Frida, BusyBox, vim text editor, htop process viewer, git version control, and additional binaries on Android devices
# @author       user
# @match        Android
# ==/UserScript==

# Check if a command exists in PATH
_exist() {
  command -v "$1" >/dev/null 2>&1
}

# Configurations
TMPDIR='/data/local/tmp'
CPU_ABI="$(getprop ro.product.cpu.abi)"
FRIDA=${1:-'17.2.16'} # Default Frida version if not provided

rc_package="$TMPDIR/package" # Source package folder
rc_bin="$TMPDIR/bin"         # Destination folder for binaries

# Map Android ABI to package directory structure
# Android reports: arm64-v8a, armeabi-v7a, x86, x86_64
# Package structure uses the actual Android ABI names
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
    echo "[E] Unsupported CPU ABI architecture: $CPU_ABI"
    echo "[I] Supported architectures: arm64-v8a, armeabi-v7a, x86, x86_64"
    exit 1
    ;;
esac

# Verify CPU ABI support and exit if not supported
[ ! -d "$rc_package/$PACKAGE_ABI" ] && {
  echo "[E] Package directory not found for architecture: $PACKAGE_ABI"
  echo "[E] Expected directory: $rc_package/$PACKAGE_ABI"
  echo "[I] Available architectures:"
  ls -1 "$rc_package/" | grep -E '^(arm|x86)' | sed 's/^/[I]   /'
  exit 1
}

# Clean previous installation and create fresh binary folder
echo '[I] Cleaning previous installation...'
rm -rf "$rc_bin"
mkdir -p "$rc_bin"

# Provide supolicy fallback (used in Magisk contexts)
# https://download.chainfire.eu/1220/SuperSU/
_exist supolicy || {
  echo '[I] Installing supolicy binaries...'
  # https://www.synacktiv.com/en/offers/trainings/android-for-security-engineers
  cp -f "$rc_package/$PACKAGE_ABI/supolicy/supolicy" "$rc_bin/supolicy" 2>/dev/null || echo "[W] supolicy not found for $PACKAGE_ABI"
  cp -f "$rc_package/$PACKAGE_ABI/supolicy/libsupol.so" "$rc_bin/libsupol.so" 2>/dev/null || echo "[W] libsupol.so not found for $PACKAGE_ABI"
}

# Install specific Frida server version for the device's CPU ABI
# https://github.com/frida/frida/
echo "[I] Installing Frida server version $FRIDA for $CPU_ABI..."
frida=$(find "$rc_package/$PACKAGE_ABI/frida" -type f -name "frida-server-$FRIDA*android-*")

if [ -z "$frida" ]; then
  echo "[W] Frida version $FRIDA not available for $PACKAGE_ABI"
  echo "[I] Available Frida versions:"
  find "$rc_package/$PACKAGE_ABI/frida" -type f -name "frida-server-*" 2>/dev/null | sed 's/.*frida-server-/[I]   /' | sed 's/-android.*//' | sort -u
else
  cp -f "$frida" "$rc_bin/frida-server"
  echo "[I] Installed: $(basename "$frida")"
fi

# Install frida wrapper script from architecture-specific directory
if [ -f "$rc_package/$PACKAGE_ABI/frida/frida" ]; then
  cp -f "$rc_package/$PACKAGE_ABI/frida/frida" "$rc_bin/frida"
  chmod +x "$rc_bin/frida"
  echo "[I] Installed frida wrapper script"
else
  echo "[W] Frida wrapper script not found for $PACKAGE_ABI"
fi

# Install additional CPU ABI-specific binaries
# https://github.com/topjohnwu/magisk-files/
echo '[I] Installing additional binaries...'
cp -f "$rc_package/$PACKAGE_ABI/busybox/libbusybox.so" "$rc_bin/busybox" 2>/dev/null || echo "[W] busybox not found for $PACKAGE_ABI"
# https://appuals.com/install-curl-openssl-android/
cp -f "$rc_package/$PACKAGE_ABI/curl/curl" "$rc_bin/curl" 2>/dev/null || echo "[W] curl not found for $PACKAGE_ABI"
cp -f "$rc_package/$PACKAGE_ABI/openssl/openssl" "$rc_bin/openssl" 2>/dev/null || echo "[W] openssl not found for $PACKAGE_ABI"

# Install additional utility packages
echo '[I] Installing additional utility packages...'
# Install git version control system
[ -f "$rc_package/$PACKAGE_ABI/git/git" ] && {
  cp -f "$rc_package/$PACKAGE_ABI/git/git" "$rc_bin/git"

  # Install git shared libraries if available
  if [ -d "$rc_package/$PACKAGE_ABI/git/lib" ]; then
    mkdir -p "$rc_bin/../lib"
    cp -f "$rc_package/$PACKAGE_ABI/git/lib"/* "$rc_bin/../lib/" 2>/dev/null || true
    echo '[I] Git version control system installed with shared libraries'
  else
    echo '[I] Git version control system installed'
  fi

  # Create git wrapper script if libraries are present
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
    echo '[I] Git wrapper script created for library dependencies'
  fi

  # Install additional git utilities if available
  [ -f "$rc_package/$PACKAGE_ABI/git/git-upload-pack" ] && cp -f "$rc_package/$PACKAGE_ABI/git/git-upload-pack" "$rc_bin/git-upload-pack"
  [ -f "$rc_package/$PACKAGE_ABI/git/git-receive-pack" ] && cp -f "$rc_package/$PACKAGE_ABI/git/git-receive-pack" "$rc_bin/git-receive-pack"
  [ -f "$rc_package/$PACKAGE_ABI/git/git-shell" ] && cp -f "$rc_package/$PACKAGE_ABI/git/git-shell" "$rc_bin/git-shell"
}

# Install text editors and system tools
echo '[I] Installing text editors and system tools...'
[ -f "$rc_package/$PACKAGE_ABI/vim/vim" ] && {
  cp -f "$rc_package/$PACKAGE_ABI/vim/vim" "$rc_bin/vim"
  # Install vimtutor if available
  [ -f "$rc_package/$PACKAGE_ABI/vim/vimtutor" ] && cp -f "$rc_package/$PACKAGE_ABI/vim/vimtutor" "$rc_bin/vimtutor"

  # Install vim configuration files to fix E1187 error
  if [ -d "$rc_package/$PACKAGE_ABI/vim/vim_config/usr/share/vim" ]; then
    echo '[I] Installing vim configuration files...'
    mkdir -p "$rc_bin/../share"
    cp -rf "$rc_package/$PACKAGE_ABI/vim/vim_config/usr/share/vim" "$rc_bin/../share/"

    # Set VIM environment variable to point to the config directory
    echo "export VIM=\"$rc_bin/../share/vim\"" >> "$rc_bin/../.vimrc_env"
    echo "export VIMRUNTIME=\"\$VIM/vim91\"" >> "$rc_bin/../.vimrc_env"

    # Install basic vimrc configuration
    [ -f "$rc_package/$PACKAGE_ABI/vim/vimrc_basic" ] && cp -f "$rc_package/$PACKAGE_ABI/vim/vimrc_basic" "$rc_bin/../.vimrc"
  fi

  echo '[I] Vim editor installed (with vimtutor and configuration)'
}

# Install htop process viewer
[ -f "$rc_package/$PACKAGE_ABI/htop/htop" ] && {
  cp -f "$rc_package/$PACKAGE_ABI/htop/htop" "$rc_bin/htop"

  # Install ncursesw terminfo files required for htop
  if [ -d "$rc_package/$PACKAGE_ABI/htop/usr/share" ]; then
    echo '[I] Installing terminfo files for htop...'
    mkdir -p "$rc_bin/../share"
    cp -rf "$rc_package/$PACKAGE_ABI/htop/usr/share"/* "$rc_bin/../share/"

    # Set TERMINFO environment variable
    echo "export TERMINFO=\"$rc_bin/../share/terminfo\"" >> "$rc_bin/../.htoprc_env"
    echo '[I] Htop process viewer installed (with terminfo support)'
  else
    echo '[I] Htop process viewer installed'
  fi
}

# Install script for adding root trust CA certificates
cp "$rc_package/update-ca-certificate.sh" "$rc_bin/update-ca-certificate"

# Set ownership and permissions for installed binaries to ensure accessibility
chown -R shell:shell "$rc_bin"
chmod -R 777 "$rc_bin"

# Set up BusyBox command symlinks for all available applets except 'man'
echo '[I] Setting up BusyBox commands...'
busybox="$rc_bin/busybox"
for applet in $("$busybox" --list | grep -vE '^man$'); do
  _exist "$applet" || ln -s "$busybox" "$rc_bin/$applet"
done

# Install RC script to configure shell environment
rc_path="$TMPDIR/mkshrc"
rm "$rc_path"
cp -f "$rc_package/mkshrc.sh" "$rc_path"
echo "[I] RC script installed at $rc_path"

# Load RC script to configure shell environment
echo '[I] Loading shell environment...'
source "$rc_path"

# Display information about installed tools
echo '[I] Text editors and system tools available:'
[ -f "$rc_bin/vim" ] && {
  echo '  - vim: Advanced text editor (type :q to quit, :wq to save and quit)'
  [ -f "$rc_bin/vimtutor" ] && echo '  - vimtutor: Interactive vim tutorial'
}
[ -f "$rc_bin/htop" ] && {
  if [ -f "$rc_bin/../.htoprc_env" ]; then
    echo '  - htop: Interactive process viewer (press q to quit) - with terminfo support'
  else
    echo '  - htop: Interactive process viewer (press q to quit)'
  fi
}
[ -f "$rc_bin/git" ] && {
  echo '  - git: Version control system with helpful aliases (gs, ga, gc, gp, gl, etc.)'
  echo '  - gitinfo: Show repository information'
  echo '  - gitclone: Enhanced git clone with progress'
}

# Clean up the deployment package after installation
echo '[I] Cleaning up deployment package...'
rm -rf "$rc_package" "$TMPDIR/install.sh"

echo '[I] Installation completed successfully'
echo '[I] mkshrc environment is now active'