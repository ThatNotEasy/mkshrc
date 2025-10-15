#!/system/bin/sh

# ==UserScript==
# @name         mkshrc
# @namespace    https://github.com/user/mkshrc/
# @version      1.5
# @description  Advanced shell environment configuration for Android devices (mksh/sh compatible)
# @author       user
# @match        Android
# ==/UserScript==

###############################################################################
# Utility Functions
###############################################################################

# Check if a command exists in PATH
_exist() {
  command -v "$1" >/dev/null 2>&1
}

# Color functions
_info() { echo -e "${BLUE:-}[I]${NC:-} $1"; }
_success() { echo -e "${GREEN:-}[✓]${NC:-} $1"; }
_warning() { echo -e "${YELLOW:-}[W]${NC:-} $1"; }
_error() { echo -e "${RED:-}[E]${NC:-} $1"; }
_step() { echo -e "${CYAN:-}[→]${NC:-} $1"; }
_highlight() { echo -e "${WHITE:-}${1}${NC:-}"; }

# Resolve the actual binary path, handling aliases
# Example: if "ls" is an alias, this returns the real command target
_resolve() {
   local binary="$1"
   local resolved="$(command -v "$binary" 2>/dev/null)"

   # If the result is an alias, extract the target
   if echo "$resolved" | grep -q '^alias '; then
     # Extract alias target more robustly
     binary="$(echo "$resolved" | sed 's/^alias [^=]*=//' | sed 's/^ *//' | sed 's/ *$//')"
   fi

   # Remove surrounding quotes if present (both single and double)
   echo "$binary" | sed "s/^'\(.*\)'$/\1/" | sed 's/^"\(.*\)"$/\1/'
}

###############################################################################
# Environment Setup
###############################################################################

export HOSTNAME="$(getprop ro.boot.serialno)" # Android device serial
export USER="$(id -u -n)"                     # Current username
export LOGNAME="$USER"                        # Ensure LOGNAME matches USER
export TMPDIR='/data/local/tmp'               # Temporary directory
export STORAGE='/storage/self/primary'        # Default shared storage (internal)



###############################################################################
# Aliases and Quality of Life Shortcuts
###############################################################################

# Detect whether the terminal supports color (via ls check)
ls --color=auto "$TMPDIR" >/dev/null 2>&1 && color_prompt=yes

if [ "$color_prompt" = yes ]; then
  # Enable colorized output if supported
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias logcat='logcat -v color'
  alias diff='diff --color'
fi

# Common shortcuts - resolve at runtime for dynamic updates
alias ll='ls -alF'     # long list with file types
alias la='ls -A'       # list all except . and ..
alias l='ls -CF'       # compact list
alias rm='rm -rf'                  # recursive remove (dangerous but convenient)
alias reset='stty sane < /dev/tty' # restore terminal to default state
export FIGNORE=''

# Networking commands
_exist ip && {
  [ "$color_prompt" = yes ] && alias ip='ip -c'
  alias ipa="$(_resolve ip) a" # Show IP addresses
}

# Fallbacks for common tools if not present
_exist ss || alias ss='netstat'
_exist nc || alias nc='netcat'



# Git aliases and shortcuts (if git is available)
_exist git && {
  alias gs='git status'
  alias ga='git add'
  alias gc='git commit'
  alias gp='git push'
  alias gl='git pull'
  alias gd='git diff'
  alias gb='git branch'
  alias gco='git checkout'
  alias glog='git log --oneline --graph --decorate'
  alias gstash='git stash'
  alias gunstash='git stash pop'
}

# Use ps -A if it shows more processes than default ps
[ "$(ps -A | wc -l)" -gt 1 ] && alias ps='ps -A'

# Create a custom colored find command if both find and color support are available
_exist find && [ "$color_prompt" = yes ] && {
  alias cfind="find \"$*\" | sed 's/\\n/ /g' | xargs $(_resolve ls) -d"
}

