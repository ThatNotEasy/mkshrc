# 🐚 MKSHRC
### Enhanced Android Shell Environment

[![Android](https://img.shields.io/badge/Platform-Android-green.svg)](https://android.com)
[![API](https://img.shields.io/badge/API-21%2B-brightgreen.svg)](https://android-arsenal.com/api?level=21)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

*Transform your Android shell experience with a powerful UNIX-like toolbox*

</div>

---

## 📋 Overview

**mkshrc** provides a comprehensive, user-friendly shell environment for Android devices. It delivers a minimal yet powerful UNIX-like toolbox featuring essential tools like BusyBox, OpenSSL, curl, Git, and Frida, all wrapped in an intelligent shell configuration that dramatically improves usability.

## ✨ Key Features

- 🔧 **Complete Toolbox** - Pre-compiled binaries for all major Android architectures
- 🚀 **Zero Dependencies** - Statically linked binaries work out-of-the-box
- 🔐 **Security Tools** - Includes Frida, OpenSSL, and certificate management
- 📱 **Universal Support** - Works on rooted and non-rooted devices
- ⚡ **Smart Aliases** - Intuitive shortcuts for common operations
- 🔄 **Auto-Detection** - Automatically configures based on device capabilities

## 📦 Included Tools

<table>
<tr>
<th>🛠️ Tool</th>
<th>📋 Version</th>
<th>📝 Description</th>
</tr>
<tr>
<td><strong>BusyBox</strong></td>
<td>1.36.1.1</td>
<td>Complete UNIX utilities suite with 300+ applets</td>
</tr>
<tr>
<td><strong>Git</strong></td>
<td>2.20.1</td>
<td>Version control with smart aliases and helpers</td>
</tr>
<tr>
<td><strong>OpenSSL</strong></td>
<td>1.1.1l</td>
<td>Cryptographic operations and SSL/TLS support</td>
</tr>
<tr>
<td><strong>curl</strong></td>
<td>7.78.0</td>
<td>HTTP/HTTPS client with full SSL support</td>
</tr>
<tr>
<td><strong>Frida</strong></td>
<td>17.2.16 / 16.7.9</td>
<td>Dynamic instrumentation and reverse engineering</td>
</tr>
<tr>
<td><strong>supolicy</strong></td>
<td>2.82</td>
<td>SELinux policy manipulation and management</td>
</tr>
</table>

## 🚀 Quick Start

### 1️⃣ Installation

<details>
<summary><strong>📱 Method 1: Using ADB (Recommended)</strong></summary>

```bash
# Push files to device
adb push package/ /data/local/tmp/package
adb push install.sh /data/local/tmp/mkshrc

# Or use the included batch script
install.bat

# Connect to device and install
adb shell
source /data/local/tmp/mkshrc
```

</details>

### 2️⃣ Activation

```bash
# Activate the enhanced shell environment
source /data/local/tmp/mkshrc.sh

# Or add to your shell profile for automatic loading
echo 'source /data/local/tmp/mkshrc.sh' >> ~/.bashrc
```

### 3️⃣ Device Compatibility

<div align="left">

| 🔐 Device Type | 🚀 Auto-Load | 🛠️ Functionality | 📝 Notes |
|----------------|---------------|-------------------|----------|
| **Rooted** | ✅ Automatic | 🟢 Full Access | Permanent installation |
| **Non-Rooted** | ❌ Manual | 🟡 Limited | Requires manual sourcing |

</div>

### 📜 Extra Utilities

- 🔐 **`update-ca-certificate <path>`** – Install custom CA certificates into Android system trust store
- 🔄 **`restart`** – Perform soft reboot of Android framework (requires root)
- 📁 **`pull <path>`** – Safely copy files from system to `/data/local/tmp/`
- 🔍 **`frida {start|status|stop|version}`** – Manage Frida server lifecycle
- 🔗 **BusyBox applets** – Automatically symlinked (except `man`)

## 🏗️ Architecture Support

<div align="left">

| 🏛️ Architecture | 📱 Target Devices | ✅ Status |
|-----------------|-------------------|-----------|
| **arm64-v8a** | Modern Android devices (64-bit ARM) | Fully Supported |
| **armeabi-v7a** | Older Android devices (32-bit ARM) | Fully Supported |
| **x86** | Android emulators (32-bit x86) | Fully Supported |
| **x86_64** | Android emulators (64-bit x86) | Fully Supported |

</div>

## 📁 Package Structure

```
📦 package/
├── 🏗️ arm64-v8a/              # 64-bit ARM (most modern devices)
│   ├── busybox/
│   ├── git/
│   ├── openssl/
│   └── curl/
├── 🏗️ armeabi-v7a/            # 32-bit ARM (older devices)
├── 🏗️ x86/                    # 32-bit x86 (emulators)
├── 🏗️ x86_64/                 # 64-bit x86 (emulators)
├── 📜 mkshrc.sh               # Main shell configuration
├── 📋 source.txt              # Source URLs for packages
└── 🔐 update-ca-certificate.sh # CA certificate updater
```

## 🔨 Adding New Packages

### 🛠️ Development Guidelines
- **[📦 Adding Packages](markdown/ADDING_PACKAGES.md)** - Complete guide for adding new tools
- **Android NDK Setup** - Cross-compilation environment
- **Static Linking** - Maximum compatibility across devices
- **API Level 21+** - Target Android 5.0 and above
- **Testing Procedures** - Validation on real devices
- **Binary Optimization** - Size reduction with `strip`

### 🔧 Available Packages
- **🔧 vim** - Advanced text editor with syntax highlighting
- **📊 htop** - Interactive process viewer and system monitor
- **📝 git** - Version control system with smart aliases and helpers

---

## ⚠️ Important Notes

<div align="left">

### 🎯 **Educational & Development Use Only**

This project is designed for **educational, debugging, and development purposes**.
Always test in safe environments and understand the implications of system modifications.

### 🔒 **Security Considerations**

- Review all binaries before deployment
- Understand root access implications
- Use appropriate security measures
- Keep tools updated for security patches

</div>

---

<div align="left">

### 🌟 **Contributing**

We welcome contributions! Please read our guidelines and submit pull requests.

### 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Made with ❤️ for the Android development community**

</div>