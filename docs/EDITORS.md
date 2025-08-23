# Text Editors Package

This package includes cross-compiled static binaries of nano and vim text editors for all Android architectures.

## Included Editors

### Nano (v7.2)
- **Description**: Simple, user-friendly text editor
- **Features**: Syntax highlighting, search/replace, spell checking
- **Usage**: `nano [filename]`
- **Architectures**: arm64-v8a, armeabi-v7a, x86, x86_64

### Vim (v9.1.0143)
- **Description**: Advanced modal text editor
- **Features**: Powerful editing capabilities, scripting, plugins
- **Usage**: `vim [filename]`
- **Tutorial**: `vimtutor` (interactive vim tutorial)
- **Architectures**: arm64-v8a, armeabi-v7a, x86, x86_64

## Installation

The binaries are automatically installed to `$rc_bin` (typically `/data/local/tmp/bin`) when the mkshrc script runs. They will be available in your PATH.

### Package Structure
```
package/<architecture>/
├── nano/
│   └── nano
└── vim/
    ├── vim
    ├── vimtutor
    ├── vimrc_basic
    └── vim_config/
        └── usr/share/vim/vim91/
            ├── defaults.vim
            ├── syntax/
            ├── autoload/
            └── ... (complete vim runtime)
```

## Basic Usage

### Nano
```bash
# Edit a file
nano myfile.txt

# Common shortcuts:
# Ctrl+O - Save file
# Ctrl+X - Exit
# Ctrl+W - Search
# Ctrl+\ - Replace
```

### Vim
```bash
# Edit a file
vim myfile.txt

# Basic vim commands:
# i - Enter insert mode
# Esc - Exit insert mode
# :w - Save file
# :q - Quit
# :wq - Save and quit
# :q! - Quit without saving

# Learn vim interactively
vimtutor
```

## Source

These binaries are sourced from the excellent [Cross-Compiled-Binaries-Android](https://github.com/Zackptg5/Cross-Compiled-Binaries-Android) project by Zackptg5, which provides high-quality static binaries for Android.

## Notes

- All binaries are statically linked and should work without additional dependencies
- The binaries are compiled with Android NDK for maximum compatibility
- Both editors support syntax highlighting and basic configuration
- Vim includes the vimtutor for learning vim commands
- Vim configuration files are automatically installed to prevent E1187 "Failed to source defaults.vim" error
- A basic .vimrc file is provided with sensible defaults for Android environment
- VIM and VIMRUNTIME environment variables are automatically set for proper operation