pull() {
   local src_path="$1"
   [ -z "$src_path" ] && { echo "Usage: pull <path>"; return 1; }
   [ ! -e "$src_path" ] && { echo "Source path does not exist: $src_path"; return 1; }

   local tmp_path="$TMPDIR/$(basename "$src_path")"

   # Ensure destination directory exists for directories
   if [ -d "$src_path" ]; then
     mkdir -p "$tmp_path" 2>/dev/null || { echo "Failed to create destination directory"; return 1; }
   fi

   # Decide whether to use sudo (only if current user is NOT root)
   [ "$(sudo id -un 2>&1)" = 'root' ] && local prefix='sudo'

   # Copy file into TMPDIR (suppressing output). Fail fast if copy fails.
   $prefix cp -af "$src_path" "$tmp_path" >/dev/null 2>&1 || {
     echo "Failed to copy $src_path"
     return 1
   }

   # Change ownership to 'shell:shell' so that the adb shell user can access it.
   # -R ensures it works for directories too.
   $prefix chown -R shell:shell "$tmp_path" >/dev/null 2>&1 || {
     echo "Failed to chown $tmp_path"
   }

   # Set SELinux context to match shell data files, again recursive for directories.
   $prefix chcon -R u:object_r:shell_data_file:s0 "$tmp_path" >/dev/null 2>&1 || {
     echo "Failed to set SELinux context on $tmp_path"
   }

   echo "Pulled: $tmp_path"
}
export pull

# Git helper function for quick repository status
gitinfo() {
  _exist git || {
    echo 'git command not found' >&2
    return 1
  }

  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git rev-parse --is-inside-git-dir >/dev/null 2>&1; then
    echo 'Not in a git repository' >&2
    return 1
  fi

  echo "=== Git Repository Information ==="
  echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
  echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached HEAD')"
  echo "Remote: $(git remote get-url origin 2>/dev/null || echo 'no remote')"
  echo
  echo "=== Status ==="
  git status --short
  echo
  echo "=== Recent Commits ==="
  git log --oneline -5 2>/dev/null || echo 'No commits yet'
}
export gitinfo

