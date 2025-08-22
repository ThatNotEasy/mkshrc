# mkshrc – Android Shell Environment

`mkshrc` provides a more user-friendly shell environment on Android devices. It installs a minimal UNIX-like toolbox (BusyBox, OpenSSL, curl, Frida, supolicy) along with a shell RC script that improves usability.

## Features

* User-friendly shell interface with `mkshrc`
* Pre-packaged common tools (BusyBox, curl, OpenSSL, Frida, supolicy)
* Auto-symlinks for BusyBox applets
* Certificate injection helper (`update-ca-certificate`)
* Works on both rooted and non-rooted devices

## Included Binaries

| Binary       | Version                   | Notes                    |
|--------------|---------------------------|--------------------------|
| BusyBox      | 1.36.1.1                  | Full applet support      |
| OpenSSL      | 1.1.1l (NDK 23.0.7599858) | Built with Android NDK   |
| curl         | 7.78.0 (NDK 23.0.7599858) | With SSL support         |
| frida-server | 17.2.16, 16.7.9           | Choose version as needed |
| supolicy     | 2.82                      | SELinux policy helper    |

## Installation

1. Push the installer package to your device:

   ```bat
   adb push package/ /data/local/tmp/package
   adb push install.sh /data/local/tmp/mkshrc
   ```

   or use the included `install.bat`.

2. Open a shell on your device:

   ```sh
   adb shell
   ```

3. Run the installer:

   ```sh
   source /data/local/tmp/mkshrc
   ```

## Usage

When you open an `adb shell`, you must source the environment:

```sh
source /data/local/tmp/mkshrc
```

* **If the device is rooted**:
  The script mounts itself permanently, so future shells automatically include it.

* **If the device is not rooted**:
  You must manually `source /data/local/tmp/mkshrc` in each new shell session.

## Extra Utilities

* `update-ca-certificate <path>` – install custom CA certificates into the Android system trust store.
* `restart` – perform a **soft reboot** of the Android framework (required root).
* `pull <path>` – safely copy a file from the system into `/data/local/tmp/`.
* `frida {start|status|stop|version}` – manage the Frida server lifecycle.
* BusyBox applets are symlinked automatically (except `man`).

# Package Directory

This directory contains pre-compiled binaries for different Android architectures.

## Directory Structure

```
package/
├── arm64-v8a/          # 64-bit ARM (most modern Android devices)
├── armeabi-v7a/        # 32-bit ARM (older Android devices)  
├── x86/                # 32-bit x86 (Android emulators)
├── x86_64/             # 64-bit x86 (Android emulators, some tablets)
├── mkshrc.sh           # Main shell configuration script
├── source.txt          # Source URLs for all packages
└── update-ca-certificate.sh  # CA certificate update script
```

## Adding Binaries

To add a binary for a package (e.g., wget):

1. **Compile the binary** for Android using Android NDK
2. **Place the binary** in the appropriate architecture directory:
   ```
   package/arm64-v8a/wget/wget
   package/armeabi-v7a/wget/wget
   package/x86/wget/wget
   package/x86_64/wget/wget
   ```
3. **The install.sh script** will automatically detect and install available binaries

## Current Packages

### Core Packages (Included)
- **busybox** - Multi-call binary with many UNIX utilities
- **curl** - HTTP/HTTPS client with SSL support
- **openssl** - SSL/TLS toolkit
- **frida-server** - Dynamic instrumentation toolkit
- **supolicy** - SELinux policy manipulation tool

### Additional Packages (Directories Created)
- **wget** - HTTP/HTTPS/FTP download utility
- **nano** - Simple text editor
- **vim** - Advanced text editor
- **htop** - Interactive process viewer
- **git** - Version control system
- **rsync** - File synchronization utility
- **tar** - Archive utility
- **unzip/zip** - ZIP archive utilities
- **grep/sed/awk** - Text processing utilities
- **find** - File search utility
- **tree** - Directory tree viewer
- **tmux/screen** - Terminal multiplexers

## Build Instructions

See [guide/ADDING_PACKAGES.md](guide/ADDING_PACKAGES.md) for detailed instructions on:
- Setting up Android NDK
- Cross-compiling packages
- Static linking for maximum compatibility
- Testing on Android devices

## Notes

- Binaries must be compiled for Android using Android NDK
- Static linking is recommended for maximum compatibility
- All binaries should target minimum API level 21 (Android 5.0)
- Test on actual devices, not just emulators
- Strip binaries to reduce size: `strip binary_name`

## Disclaimer

This project is intended for **educational and debugging purposes only**. Using these tools may modify your Android device. Proceed at your own risk.