#+feature dynamic-literals
package build

import "core:log"
import "core:strings"
import "core:slice"
import "core:path/filepath"
import os "core:os/os2"
import "core:fmt"
import "core:io"

// Project configuration
PROJECT_ROOT :: #config(PROJECT_ROOT, ".")

// Odin configuration
ODIN_VENDOR_PATH :: #config(ODIN_VENDOR_PATH, "C:/Users/antwah/odin/vendor")
ODIN_SHARED_PATH :: #config(ODIN_SHARED_PATH, "C:/Users/antwah/odin/shared")

// Tool paths
SHADERCROSS_PATH :: #config(SHADERCROSS_PATH, "C:/Users/antwah/shadercross")

// Build settings
DEBUG_EXE_NAME :: "fenrir_debug.exe"
RELEASE_EXE_NAME :: "Fenrir.exe"

// Dependency URLs
IMGUI_REPO_URL :: "https://gitlab.com/nadako/odin-imgui/-/tree/sdlgpu3?ref_type=heads"
IMGUI_CLONE_CMD :: "git clone https://gitlab.com/nadako/odin-imgui.git -b sdlgpu3 imgui"
SHADERCROSS_REPO_URL :: "https://github.com/libsdl-org/SDL_shadercross"
SHADERCROSS_ACTIONS_URL :: "https://github.com/libsdl-org/SDL_shadercross/actions"

// Shader types
SHADER_TYPE_VERTEX :: "vertex"
SHADER_TYPE_FRAGMENT :: "fragment"

// Target formats
SHADER_FORMAT_SPIRV :: "SPIRV"
SHADER_FORMAT_METAL :: "MSL"
SHADER_FORMAT_DXIL :: "DXIL"

validate_config :: proc() -> bool {
	// Validate project root
	if !os.exists(PROJECT_ROOT) {
		log.errorf("Project root '%s' does not exist. Please update the build.odin file.", PROJECT_ROOT)
		return false
	}
	
	// Validate SDL path
	sdl_path := filepath.join({ODIN_VENDOR_PATH, "sdl3/SDL3.dll"})
	if !os.exists(sdl_path) {
		log.errorf("SDL3.dll not found at '%s'. Please update the ODIN_VENDOR_PATH in build.odin.", sdl_path)
		return false
	}
	
	// Validate ImGui
	imgui_path := filepath.join({ODIN_SHARED_PATH, "imgui"})
	if !os.exists(imgui_path) {
		log.errorf("ImGui not found at '%s'.", imgui_path)
		log.errorf("Please install ImGui using the following command:")
		log.errorf("cd %s && %s", ODIN_SHARED_PATH, IMGUI_CLONE_CMD)
		log.errorf("Repository URL: %s", IMGUI_REPO_URL)
		return false
	}
	
	// Validate ShaderCross
	shadercross_exe := filepath.join({SHADERCROSS_PATH, "bin/shadercross.exe"})
	if !os.exists(shadercross_exe) {
		log.errorf("shadercross.exe not found at '%s'.", shadercross_exe)
		log.errorf("Please download SDL_shadercross from GitHub Actions:")
		log.errorf("1. Visit %s", SHADERCROSS_ACTIONS_URL)
		log.errorf("2. Find a successful workflow run")
		log.errorf("3. Download the appropriate artifact for your platform")
		log.errorf("4. Extract to '%s' and ensure the binary is in the 'bin' subdirectory", SHADERCROSS_PATH)
		log.errorf("Example: set SHADERCROSS_PATH=C:/shadercross")
		return false
	}
	
	return true
}