# Git clone with progress and error handling
gitclone() {
  _exist git || {
    echo 'git command not found' >&2
    return 1
  }

  if [ $# -eq 0 ]; then
    echo 'Usage: gitclone <repository-url> [directory]' >&2
    return 1
  fi

  local repo_url="$1"
  local target_dir="$2"

  echo "Cloning repository: $repo_url"
  if [ -n "$target_dir" ]; then
    git clone --progress "$repo_url" "$target_dir"
  else
    git clone --progress "$repo_url"
  fi
}
export gitclone

restart() {
  # Magisk & other root managers rely on overlayfs or tmpfs mounts that insert or hide su binaries and management files at boot.
  # When you do a soft reboot (zygote / framework restart, not full kernel reboot):
  # - The system services restart.
  # - But Magisk’s init-time mount overlays don’t get re-applied, because init didn’t rerun.
  # Result:
  # - /sbin/su, /system/xbin/su, etc. may not be mounted anymore.
  # - which su won’t find anything in $PATH.

  # Verify that the current user has root privileges
  [ "$(sudo id -un 2>&1)" = 'root' ] || {
    echo 'Permission denied. Privileged user not available.'
    exit 1
  }

  # Soft reboot via init: stop and restart the Android framework.
  # This does not reboot the kernel, only restarts system services.
  # Reference: https://source.android.com/docs/core/runtime/soft-restart

  # Effect: Kills all Android framework services and restarts them.
  # Pros: Works on older Android (pre-Android 8 especially), very thorough.
  # Cons:
  # - Slow (almost like a full reboot).
  # - On newer Android (10+), init often blocks this, or services don’t come back cleanly.
  # - Risk of bootloop if start doesn’t fully reinitialize.
  # Not very stable on modern Android.
  #sudo stop
  #sudo start

  # Effect: Signals init to restart the zygote service (which spawns all apps and system_server).
  # Pros:
  # - Officially supported mechanism.
  # - Fast, cleaner than killing processes.
  # - Works on Android 5 → Android latest.
  # Cons: Some devices split into zygote / zygote_secondary, so you may need both.
  # Most stable & recommended across versions.
  sudo setprop ctl.restart zygote

  # Effect: Hard-kills zygote, Android restarts it automatically.
  # Pros: Works even if setprop isn’t available or blocked.
  # Cons:
  # - Dirty (no graceful shutdown).
  # - Can cause crashes, logs filled with errors.
  # - On some devices, may trigger watchdog → full reboot.
  # Works, but hacky and less reliable.
  #sudo kill -9 $(pidof zygote)

  # Effect: Kills system_server; zygote will restart it.
  # Pros: Faster than full zygote restart.
  # Cons:
  # - Leaves zygote alive (not a clean reset).
  # - Often unstable afterward (services missing, ANRs).
  # - Some Android versions will panic → reboot.
  # Least stable.
  #sudo kill -9 $(pidof system_server)
}
export restart

# Fix mksh vi mode issues when editing multi-line
_vi() {
  # https://github.com/matan-h/adb-shell/blob/main/startup.sh#L52
  set +o emacs +o vi-tabcomplete
  vi "$@"
  set -o emacs -o vi-tabcomplete
  set +o noclobber
}
alias vi=_vi

# Basic replacement for "man" since Android usually lacks it
man() {
  local binary="$(_resolve "$1" | cut -d ' ' -f1)"

  # Handle empty or recursive call (man man)
  if [ -z "$binary" ] || [ "$binary" = 'man' ]; then
    echo -e "What manual page do you want?\nFor example, try 'man ls'." >&2
    return 1
  fi

  # Use --help output as a poor-man’s manual
  local manual="$("$binary" --help 2>&1)"
  if [ $? -eq 127 ] || [ -z "$manual" ]; then
    echo "No manual entry for $binary" >&2
    return 16
  fi

  $binary --help
}
export man

# Sudo wrapper (works with root / su / Magisk)
sudo() {
  [ $# -eq 0 ] && {
    echo 'Usage: sudo <command>' >&2
    return 1
  }

  local binary="$(_resolve "$1")"
  local prompt="$(echo "$@" | sed "s:$1:$binary:g")"

  if [ "$(id -u)" -eq 0 ]; then
    # Already root
    $prompt
  else
    _exist su || {
      echo 'su binary not found' >&2
      return 127
    }

    # Detect su format (standard or Magisk)
    local su_pty="$(_resolve su) root"
    if su ---help 2>&1 | grep -q -- '-c'; then
      su_pty="$(_resolve su) -c"
    fi

    # Force PTY resolution
    reset

    # https://stackoverflow.com/questions/27274339/how-to-use-su-command-over-adb-shell/
    $su_pty $prompt
  fi
}
export sudo

frida() {
   # Show help first (before checking for binary)
   case "$1" in
   -h|--help|help)
     echo "Frida server management utility"
     echo ""
     echo "Usage: frida {start|status|stop|version|help}"
     echo ""
     echo "Commands:"
     echo "  start    Start the Frida server in daemon mode"
     echo "  status   Check if Frida server is running"
     echo "  stop     Stop the Frida server"
     echo "  version  Show Frida server version"
     echo "  help     Show this help message"
     echo ""
     echo "Note: Root privileges recommended for start/stop operations"
     echo "      Can run without root on some devices/configurations"
     echo "      Requires frida-server binary in PATH"
     return 0
     ;;
   version)
     # Show Frida version without binary check
     frida-server --version 2>/dev/null && return 0
     echo 'frida-server binary not found in PATH' >&2
     return 1
     ;;
   esac

  # Ensure the frida-server binary is available
  _exist frida-server || {
    echo 'frida-server binary not found in PATH' >&2
    echo 'Use "frida help" for usage information' >&2
    return 1
  }

  # Version check moved to case statement above

  # Helper function to check if frida-server is running (avoids recursion)
  _frida_is_running() {
    pgrep -x frida-server >/dev/null 2>&1
  }

  # Check if we have root privileges (optional for non-rooted devices)
  _has_root() {
    # Try multiple methods to detect root access
    [ "$(id -u 2>/dev/null)" = "0" ] && return 0  # Already root
    [ "$(sudo id -un 2>/dev/null)" = "root" ] && return 0  # Can sudo to root
    command -v su >/dev/null 2>&1 && su -c 'id -u' 2>/dev/null | grep -q '^0$' && return 0  # Can su to root
    return 1  # No root access
  }

  case "$1" in
  start)
    # Start Frida server if not already running
    if _frida_is_running; then
      echo 'Already running' >&2
      return 1
    fi

    # Try to start frida-server with appropriate privileges
    if _has_root; then
      echo '[I] Starting frida-server with root privileges...'
      sudo setenforce 0 >/dev/null 2>&1 # disable SELinux temporarily
      sudo frida-server -D || {
        echo 'Start failed with root privileges' >&2
        return 1
      }
    else
      echo '[I] Starting frida-server without root (may have limited functionality)...'
      frida-server -D || {
        echo 'Start failed without root privileges' >&2
        echo 'Try running with root access or check device permissions' >&2
        return 1
      }
    fi
    echo 'Started'
    ;;
  status)
    # Check if Frida server is running
    local pid="$(pgrep -f frida-server)"
    [ -z "$pid" ] && {
      echo 'Stopped'
      return 1
    }
    echo "Running ($pid)"
    ;;
  stop)
    # Stop Frida server
    local pids="$(pgrep -f frida-server)"
    if [ -n "$pids" ]; then
      # Try to kill with appropriate privileges
      if _has_root; then
        echo '[I] Stopping frida-server with root privileges...'
        sudo kill -9 $pids 2>/dev/null || {
          echo 'Failed to kill frida-server processes with root' >&2
          return 1
        }
        #sudo setenforce 1 >/dev/null 2>&1  # re-enable SELinux
      else
        echo '[I] Stopping frida-server without root...'
        kill -9 $pids 2>/dev/null || {
          echo 'Failed to kill frida-server processes without root' >&2
          echo 'Try running with root access or use task manager' >&2
          return 1
        }
      fi
    else
      echo 'No frida-server processes found' >&2
      return 1
    fi
    sleep 1

    if _frida_is_running; then
      _exist magisk && echo 'Use Magisk to stop' >&2 || echo 'Still running' >&2
      return 1
    fi
    echo 'Stopped'
    ;;
  *)
    # Invalid usage
    echo 'Usage: frida {start|status|stop|version|help}' >&2
    echo 'Use "frida help" for more information' >&2
    return 1
    ;;
  esac
}
export frida

