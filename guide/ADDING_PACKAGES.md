# Adding New Packages to mkshrc

This guide explains how to add new packages to the mkshrc Android shell environment.

## Package Structure

Each package follows this directory structure:
```
package/
├── arm64-v8a/
│   ├── busybox/
│   │   └── libbusybox.so
│   ├── curl/
│   │   └── curl
│   ├── newpackage/
│   │   └── newpackage
│   └── ...
├── armeabi-v7a/
├── x86/
├── x86_64/
├── mkshrc.sh
├── source.txt
└── update-ca-certificate.sh
```

## Supported Architectures

- `arm64-v8a` - 64-bit ARM (most modern Android devices)
- `armeabi-v7a` - 32-bit ARM (older Android devices)
- `x86` - 32-bit x86 (Android emulators)
- `x86_64` - 64-bit x86 (Android emulators, some tablets)

## Steps to Add a New Package

### 1. Create Package Directories

For each architecture, create a directory under `package/{arch}/`:
```bash
mkdir -p package/arm64-v8a/newpackage
mkdir -p package/armeabi-v7a/newpackage
mkdir -p package/x86/newpackage
mkdir -p package/x86_64/newpackage
```

### 2. Build or Obtain Binaries

You have several options:

#### Option A: Cross-compile from Source
Use the provided `build-packages.sh` script or Android NDK:
```bash
# Set up Android NDK environment
export ANDROID_NDK_HOME=/path/to/ndk
export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang

# Configure and build
./configure --host=aarch64-linux-android
make
```

#### Option B: Use Pre-built Binaries
- Download from official releases (if Android builds available)
- Use Termux packages as reference
- Extract from other Android distributions

#### Option C: Static Compilation
For maximum compatibility, compile statically:
```bash
export CFLAGS="-static -Os"
export LDFLAGS="-static"
```

### 3. Place Binaries

Copy the compiled binary to each architecture directory:
```bash
cp newpackage-arm64 package/arm64-v8a/newpackage/newpackage
cp newpackage-arm package/armeabi-v7a/newpackage/newpackage
cp newpackage-x86 package/x86/newpackage/newpackage
cp newpackage-x86_64 package/x86_64/newpackage/newpackage
```

### 4. Update install.sh

Add installation logic to `install.sh`:
```bash
# Add after line 78 (after other package installations)
[ -f "$rc_package/$CPU_ABI/newpackage/newpackage" ] && cp -f "$rc_package/$CPU_ABI/newpackage/newpackage" "$rc_bin/newpackage"
```

### 5. Update Documentation

Add the package to `README.md`:
```markdown
| newpackage   | 1.0.0                     | Description of package    |
```

Add source URL to `package/source.txt`:
```
# newpackage - Description
https://example.com/newpackage-1.0.0.tar.gz
```

### 6. Test Installation

Test the package installation:
```bash
# Deploy to device
./deploy.sh

# Connect to device and test
adb shell
source /data/local/tmp/mkshrc
newpackage --version
```

## Package Requirements

### Binary Requirements
- Must be compiled for Android (using Android NDK or compatible toolchain)
- Should be statically linked when possible for maximum compatibility
- Must target minimum API level 21 (Android 5.0)
- Should be stripped to reduce size: `strip newpackage`

### Size Considerations
- Keep binaries as small as possible
- Use compression if needed
- Consider using BusyBox applets for simple utilities

### Dependencies
- Avoid external dependencies when possible
- If dependencies are needed, include them in the package
- Document any system requirements

## Common Build Issues

### NDK Path Issues
```bash
export ANDROID_NDK_HOME=/path/to/android-ndk-r25c
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
```

### Cross-compilation Failures
- Use `--host` flag with configure scripts
- Set appropriate `CC`, `CXX`, `AR`, `STRIP` variables
- Add `-fPIE` and `-pie` flags for position-independent executables

### Runtime Issues
- Test on actual device, not just emulator
- Check for missing shared libraries with `ldd` (on host) or `readelf -d`
- Verify executable permissions are set correctly

## Example: Adding htop

Here's a complete example of adding htop:

1. **Create directories:**
```bash
for arch in arm64-v8a armeabi-v7a x86 x86_64; do
    mkdir -p package/$arch/htop
done
```

2. **Build for each architecture:**
```bash
# For arm64-v8a
export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android21-clang
./configure --host=aarch64-linux-android --disable-unicode
make
cp htop package/arm64-v8a/htop/htop
```

3. **Update install.sh:**
```bash
[ -f "$rc_package/$CPU_ABI/htop/htop" ] && cp -f "$rc_package/$CPU_ABI/htop/htop" "$rc_bin/htop"
```

4. **Update README.md:**
```markdown
| htop         | 3.2.2                     | Interactive process viewer |
```

5. **Test:**
```bash
./deploy.sh
adb shell "source /data/local/tmp/mkshrc && htop"
```

## Tips

- Start with simple packages (single binary, no dependencies)
- Use the build script as a template for automation
- Test on multiple device types and Android versions
- Consider using Termux as a reference for Android-compatible builds
- Keep backups of working binaries
- Document any special configuration or usage notes
