# mkshrc – Android Shell Environment

`mkshrc` provides a more user-friendly shell environment on Android devices. It installs a minimal UNIX-like toolbox (BusyBox, OpenSSL, curl, Frida, supolicy) along with a shell RC script that improves usability.

## Features

* User-friendly shell interface with `mkshrc`
* Pre-packaged common tools (BusyBox, curl, OpenSSL, Frida, supolicy)
* Support for additional utilities (wget, nano, vim, htop, git, and more)
* Auto-symlinks for BusyBox applets
* Certificate injection helper (`update-ca-certificate`)
* Works on both rooted and non-rooted devices
* Extensible package system for adding custom binaries

## Included Binaries

### Core Binaries
| Binary       | Version                   | Notes                    |
|--------------|---------------------------|--------------------------|
| BusyBox      | 1.36.1.1                  | Full applet support      |
| OpenSSL      | 1.1.1l (NDK 23.0.7599858) | Built with Android NDK   |
| curl         | 7.78.0 (NDK 23.0.7599858) | With SSL support         |
| frida-server | 17.2.16, 16.7.9           | Choose version as needed |
| supolicy     | 2.82                      | SELinux policy helper    |

### Additional Utilities (Optional)
| Binary       | Notes                                    |
|--------------|------------------------------------------|
| wget         | HTTP/HTTPS/FTP download utility          |
| nano         | Simple text editor                       |
| vim          | Advanced text editor                     |
| htop         | Interactive process viewer               |
| git          | Version control system                   |
| rsync        | File synchronization utility             |
| tar          | Archive utility                          |
| unzip        | ZIP archive extractor                    |
| zip          | ZIP archive creator                      |
| grep         | Text search utility                      |
| sed          | Stream editor                            |
| awk          | Text processing tool                     |
| find         | File search utility                      |
| tree         | Directory tree viewer                    |
| tmux         | Terminal multiplexer                     |
| screen       | Terminal session manager                 |

*Note: Additional utilities require manual compilation for Android. See [ADDING_PACKAGES.md](guide/ADDING_PACKAGES.md) for build instructions.*

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

## Adding More Packages

The package system supports additional utilities beyond the core binaries. To add new packages:

1. **Compile for Android** using Android NDK (see [guide/ADDING_PACKAGES.md](guide/ADDING_PACKAGES.md))
2. **Place binaries** in the appropriate architecture directories under `package/`
3. **The installer** will automatically detect and install available binaries

Popular packages to consider adding:
- `wget` - Download files from web servers
- `nano`/`vim` - Text editors for configuration files
- `htop` - Monitor system processes and resources
- `git` - Version control for development work
- `rsync` - Efficient file synchronization
- `tmux`/`screen` - Terminal session management

See the [package directory README](package/README.md) for more details.

## Disclaimer

This project is intended for **educational and debugging purposes only**. Using these tools may modify your Android device. Proceed at your own risk.