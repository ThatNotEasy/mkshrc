#!/system/bin/sh

# ==UserScript==
# @name         Android Environment Installer
# @namespace    https://github.com/user/mkshrc/
# @version      1.2
# @description  Installs mkshrc shell environment, Frida, BusyBox, vim text editor, htop process viewer, and additional binaries on Android devices
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
FRIDA=${1:-'16.7.19'} # Default Frida version if not provided

rc_package="$TMPDIR/package" # Source package folder
rc_bin="$TMPDIR/bin"         # Destination folder for binaries

# Verify CPU ABI support and exit if not supported
[ ! -d "$rc_package/$CPU_ABI" ] && {
  echo "[E] Unsupported CPU ABI architecture: $CPU_ABI"
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
  cp -f "$rc_package/$CPU_ABI/supolicy/supolicy" "$rc_bin/supolicy"
  cp -f "$rc_package/$CPU_ABI/supolicy/libsupol.so" "$rc_bin/libsupol.so"
}

# Install specific Frida server version for the device's CPU ABI
# https://github.com/frida/frida/
echo "[I] Installing Frida server version $FRIDA..."
frida=$(find "$rc_package/$CPU_ABI/frida" -type f -name "frida-server-$FRIDA*android-*")

if [ -z "$frida" ]; then
  echo "[W] Frida version not available: $FRIDA"
else
  cp -f "$frida" "$rc_bin/frida-server"
fi

# Install additional CPU ABI-specific binaries
# https://github.com/topjohnwu/magisk-files/
echo '[I] Installing additional binaries...'
cp -f "$rc_package/$CPU_ABI/busybox/libbusybox.so" "$rc_bin/busybox"
# https://appuals.com/install-curl-openssl-android/
cp -f "$rc_package/$CPU_ABI/curl/curl" "$rc_bin/curl"
cp -f "$rc_package/$CPU_ABI/openssl/openssl" "$rc_bin/openssl"

# Install additional utility packages
echo '[I] Installing additional utility packages...'
[ -f "$rc_package/$CPU_ABI/wget/wget" ] && cp -f "$rc_package/$CPU_ABI/wget/wget" "$rc_bin/wget"

# Install text editors and system tools
echo '[I] Installing text editors and system tools...'
[ -f "$rc_package/$CPU_ABI/vim/vim" ] && {
  cp -f "$rc_package/$CPU_ABI/vim/vim" "$rc_bin/vim"
  # Install vimtutor if available
  [ -f "$rc_package/$CPU_ABI/vim/vimtutor" ] && cp -f "$rc_package/$CPU_ABI/vim/vimtutor" "$rc_bin/vimtutor"

  # Install vim configuration files to fix E1187 error
  if [ -d "$rc_package/$CPU_ABI/vim/vim_config/usr/share/vim" ]; then
    echo '[I] Installing vim configuration files...'
    mkdir -p "$rc_bin/../share"
    cp -rf "$rc_package/$CPU_ABI/vim/vim_config/usr/share/vim" "$rc_bin/../share/"

    # Set VIM environment variable to point to the config directory
    echo "export VIM=\"$rc_bin/../share/vim\"" >> "$rc_bin/../.vimrc_env"
    echo "export VIMRUNTIME=\"\$VIM/vim91\"" >> "$rc_bin/../.vimrc_env"

    # Install basic vimrc configuration
    [ -f "$rc_package/$CPU_ABI/vim/vimrc_basic" ] && cp -f "$rc_package/$CPU_ABI/vim/vimrc_basic" "$rc_bin/../.vimrc"
  fi

  echo '[I] Vim editor installed (with vimtutor and configuration)'
}

# Install htop process viewer
[ -f "$rc_package/$CPU_ABI/htop/htop" ] && {
  cp -f "$rc_package/$CPU_ABI/htop/htop" "$rc_bin/htop"

  # Install ncursesw terminfo files required for htop
  if [ -d "$rc_package/$CPU_ABI/htop/usr/share" ]; then
    echo '[I] Installing terminfo files for htop...'
    mkdir -p "$rc_bin/../share"
    cp -rf "$rc_package/$CPU_ABI/htop/usr/share"/* "$rc_bin/../share/"

    # Set TERMINFO environment variable
    echo "export TERMINFO=\"$rc_bin/../share/terminfo\"" >> "$rc_bin/../.htoprc_env"
    echo '[I] Htop process viewer installed (with terminfo support)'
  else
    echo '[I] Htop process viewer installed'
  fi
}
[ -f "$rc_package/$CPU_ABI/htop/htop" ] && cp -f "$rc_package/$CPU_ABI/htop/htop" "$rc_bin/htop"

# Install system administration tools
[ -f "$rc_package/$CPU_ABI/sudo/sudo" ] && cp -f "$rc_package/$CPU_ABI/sudo/sudo" "$rc_bin/sudo"
[ -f "$rc_package/$CPU_ABI/fakeroot/fakeroot" ] && {
    cp -f "$rc_package/$CPU_ABI/fakeroot/fakeroot" "$rc_bin/fakeroot"
    # Copy fakeroot daemon and library (needed for real fakeroot)
    [ -f "$rc_package/$CPU_ABI/fakeroot/faked" ] && cp -f "$rc_package/$CPU_ABI/fakeroot/faked" "$rc_bin/faked"
    [ -f "$rc_package/$CPU_ABI/fakeroot/libfakeroot-0.so" ] && cp -f "$rc_package/$CPU_ABI/fakeroot/libfakeroot-0.so" "$rc_bin/libfakeroot-0.so"
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

# Clean up the deployment package after installation
echo '[I] Cleaning up deployment package...'
rm -rf "$rc_package" "$TMPDIR/install.sh"

echo '[I] Installation completed successfully'
echo '[I] mkshrc environment is now active'