compile_shaders :: proc(project_root: string) -> bool {
	log.info("Compiling shaders...")
	
	// Root shader directories
	shader_src_root := filepath.join({project_root, "assets/shaders/src"})
	shader_bin_root := filepath.join({project_root, "assets/shaders/bin"})
	
	// Create specific directories for game and editor
	game_src_dir := filepath.join({shader_src_root, "game"})
	game_bin_dir := filepath.join({shader_bin_root, "game"})
	editor_src_dir := filepath.join({shader_src_root, "editor"})
	editor_bin_dir := filepath.join({shader_bin_root, "editor"})
	
	// Ensure directories exist
	os.make_directory_all(game_src_dir)
	os.make_directory_all(game_bin_dir)
	
	// Only create editor directories in debug mode
	is_debug := #defined(ODIN_DEBUG)
	if is_debug {
		os.make_directory_all(editor_src_dir)
		os.make_directory_all(editor_bin_dir)
	}
	
	shadercross_exe := filepath.join({SHADERCROSS_PATH, "bin/shadercross.exe"})
	if !os.exists(shadercross_exe) {
		log.errorf("shadercross.exe not found at '%s'. Shader compilation skipped.", shadercross_exe)
		return true // Continue with the build
	}
	
	compilation_success := true
	
	// Formats and extensions
	formats := []string{SHADER_FORMAT_SPIRV, SHADER_FORMAT_METAL, SHADER_FORMAT_DXIL}
	file_exts := []string{"spv", "metal", "dxil"}
	
	// Compile game shaders (always)
	log.info("Compiling game shaders...")
	
	if !compile_shaders_in_directory(game_src_dir, game_bin_dir, formats, file_exts, shadercross_exe) {
		compilation_success = false
	}
	
	// Compile editor shaders (only in debug mode)
	if is_debug {
		log.info("Compiling editor shaders...")
		
		if !compile_shaders_in_directory(editor_src_dir, editor_bin_dir, formats, file_exts, shadercross_exe) {
			compilation_success = false
		}
	}
	
	if compilation_success {
		log.info("Shader compilation completed successfully.")
	} else {
		log.error("Some shader compilations failed.")
	}
	
	return true
}

// Helper function to compile shaders in a specific directory
compile_shaders_in_directory :: proc(src_dir: string, bin_dir: string, 
                                   formats: []string, file_exts: []string, 
                                   shadercross_exe: string) -> bool {
	// Check if the source directory exists
	if !os.exists(src_dir) {
		log.warnf("Shader source directory '%s' not found.", src_dir)
		return true // No shaders to compile
	}
	
	// Ensure the bin directory exists
	if !os.exists(bin_dir) {
		os.make_directory_all(bin_dir)
	}
	
	// Read shader files
	files, err := os.read_all_directory_by_path(src_dir, context.allocator)
	if err != nil {
		log.errorf("Failed to read shader directory: %v", err)
		return false
	}
	defer delete(files)
	
	compilation_success := true
	
	for file in files {
		// Skip directories and special entries
		if file.name == "." || file.name == ".." {
			continue
		}
		
		file_name := file.name
		log.infof("Found shader file: %s", file_name)
		
		// Parse filename parts
		parts := strings.split(file_name, ".")
		defer delete(parts)
		
		if len(parts) < 3 {
			log.warnf("Skipping file with invalid naming format: %s", file_name)
			continue
		}
		
		// Extract shader type from extension
		shader_type_str := parts[len(parts)-1]
		shader_type: string
		
		switch shader_type_str {
		case "vert":
			shader_type = SHADER_TYPE_VERTEX
		case "frag":
			shader_type = SHADER_TYPE_FRAGMENT
		case:
			log.warnf("Unknown shader type: %s in file %s", shader_type_str, file_name)
			continue
		}
		
		// Extract shader name (everything before last two extensions)
		shader_name: string
		if len(parts) > 2 {
			shader_name = strings.join(parts[:len(parts)-2], ".")
		} else {
			shader_name = parts[0]
		}
		
		// Compile for each target format
		for format, i in formats {
			file_ext := file_exts[i]
			
			// Output name follows pattern: name.format.type (e.g., basic.spv.vert)
			output_name := fmt.tprintf("%s.%s.%s", shader_name, file_ext, shader_type_str)
			output_path := filepath.join({bin_dir, output_name})
			
			log.infof("Compiling to %s: %s", format, output_name)
			
			// Build and run shadercross command
			shader_command := []string{
				shadercross_exe,
				file.fullpath,
				"--source", "HLSL",
				"--dest", format,
				"--stage", shader_type,
				"--entrypoint", "main",
				"--output", output_path,
			}
			
			shader_process, process_err := os.process_start({
				command = shader_command,
				stdin = os.stdin,
				stdout = os.stdout,
				stderr = os.stderr,
			})
			
			if process_err != nil {
				log.errorf("Failed to start shader compilation: %v", process_err)
				compilation_success = false
				continue
			}
			
			shader_state, wait_err := os.process_wait(shader_process)
			if wait_err != nil {
				log.errorf("Failed to wait for shader compilation: %v", wait_err)
				compilation_success = false
			}
			
			close_err := os.process_close(shader_process)
			if close_err != nil {
				log.errorf("Failed to close shader compilation process: %v", close_err)
			}
			
			if shader_state.exit_code != 0 {
				log.errorf("Shader compilation failed for %s to %s", file_name, format)
				// Allow MSL errors - these are expected for some shaders
				if format != SHADER_FORMAT_METAL {
					compilation_success = false
				}
			}
		}
	}
	
	return compilation_success
}

