# Fenrir SDL

A game engine built with the Odin programming language and SDL.

## Dependencies

This project uses SDL3. The build script (`build.odin`) automatically locates and copies the necessary SDL3 runtime library (e.g., `SDL3.dll` on Windows) from your Odin installation's `vendor:sdl3` collection into the build output directory.

Ensure that you have the SDL3 library available within your Odin installation (this is often included by default or can be added via `odin install` or managing collections manually).

## Build System

### Configuration

The build system is configured in `build.odin` with the following constants that you may need to modify:

```odin
// Project configuration
PROJECT_ROOT :: "C:/Users/antwah/odin_project/fenrir-sdl"   // Update to your project path

// Odin configuration
ODIN_VENDOR_PATH :: "C:/Users/antwah/odin/vendor"          // Update to your Odin vendor path

// Build settings
DEBUG_EXE_NAME :: "fenrir_debug.exe"                       // Debug executable name
RELEASE_EXE_NAME :: "Fenrir.exe"                           // Release executable name
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