# WiFi configuration parser - displays saved WiFi networks with SSID, password, and security
wlan() {
  local config_file="/data/misc/wifi/WifiConfigStore.xml"
  local wpa_file="/data/misc/wifi/wpa_supplicant.conf"
  local local_config="$TMPDIR/package/WifiConfigStore.xml"
  local local_wpa="$TMPDIR/package/wpa_supplicant.conf"
  local tmp_config="$TMPDIR/WifiConfigStore.xml"
  local tmp_wpa="$TMPDIR/wpa_supplicant.conf"

  echo "=== WiFi Network Information ==="
  echo

  # Try to read saved networks from local copies first (works on non-rooted devices)
  if [ -f "$local_config" ]; then
    config_file="$local_config"
    echo "Using local WifiConfigStore.xml copy from package/"
  elif [ -f "$tmp_config" ]; then
    config_file="$tmp_config"
    echo "Using WifiConfigStore.xml copy from tmp/"
  fi

  if [ -f "$local_wpa" ]; then
    wpa_file="$local_wpa"
    echo "Using local wpa_supplicant.conf copy from package/"
  elif [ -f "$tmp_wpa" ]; then
    wpa_file="$tmp_wpa"
    echo "Using wpa_supplicant.conf copy from tmp/"
  fi

  # Try to read saved networks from WifiConfigStore.xml (requires root on most devices)
  if [ -f "$config_file" ] && head -1 "$config_file" >/dev/null 2>&1; then
    echo "=== Saved Networks (from $config_file) ==="

    # Parse networks using sed and grep for better compatibility
    networks=$(grep -n "<Network>" "$config_file" | cut -d: -f1)
    for start_line in $networks; do
      # Find the end of this network block
      end_line=$(tail -n +$start_line "$config_file" | grep -n "</Network>" | head -1 | cut -d: -f1)
      end_line=$((start_line + end_line - 1))

      # Extract network block
      network_block=$(sed -n "${start_line},${end_line}p" "$config_file")

      # Extract SSID
      ssid=$(echo "$network_block" | grep '<string name="SSID">' | sed 's|.*<string name="SSID">||; s|</string>.*||')

      # Extract PreSharedKey
      psk=$(echo "$network_block" | grep '<string name="PreSharedKey">' | sed 's|.*<string name="PreSharedKey">||; s|</string>.*||')

      # Extract KeyMgmt
      keymgmt=$(echo "$network_block" | grep '<string name="KeyMgmt">' | sed 's|.*<string name="KeyMgmt">||; s|</string>.*||')

      if [ -n "$ssid" ]; then
        security="Open"
        case "$keymgmt" in
          "WPA_PSK") security="WPA/WPA2" ;;
          "WPA2_PSK") security="WPA2" ;;
          "WPA3_PSK") security="WPA3" ;;
          "IEEE8021X") security="802.1X" ;;
        esac

        echo "SSID: $ssid"
        echo "Password: $psk"
        echo "Security: $security"
        echo "----------------------------------------"
      fi
    done
  elif [ -f "$config_file" ]; then
    echo "=== Saved Networks ==="
    echo "System config file exists but requires root access to read."
    echo "Try: sudo wlan"
    echo
  fi

  # Try to read from wpa_supplicant.conf (may be accessible on some devices)
  if [ -f "$wpa_file" ] && head -1 "$wpa_file" >/dev/null 2>&1; then
    echo "=== Networks from wpa_supplicant ==="

    # Parse wpa_supplicant.conf using sed
    networks=$(grep -n "^network={" "$wpa_file" | cut -d: -f1)
    for start_line in $networks; do
      # Find the end of this network block
      end_line=$(tail -n +$start_line "$wpa_file" | grep -n "^}" | head -1 | cut -d: -f1)
      end_line=$((start_line + end_line - 1))

      # Extract network block
      network_block=$(sed -n "${start_line},${end_line}p" "$wpa_file")

      # Extract SSID
      ssid=$(echo "$network_block" | grep '^[[:space:]]*ssid=' | sed 's/.*ssid="\([^"]*\)".*/\1/')

      # Extract PSK
      psk=$(echo "$network_block" | grep '^[[:space:]]*psk=' | sed 's/.*psk="\([^"]*\)".*/\1/')

      if [ -n "$ssid" ]; then
        echo "SSID: $ssid"
        echo "Password: $psk"
        echo "Security: WPA/WPA2"
        echo "----------------------------------------"
      fi
    done
  fi

  # Show current connection info using dumpsys (works on most devices)
  echo "=== Current Connection ==="
  if _exist dumpsys; then
    # Capture dumpsys output once to avoid broken pipe errors
    local dumpsys_output=$(dumpsys wifi 2>/dev/null)

    # Extract information from the captured output
    local connected_ssid=$(echo "$dumpsys_output" | grep -E "SSID:" | head -1 | sed 's/.*SSID: \([^,]*\).*/\1/' | tr -d '"')
    local connected_bssid=$(echo "$dumpsys_output" | grep -E "BSSID:" | head -1 | sed 's/.*BSSID: \([^,]*\).*/\1/')
    local link_speed=$(echo "$dumpsys_output" | grep -E "linkSpeed:" | head -1 | sed 's/.*linkSpeed: \([^,]*\).*/\1/')
    local wifi_standard=$(echo "$dumpsys_output" | grep -E "wifiStandard:" | head -1 | sed 's/.*wifiStandard: \([^,]*\).*/\1/')
    local is_connected=$(echo "$dumpsys_output" | grep -E "mIsConnected:" | head -1 | awk '{print $2}')
    local ip_addr=$(echo "$dumpsys_output" | grep -E "ipAddress:" | head -1 | sed 's/.*ipAddress: \([^,]*\).*/\1/')
    local gateway=$(echo "$dumpsys_output" | grep -E "gateway:" | head -1 | sed 's/.*gateway: \([0-9.]*\).*/\1/')

    if [ "$is_connected" = "true" ] && [ -n "$connected_ssid" ]; then
      echo "Connected to: $connected_ssid"
      [ -n "$connected_bssid" ] && echo "BSSID: $connected_bssid"
      [ -n "$wifi_standard" ] && echo "WiFi Standard: $wifi_standard"
      [ -n "$link_speed" ] && echo "Link Speed: $link_speed Mbps"
      [ -n "$ip_addr" ] && echo "IP Address: $ip_addr"
      [ -n "$gateway" ] && echo "Gateway: $gateway"
    else
      echo "Not connected to any WiFi network"
    fi
  else
    echo "dumpsys not available for connection info"
  fi

  echo
  echo "Note: Passwords are only shown for networks with saved credentials."
  echo "Some networks may use other authentication methods."
  echo "For full access to saved networks, root privileges may be required."
}
export wlan