build_debug :: proc() -> (success: bool) {
	project_root := PROJECT_ROOT
	
	// Create directories
	log.info("Creating directory structure...")
	os.make_directory_all(filepath.join({project_root, "assets/meshes"}))
	os.make_directory_all(filepath.join({project_root, "assets/scenes"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/src/game"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/src/editor"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/bin/game"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/bin/editor"}))
	os.make_directory_all(filepath.join({project_root, "assets/textures"}))
	os.make_directory_all(filepath.join({project_root, "src/game"}))
	os.make_directory_all(filepath.join({project_root, "src/editor"}))
	os.make_directory_all(filepath.join({project_root, "bin/release"}))
	
	// Compile shaders
	if !compile_shaders(project_root) {
		log.error("Shader compilation failed. Build aborted.")
		return false
	}
	
	// Build in debug mode
	output_path := filepath.join({project_root, DEBUG_EXE_NAME})
	
	// Build with debug flag - this automatically defines ODIN_DEBUG
	build_flags := []string{"-debug"}
	
	// Source directory
	src_dir := filepath.join({project_root, "src"})
	
	log.info("Building project in debug mode with editor...")
	log.infof("Source directory: %s", src_dir)
	log.infof("Output path: %s", output_path)
	
	// Create full command with all build flags
	command := make([dynamic]string)
	append(&command, "odin")
	append(&command, "build")
	append(&command, src_dir)
	for flag in build_flags {
		append(&command, flag)
	}
	append(&command, fmt.tprintf("-out:%s", output_path))
	
	// Run the build command
	build_process, process_err := os.process_start({
		command = slice.clone(command[:]), // Convert dynamic array to slice
		stdin = os.stdin,
		stdout = os.stdout,
		stderr = os.stderr,
	})
	
	if process_err != nil {
		log.errorf("Failed to start build process: %v", process_err)
		return false
	}
	
	build_state, wait_err := os.process_wait(build_process)
	if wait_err != nil {
		log.errorf("Failed to wait for build process: %v", wait_err)
		return false
	}
	
	close_err := os.process_close(build_process)
	if close_err != nil {
		log.errorf("Failed to close build process: %v", close_err)
		return false
	}
	
	if build_state.exit_code != 0 {
		log.error("Build failed")
		return false
	}
	
	// Copy SDL3.dll
	log.info("Copying SDL3.dll...")
	sdl_path := filepath.join({ODIN_VENDOR_PATH, "sdl3/SDL3.dll"})
	dest_path := filepath.join({project_root, "SDL3.dll"})
	log.infof("SDL source path: %s", sdl_path)
	log.infof("SDL destination path: %s", dest_path)
	
	if !os.exists(sdl_path) {
		log.errorf("SDL3.dll not found at '%s'", sdl_path)
		return false
	} else {
		data, read_err := os.read_entire_file_from_path(sdl_path, context.allocator)
		defer delete(data)
		if read_err != nil {
			log.errorf("Failed to read SDL3.dll: %v", read_err)
			return false
		} else {
			write_err := os.write_entire_file(dest_path, data)
			if write_err != nil {
				log.errorf("Failed to write SDL3.dll: %v", write_err)
				return false
			} else {
				log.info("Successfully copied SDL3.dll")
			}
		}
	}
	
	log.info("Debug build complete!")
	return true
}

