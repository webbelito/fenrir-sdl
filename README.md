# Fenrir SDL

A game engine built with the Odin programming language and SDL.

## Dependencies

### SDL3
This project uses SDL3. The build script (`build.odin`) automatically locates and copies the necessary SDL3 runtime library (e.g., `SDL3.dll` on Windows) from your Odin installation's `vendor:sdl3` collection into the build output directory.

Ensure that you have the SDL3 library available within your Odin installation (this is often included by default or can be added via `odin install` or managing collections manually).

### ImGui
This project uses [Dear ImGui](https://github.com/ocornut/imgui) for the user interface, specifically an Odin binding for ImGui with SDL3 and GPU renderer support. The build script expects to find the ImGui binding in your Odin shared directory at:

```
%ODIN_ROOT%/shared/imgui
```

If the ImGui dependency is not found, the build script will show an error message with installation instructions.

#### Installing ImGui for Odin

To install the required version of ImGui for this project:

```bash
# Navigate to your Odin shared directory
cd %ODIN_ROOT%/shared

# Clone the repository with the specific branch for SDL3 + GPU support
git clone https://gitlab.com/nadako/odin-imgui.git -b sdlgpu3 imgui
```

This will clone the specific branch (sdlgpu3) of the Odin-ImGui bindings that works with SDL3 and GPU rendering. The repository is maintained by Dan Korostelev and provides Odin bindings for the C++ Dear ImGui library.

#### Why this specific version?

This project requires the `sdlgpu3` branch because:
1. It supports SDL3 (the latest version of SDL)
2. It uses GPU-accelerated rendering
3. It has been updated to work with recent Odin language changes

The official repository URL is: https://gitlab.com/nadako/odin-imgui/-/tree/sdlgpu3?ref_type=heads

## Build System

### Configuration

The build system is configured in `build.odin` with the following constants that use environment variables or can be overridden at compile time:

```odin
// Project configuration
PROJECT_ROOT :: #config(PROJECT_ROOT, ".")  // Current directory by default

// Odin configuration
ODIN_VENDOR_PATH :: #config(ODIN_VENDOR_PATH, os.get_env("ODIN_ROOT", "C:/odin") + "/vendor")
ODIN_SHARED_PATH :: #config(ODIN_SHARED_PATH, os.get_env("ODIN_ROOT", "C:/odin") + "/shared")

// Build settings
DEBUG_EXE_NAME :: "fenrir_debug.exe"        // Debug executable name
RELEASE_EXE_NAME :: "Fenrir.exe"            // Release executable name
```

You can configure the paths in several ways:

1. **Set the ODIN_ROOT environment variable**:
   ```
   # Windows
   set ODIN_ROOT=C:/path/to/odin
   
   # Linux/macOS
   export ODIN_ROOT=/path/to/odin
   ```

2. **Pass configuration values at compile time**:
   ```
   odin run build.odin -file -define:PROJECT_ROOT="C:/your/project/path" -define:ODIN_VENDOR_PATH="C:/custom/path/to/vendor"
   ```

3. **Edit the values in build.odin directly** if the automatic configuration doesn't work for your setup.

### Build Modes

#### Debug Build
The debug build (`odin run build.odin -file`) does the following:
- Compiles the project with debug symbols and optimization disabled
- Creates the executable in the project root directory
- Copies SDL3.dll to the project root directory
- Maintains the source directory structure for easy debugging

#### Release Build
The release build (`odin run build.odin -file -- release`) does the following:
- Compiles the project with speed optimizations enabled
- Creates a distributable `bin/release` directory containing:
  - The optimized executable (`Fenrir.exe`)
  - All necessary dependencies (SDL3.dll)
  - Complete assets directory structure
  - A README.txt file with basic information for end-users
- The release package can be copied to any location and will run standalone

## Getting Started

Clone the repository and run the build script:

```bash
# Build for debug (Default)
odin run build.odin -file

# Build for release
odin run build.odin -file -- release
```

### VS Code Integration

This project includes VS Code tasks for building and running:

- **Build (Debug)**: Compile in debug mode
- **Build (Release)**: Compile in release mode 
- **Build & Run (Debug)**: Compile and run the debug version
- **Build & Run (Release)**: Compile and run the release version
- **Clean Project**: Remove all build outputs

## Usage

*(Instructions on how to use the engine will go here)*

## Project Structure

```
fenrir-sdl/
├── assets/             # Game assets
│   ├── meshes/         # 3D models
│   ├── scenes/         # Scene definitions
│   ├── shaders/        # Shader files
│   │   ├── bin/        # Compiled shaders
│   │   └── src/        # Shader source code
│   └── textures/       # Image files
├── bin/
│   └── release/        # Release build output
├── src/                # Source code
├── build.odin          # Build system
└── README.md           # This file
```

## Contributing

*(Information about how others can contribute to the project)*

## License

*(Specify the license for your project here, e.g., MIT)* 