###############################################################################
# Persistence Handling (mkshrc overlay before reboot)
###############################################################################

SYSTEM_RC='/system/etc'
VENDOR_RC='/vendor/etc'
# Determine the default RC directory
if [ -d "/system" ] && [ -d "/data/local/tmp" ]; then
  # On Android, use TMPDIR
  DEFAULT_RC="${TMPDIR:-/data/local/tmp}"
else
  # Not on Android, use current script directory
  DEFAULT_RC="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")" 2>/dev/null || dirname "$0")"
fi

# Detect where to install mkshrc based on privilege
_detect() {
  if [ "$(sudo id -un 2>&1)" = 'root' ]; then
    [ -f "$SYSTEM_RC/mkshrc" ] && echo "$SYSTEM_RC" && return
    [ -f "$VENDOR_RC/mkshrc" ] && echo "$VENDOR_RC" && return
  fi
  echo "$1"
}

rc_root="$DEFAULT_RC"            # fallback to temp dir
rc_tmpfs="$(_detect "$rc_root")" # check for root locations

#echo "[D] DEFAULT_RC: $DEFAULT_RC"
#echo "[D] RC root path: $rc_root"
#echo "[D] RC tmpfs path: $rc_tmpfs"

# If persistent mode possible, mount tmpfs over target path
if [ "$rc_root" != "$rc_tmpfs" ]; then
  if [ ! -d "$rc_tmpfs/bin" ]; then
    # Create a temporary backup directory
    rc_bak="$(mktemp -d)"

    # Copy all existing files from the tmpfs target into the backup directory
    sudo cp -af "$rc_tmpfs"/* "$rc_bak"
    #sudo cp -dprf "$rc_tmpfs"/* "$rc_bak"

    # Mount a tmpfs filesystem over the target directory
    sudo mount -t tmpfs tmpfs "$rc_tmpfs"

    # Restore the backup files into the newly mounted tmpfs
    sudo cp -af "$rc_bak"/* "$rc_tmpfs"
    sudo rm -rf "$rc_bak" # Clean up temporary backup

    # Copy the current script into tmpfs
    sudo cp -af "$DEFAULT_RC/mkshrc" "$rc_tmpfs/mkshrc"

    # Recursively copy the "bin" folder (containing binaries) into tmpfs
    sudo cp -af "$rc_root/bin" "$rc_tmpfs/bin"

    # Set ownership of all files in tmpfs to root:root
    sudo chown -R root:root "$rc_tmpfs"

    # Set ownership of mkshrc and bin to shell:shell for adb access
    sudo chown -R shell:shell "$rc_tmpfs/mkshrc" "$rc_tmpfs/bin"

    # Restoring SELinux objects by default
    sudo chcon -R u:object_r:system_file:s0 "$rc_tmpfs"
    sudo chcon u:object_r:cgroup_desc_file:s0 "$rc_tmpfs/cgroups.json" >/dev/null 2>&1
    sudo chcon u:object_r:system_font_fallback_file:s0 "$rc_tmpfs/font_fallback.xml" >/dev/null 2>&1
    sudo chcon u:object_r:system_event_log_tags_file:s0 "$rc_tmpfs/event-log-tags" >/dev/null 2>&1
    sudo chcon u:object_r:system_group_file:s0 "$rc_tmpfs/group" >/dev/null 2>&1
    sudo chcon u:object_r:system_passwd_file:s0 "$rc_tmpfs/passwd" >/dev/null 2>&1
    sudo chcon -R u:object_r:system_perfetto_config_file:s0 "$rc_tmpfs/perfetto" >/dev/null 2>&1
    sudo chcon u:object_r:system_linker_config_file:s0 "$rc_tmpfs/ld.config."* >/dev/null 2>&1
    sudo chcon -R u:object_r:system_seccomp_policy_file:s0 "$rc_tmpfs/seccomp_policy/" >/dev/null 2>&1
    sudo chcon u:object_r:system_linker_config_file:s0 "$rc_tmpfs/somxreg.conf" >/dev/null 2>&1
    sudo chcon u:object_r:task_profiles_file:s0 "$rc_tmpfs/task_profiles.json" >/dev/null 2>&1

    # Provide edition support
    sudo chcon -R u:object_r:shell_data_file:s0 "$rc_tmpfs/mkshrc" "$rc_tmpfs/bin"

    # Set SELinux context for bin directory to allow execution
    sudo chcon -R u:object_r:system_file:s0 "$rc_tmpfs/bin"

    rc_root="$rc_tmpfs"
    echo '[I] Script mount permanently until next reboot'
  #else
  #  echo '[D] RC already defined persistently'
  fi
else
  echo '[E] RC in persistent mode unavailable'
  echo '[W] Script sets for current shell context only'
  # Keep rc_root as DEFAULT_RC when persistence is not available
  rc_root="$DEFAULT_RC"
fi

rc_bin="$rc_root/bin"

# Ensure the bin directory exists
[ ! -d "$rc_bin" ] && {
  echo "[W] Bin directory not found: $rc_bin"
  echo "[I] Creating bin directory..."
  mkdir -p "$rc_bin" 2>/dev/null || {
    echo "[E] Failed to create bin directory"
  }
}

# Add to PATH if not already there and directory exists
if [ -d "$rc_bin" ]; then
  echo "$PATH" | grep -q "$rc_bin" || export PATH="$PATH:$rc_bin"
  # Removed PATH log message as requested
else
  echo "[E] Bin directory does not exist: $rc_bin"
fi

# Provide supolicy fallback (used in Magisk contexts)
[ -f "$rc_bin/libsupol.so" ] && alias supolicy="LD_LIBRARY_PATH='$rc_bin' $rc_bin/supolicy"

###############################################################################
# Prompt & Colors
###############################################################################

set +o nohup # disable nohup mode

# Keep PS4 with timestamps
PS4='[$EPOCHREALTIME] '

# Regular colors
BLACK=$'\E[0;30m'
RED=$'\E[0;31m'
GREEN=$'\E[0;32m'
YELLOW=$'\E[0;33m'
BLUE=$'\E[0;34m'
MAGENTA=$'\E[0;35m'
CYAN=$'\E[0;36m'
WHITE=$'\E[0;37m'

# Bright colors
BRIGHT_BLACK=$'\E[1;30m'
BRIGHT_RED=$'\E[1;31m'
BRIGHT_GREEN=$'\E[1;32m'
BRIGHT_YELLOW=$'\E[1;33m'
BRIGHT_BLUE=$'\E[1;34m'
BRIGHT_MAGENTA=$'\E[1;35m'
BRIGHT_CYAN=$'\E[1;36m'
BRIGHT_WHITE=$'\E[1;37m'

# Styles
BOLD=$'\E[1m'
UNDERLINE=$'\E[4m'
REVERSE=$'\E[7m'

# Reset
RESET=$'\E[0m'

# Shell context (SELinux domain)
ctx_shell="$(id -Z 2>/dev/null | awk -F: '{print $3}')"

# Parrot OS style prompt colors and symbols
if [ "$(id -u)" -eq 0 ]; then
  # Root user - red theme with danger symbol
  user_color="$BRIGHT_RED"
  host_color="$RED"
  symbol_color="$BRIGHT_RED"
  prompt_symbol="💀"
  ctx_type='#'
else
  # Regular user - cyan/green theme with parrot symbol
  user_color="$BRIGHT_CYAN"
  host_color="$BRIGHT_GREEN"
  symbol_color="$BRIGHT_MAGENTA"
  prompt_symbol="🦜"
  ctx_type='$'
fi



# Set up a simple prompt without persistent history
if [ "$color_prompt" = yes ]; then
  PS1='${|
  local e=$?
 
  # Show exit code if non-zero with red background
  (( e )) && REPLY+="${RESET}${WHITE}${RED} ${e} ${RESET} "
 
  return $e
}${BRIGHT_WHITE}[${BRIGHT_YELLOW}$(date "+%H:%M:%S")${BRIGHT_WHITE}]${symbol_color}${prompt_symbol} ${user_color}${USER}${WHITE}@${host_color}${HOSTNAME} ${WHITE}in ${BRIGHT_CYAN}${|
  # Show full relative path for subdirectories
  if [ "$PWD" = "$HOME" ]; then
    REPLY="~"
  elif echo "$PWD" | grep -q "^$HOME/"; then
    REPLY="~/${PWD#"$HOME/"}"
  else
    REPLY="$PWD"
  fi
}${WHITE}${YELLOW}${ctx_shell:+ (${ctx_shell})}
${symbol_color}└─${ctx_type}${RESET} '
else
  PS1='${|
  local e=$?
 
  # Show exit code if non-zero
  (( e )) && REPLY+="[${e}] "
 
  return $e
}[$(date "+%H:%M:%S")]${USER}@${HOSTNAME} in ${|
  # Show full relative path for subdirectories
  if [ "$PWD" = "$HOME" ]; then
    REPLY="~"
  elif echo "$PWD" | grep -q "^$HOME/"; then
    REPLY="~/${PWD#"$HOME/"}"
  else
    REPLY="$PWD"
  fi
}${ctx_shell:+ (${ctx_shell})}
└─${ctx_type} '
fi

###############################################################################
# Tab Completion Configuration
###############################################################################

# Enable tab completion and vi-style editing
set -o vi-tabcomplete
set -o emacs

# Case-insensitive directory completion for mksh
# Optimized version with better performance and cleaner code

# Function to find case-insensitive directory matches
_find_case_insensitive_dirs() {
    local search_path="$1"
    local search_dir="." search_pattern="$search_path"
    
    # Parse the search path if it contains slashes
    case "$search_path" in
        */*)
            search_dir="${search_path%/*}"
            search_pattern="${search_path##*/}"
            [[ -z "$search_dir" ]] && search_dir="/"
            ;;
    esac
    
    [[ ! -d "$search_dir" ]] && return 1
    
    local matches="" entry basename full_path
    local lower_pattern="$(echo "$search_pattern" | tr '[:upper:]' '[:lower:]')"
    
    for entry in "$search_dir"/*; do
        [[ ! -d "$entry" ]] && continue
        basename="${entry##*/}"
        [[ "$basename" = "." || "$basename" = ".." ]] && continue
        
        local lower_basename="$(echo "$basename" | tr '[:upper:]' '[:lower:]')"
        case "$lower_basename" in
            "$lower_pattern"*)
                # Build plain full path for insertion, but color for display
                if [[ "$search_dir" = "." ]]; then
                    full_path="$basename/"
                elif [[ "$search_dir" = "/" ]]; then
                    full_path="/$basename/"
                else
                    full_path="$search_dir/$basename/"
                fi
                matches="$matches${BRIGHT_CYAN}${full_path}${RESET}