build_release :: proc() -> (success: bool) {
	project_root := PROJECT_ROOT
	
	// Create directories
	log.info("Creating directory structure...")
	os.make_directory_all(filepath.join({project_root, "assets/meshes"}))
	os.make_directory_all(filepath.join({project_root, "assets/scenes"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/src/game"}))
	// No editor folder needed for release
	os.make_directory_all(filepath.join({project_root, "assets/shaders/bin/game"}))
	// No editor shader output needed for release
	os.make_directory_all(filepath.join({project_root, "assets/textures"}))
	os.make_directory_all(filepath.join({project_root, "src/game"}))
	os.make_directory_all(filepath.join({project_root, "src/editor"}))  // Still needed for compilation
	os.make_directory_all(filepath.join({project_root, "bin/release"}))
	
	// Compile shaders (editor shaders won't be compiled in release mode)
	if !compile_shaders(project_root) {
		log.error("Shader compilation failed. Build aborted.")
		return false
	}
	
	// Build in release mode
	release_dir := filepath.join({project_root, "bin/release"})
	output_path := filepath.join({release_dir, RELEASE_EXE_NAME})
	
	// Build with optimization flag, but no debug flag and no ODIN_DEBUG define
	build_flags := []string{"-o:speed"}
	
	src_dir := filepath.join({project_root, "src"})
	
	log.info("Building project in release mode (no editor)...")
	log.infof("Source directory: %s", src_dir)
	log.infof("Output path: %s", output_path)
	
	// Create full command with all build flags
	command := make([dynamic]string)
	append(&command, "odin")
	append(&command, "build")
	append(&command, src_dir)
	for flag in build_flags {
		append(&command, flag)
	}
	append(&command, fmt.tprintf("-out:%s", output_path))
	
	// Run the build command
	build_process, process_err := os.process_start({
		command = slice.clone(command[:]), // Convert dynamic array to slice
		stdin = os.stdin,
		stdout = os.stdout,
		stderr = os.stderr,
	})
	
	if process_err != nil {
		log.errorf("Failed to start build process: %v", process_err)
		return false
	}
	
	build_state, wait_err := os.process_wait(build_process)
	if wait_err != nil {
		log.errorf("Failed to wait for build process: %v", wait_err)
		return false
	}
	
	close_err := os.process_close(build_process)
	if close_err != nil {
		log.errorf("Failed to close build process: %v", close_err)
		return false
	}
	
	if build_state.exit_code != 0 {
		log.error("Build failed")
		return false
	}
	
	// Copy SDL3.dll
	log.info("Copying SDL3.dll...")
	sdl_path := filepath.join({ODIN_VENDOR_PATH, "sdl3/SDL3.dll"})
	dest_path := filepath.join({release_dir, "SDL3.dll"})
	log.infof("SDL source path: %s", sdl_path)
	log.infof("SDL destination path: %s", dest_path)
	
	if !os.exists(sdl_path) {
		log.errorf("SDL3.dll not found at '%s'", sdl_path)
		return false
	} else {
		data, read_err := os.read_entire_file_from_path(sdl_path, context.allocator)
		defer delete(data)
		if read_err != nil {
			log.errorf("Failed to read SDL3.dll: %v", read_err)
			return false
		} else {
			write_err := os.write_entire_file(dest_path, data)
			if write_err != nil {
				log.errorf("Failed to write SDL3.dll: %v", write_err)
				return false
			} else {
				log.info("Successfully copied SDL3.dll")
			}
		}
	}
	
	// Copy assets directory (no editor assets in release)
	assets_dir := filepath.join({project_root, "assets"})
	if os.exists(assets_dir) && os.is_dir(assets_dir) {
		log.info("Copying game assets...")
		dest_assets_dir := filepath.join({release_dir, "assets"})
		
		// Create the destination assets directory
		if !os.exists(dest_assets_dir) {
			os.make_directory(dest_assets_dir)
		}
		
		// Copy all assets except editor content
		os.make_directory_all(filepath.join({dest_assets_dir, "meshes"}))
		os.make_directory_all(filepath.join({dest_assets_dir, "scenes"}))
		os.make_directory_all(filepath.join({dest_assets_dir, "shaders/bin/game"}))
		os.make_directory_all(filepath.join({dest_assets_dir, "textures"}))
		
		// Copy meshes directory
		meshes_src := filepath.join({assets_dir, "meshes"})
		meshes_dst := filepath.join({dest_assets_dir, "meshes"})
		copy_directory(meshes_src, meshes_dst)
		
		// Copy scenes directory
		scenes_src := filepath.join({assets_dir, "scenes"})
		scenes_dst := filepath.join({dest_assets_dir, "scenes"})
		copy_directory(scenes_src, scenes_dst)
		
		// Copy game shaders bin directory
		shaders_src := filepath.join({assets_dir, "shaders/bin/game"})
		shaders_dst := filepath.join({dest_assets_dir, "shaders/bin/game"})
		copy_directory(shaders_src, shaders_dst)
		
		// Copy textures directory
		textures_src := filepath.join({assets_dir, "textures"})
		textures_dst := filepath.join({dest_assets_dir, "textures"})
		copy_directory(textures_src, textures_dst)
		
		log.info("Assets copied successfully")
	} else {
		log.warnf("Assets directory not found at '%s', skipping copy", assets_dir)
	}
	
	// Create README.txt
	log.info("Creating README.txt...")
	readme := `Fenrir SDL Game Engine
====================

A simple game engine built with Odin and SDL3.

How to Run:
-----------
Simply double-click on Fenrir.exe to run the application.

Controls:
---------
(Add your controls here)

Credits:
--------
Created with Odin (https://odin-lang.org/) and SDL3 (https://www.libsdl.org/)
`
	
	readme_path := filepath.join({release_dir, "README.txt"})
	write_err := os.write_entire_file(readme_path, transmute([]byte)readme)
	if write_err != nil {
		log.errorf("Failed to create README.txt: %v", write_err)
		return false
	}
	
	log.info("Release build complete!")
	log.info("The release package is ready in the 'bin/release' directory.")
	log.info("You can copy this folder and run it from anywhere.")
	return true
}

// Helper to copy a directory
copy_directory :: proc(src, dst: string) {
	if !os.exists(src) {
		log.warnf("Source directory '%s' does not exist", src)
		return
	}
	
	if !os.exists(dst) {
		os.make_directory_all(dst)
	}
	
	// Use robocopy on Windows for efficient directory copying
	copy_cmd := []string{
		"robocopy", 
		src, 
		dst, 
		"/E", // Copy subdirectories including empty ones
		"/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS" // Reduce output verbosity
	}
	
	log.infof("Copying from %s to %s", src, dst)
	
	process, err := os.process_start({
		command = copy_cmd,
		stdin = os.stdin,
		stdout = os.stdout,
		stderr = os.stderr,
	})
	
	if err != nil {
		log.errorf("Failed to start copy process: %v", err)
		return
	}
	
	state, wait_err := os.process_wait(process)
	if wait_err != nil {
		log.errorf("Failed to wait for copy process: %v", wait_err)
	}
	
	close_err := os.process_close(process)
	if close_err != nil {
		log.errorf("Failed to close copy process: %v", close_err)
	}
	
	// Robocopy return codes: 0-7 are successful, >8 indicates errors
	if state.exit_code > 8 {
		log.errorf("Copy failed with exit code: %d", state.exit_code)
	}
}

main :: proc() {
	// Setup logging
	context.logger = log.create_console_logger()
	
	// Check platform
	if ODIN_OS != .Windows {
		log.error("This build script only supports Windows.")
		os.exit(1)
	}
	
	// Validate configuration
	log.info("Validating configuration...")
	if !validate_config() {
		log.error("Configuration validation failed. Please check the build.odin file.")
		os.exit(1)
	}
	
	// Default to debug build
	build_type := "debug"
	
	// Check command line args
	for i := 1; i < len(os.args); i += 1 {
		if os.args[i] == "release" {
			build_type = "release"
			break
		}
	}
	
	log.infof("Build type: %s", build_type)
	
	// Run the appropriate build
	build_success := false
	if build_type == "debug" {
		build_success = build_debug()
	} else {
		build_success = build_release()
	}
	
	// Exit with appropriate status code
	if !build_success {
		log.error("Build process failed. See errors above.")
		os.exit(1)
	}
	
	log.info("Build process completed successfully.")
} 