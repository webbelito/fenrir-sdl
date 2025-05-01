# Fenrir SDL

A game engine built with the Odin programming language and SDL.

## Dependencies

### SDL3
This project uses SDL3. The build script (`build.odin`) automatically locates and copies the necessary SDL3 runtime library (e.g., `SDL3.dll` on Windows) from your Odin installation's `vendor:sdl3` collection into the build output directory.

Ensure that you have the SDL3 library available within your Odin installation (this is often included by default or can be added via `odin install` or managing collections manually).

### ImGui
This project uses [Dear ImGui](https://github.com/ocornut/imgui) for the user interface, specifically an Odin binding for ImGui with SDL3 and GPU renderer support. The build script expects to find the ImGui binding in your Odin shared directory at:

```
C:/Users/antwah/odin/shared/imgui
```

If the ImGui dependency is not found, the build script will show an error message with installation instructions.

#### Installing ImGui for Odin

To install the required version of ImGui for this project:

```bash
# Navigate to your Odin shared directory
cd C:/Users/antwah/odin/shared

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

### SDL_shadercross
This project uses [SDL_shadercross](https://github.com/libsdl-org/SDL_shadercross) for cross-compiling shaders to various formats. It's a fork of ShaderCross maintained by the SDL team. The build script expects to find SDL_shadercross installed externally to the project at:

```
C:/Users/antwah/shadercross
```

With the ShaderCross executable located in the bin subdirectory:

```
C:/Users/antwah/shadercross/bin/ShaderCross.exe
```

#### Installing SDL_shadercross

Instead of building from source, you can download pre-built binaries directly from GitHub Actions:

1. Visit the [SDL_shadercross Actions page](https://github.com/libsdl-org/SDL_shadercross/actions)
2. Click on a successful workflow run (look for green checkmarks)
3. Scroll down to the "Artifacts" section 
4. Download the appropriate artifact for your platform:
   - `SDL3_shadercross-VC-x64` - Windows (Visual C++)
   - `SDL3_shadercross-mingw64` - Windows (MinGW64)
   - `SDL3_shadercross-linux-x64` - Linux
   - `SDL3_shadercross-macos-arm64` - macOS (Apple Silicon)
   - `SDL3_shadercross-slrsniper` - Steam Linux Runtime
5. Extract the downloaded zip to `C:/Users/antwah/shadercross`
6. Ensure that the ShaderCross executable is present in the `bin` subdirectory (e.g., `C:/Users/antwah/shadercross/bin/ShaderCross.exe`)

You can override these hardcoded paths at compile time:

```
odin run build.odin -file -define:SHADERCROSS_PATH="C:/your/custom/path/to/shadercross"
```

## Shader Compilation

The build system automatically compiles shaders from HLSL to multiple target formats during both debug and release builds.

### Shader Organization

Shaders should be organized as follows:

- **Source Shaders**: Place your HLSL shaders in `assets/shaders/src/`
- **Compiled Shaders**: Compiled shaders are output to `assets/shaders/bin/`

### Shader Naming Convention

Shader files should follow this naming convention:

```
<name>.hlsl.<type>
```

Where:
- `<name>` is the base name of your shader (e.g., "opaque", "skybox")
- `<type>` is the shader type: "vert" for vertex shaders, "frag" for fragment shaders

Examples:
```
opaque.hlsl.vert  - Vertex shader
opaque.hlsl.frag  - Fragment shader 
skybox.hlsl.vert  - Vertex shader
skybox.hlsl.frag  - Fragment shader
```

### Compilation Process

The build system will:

1. Scan the `assets/shaders/src/` directory for HLSL shaders
2. For each shader, compile to three target formats:
   - SPIRV (Vulkan) - `.spv` extension
   - Metal (Apple) - `.metal` extension
   - DXIL (DirectX) - `.dxil` extension

### Output Format

Compiled shaders follow this naming convention:

```
<name>.<type>.<format>
```

For example, `opaque.hlsl.vert` will be compiled to:
```
opaque.vert.spv    - SPIRV version
opaque.vert.metal  - Metal version
opaque.vert.dxil   - DXIL version
```

## Build System

### Configuration

The build system is configured in `build.odin` with the following constants that can be overridden at compile time:

```odin
// Project configuration
PROJECT_ROOT :: #config(PROJECT_ROOT, ".")  // Current directory by default

// Odin configuration
ODIN_VENDOR_PATH :: #config(ODIN_VENDOR_PATH, "C:/Users/antwah/odin/vendor")
ODIN_SHARED_PATH :: #config(ODIN_SHARED_PATH, "C:/Users/antwah/odin/shared")

// Tool paths
SHADERCROSS_PATH :: #config(SHADERCROSS_PATH, "C:/Users/antwah/shadercross")

// Build settings
DEBUG_EXE_NAME :: "fenrir_debug.exe"        // Debug executable name
RELEASE_EXE_NAME :: "Fenrir.exe"            // Release executable name
```

If you need to use different paths, you can:

1. **Edit the paths in build.odin directly** to match your environment

2. **Override at compile time**:
   ```
   odin run build.odin -file -define:ODIN_VENDOR_PATH="C:/your/odin/vendor" -define:SHADERCROSS_PATH="C:/your/shadercross"
   ```

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