"
                ;;
        esac
    done
    
    printf '%s' "$matches"
}

# Enhanced cd function with case-insensitive completion support
cd() {
     # Go to home directory if no arguments
     [ $# -eq 0 ] && { builtin cd; return $?; }

     local target="$1"

     # Use target directly if it exists
     [ -d "$target" ] && { builtin cd "$target"; return $?; }

     local dir="${target%/*}" base="${target##*/}"
     [ "$dir" = "$target" ] && dir="."

     # Look for case-insensitive match (POSIX compatible)
     if [ -d "$dir" ]; then
         local entry basename
         local lower_base="$(echo "$base" | tr '[:upper:]' '[:lower:]')"
         for entry in "$dir"/*; do
             [ ! -d "$entry" ] && continue
             basename="${entry##*/}"
             local lower_basename="$(echo "$basename" | tr '[:upper:]' '[:lower:]')"
             [ "$lower_basename" = "$lower_base" ] && { builtin cd "$entry"; return $?; }
         done
     fi

     # Fall back to original target
     builtin cd "$target"
}

# Main completion function
_case_insensitive_completion() {
    local current_line="${COMP_LINE:-$1}" current_word="${COMP_WORDS[COMP_CWORD]}"
    [[ -z "$current_word" ]] && current_word="${current_line##* }"
    
    # Only handle cd command
    [[ "${current_line%% *}" != "cd" ]] && return 1
    
    local search_dir="." search_pattern="$current_word"
    
    # Parse path components
    case "$current_word" in
        */*)
            search_dir="${current_word%/*}"
            search_pattern="${current_word##*/}"
            [[ -z "$search_dir" ]] && search_dir="/"
            ;;
    esac
    
    [[ ! -d "$search_dir" ]] && return 1
    
    local matches="" entry basename full_path
    local lower_pattern="$(echo "$search_pattern" | tr '[:upper:]' '[:lower:]')"
    
    for entry in "$search_dir"/*; do
        [[ ! -d "$entry" ]] && continue
        basename="${entry##*/}"
        [[ "$basename" = "." || "$basename" = ".." ]] && continue
        
        # Use case conversion for comparison (mksh compatible)
        local lower_basename="$(echo "$basename" | tr '[:upper:]' '[:lower:]')"
        case "$lower_basename" in
            "$lower_pattern"*)
                # Build plain full path for insertion, but color for display
                if [[ "$search_dir" = "." ]]; then
                    full_path="$basename/"
                elif [[ "$search_dir" = "/" ]]; then
                    full_path="/$basename/"
                else
                    full_path="$search_dir/$basename/"
                fi
                matches="$matches${BRIGHT_CYAN}${full_path}${RESET}
"
                ;;
        esac
    done
    
    printf '%s' "$matches"
    return 0
}

# Set up completion
if bind -x '"\t": _case_insensitive_completion' 2>/dev/null; then
    echo "[I] Case-insensitive tab completion enabled for mksh"
else
    # Fallback: enhanced cd function still works
    echo "[I] Enhanced cd with case-insensitive matching enabled"
    echo "[I] Note: Tab completion may not be case-insensitive"
fi

# Clean up environment
# set +o nocaseglob 2>/dev/null || true
export FIGNORE=''

###############################################################################
# Additional Configurations
###############################################################################

# Source additional shell configurations if they exist
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
[ -f "$HOME/.profile" ] && source "$HOME/.profile"

# Source vim environment variables if available (fixes E1187 error)
[ -f "$rc_bin/../.vimrc_env" ] && source "$rc_bin/../.vimrc_env"

# Source htop environment variables if available (sets TERMINFO for proper display)
[ -f "$rc_bin/../.htoprc_env" ] && source "$rc_bin/../.htoprc_env"