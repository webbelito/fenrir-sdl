#+feature dynamic-literals
package main

import "core:log"
import "core:strings"
import "core:slice"
import "core:path/filepath"
import os "core:os/os2"
import "core:fmt"
import "core:io"

// Project configuration
PROJECT_ROOT :: "C:/Users/antwah/odin_project/fenrir-sdl"

// Odin configuration
ODIN_VENDOR_PATH :: "C:/Users/antwah/odin/vendor"

// Build settings
DEBUG_EXE_NAME :: "fenrir_debug.exe"
RELEASE_EXE_NAME :: "Fenrir.exe"

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
	
	return true
}

build_debug :: proc() {
	// Get paths from config
	project_root := PROJECT_ROOT
	
	// Create directories
	log.info("Creating directory structure...")
	os.make_directory_all(filepath.join({project_root, "assets/meshes"}))
	os.make_directory_all(filepath.join({project_root, "assets/scenes"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/bin"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/src"}))
	os.make_directory_all(filepath.join({project_root, "assets/textures"}))
	os.make_directory_all(filepath.join({project_root, "src"}))
	os.make_directory_all(filepath.join({project_root, "bin/release"}))
	
	// Always build in debug mode
	output_path := filepath.join({project_root, DEBUG_EXE_NAME})
	build_flag := "-debug"
	
	// Get source directory - absolute path
	src_dir := filepath.join({project_root, "src"})
	
	log.info("Building project in debug mode...")
	log.infof("Source directory: %s", src_dir)
	log.infof("Output path: %s", output_path)
	
	command := []string{"odin", "build", src_dir, build_flag, fmt.tprintf("-out:%s", output_path)}
	
	// Run the build command
	build_process, process_err := os.process_start({
		command = command,
		stdin = os.stdin,
		stdout = os.stdout,
		stderr = os.stderr,
	})
	
	if process_err != nil {
		log.errorf("Failed to start build process: %v", process_err)
		os.exit(1)
	}
	
	build_state, wait_err := os.process_wait(build_process)
	if wait_err != nil {
		log.errorf("Failed to wait for build process: %v", wait_err)
		os.exit(1)
	}
	
	close_err := os.process_close(build_process)
	if close_err != nil {
		log.errorf("Failed to close build process: %v", close_err)
		os.exit(1)
	}
	
	if build_state.exit_code != 0 {
		log.error("Build failed")
		os.exit(1)
	}
	
	// Copy SDL3.dll to root directory
	log.info("Copying SDL3.dll...")
	sdl_path := filepath.join({ODIN_VENDOR_PATH, "sdl3/SDL3.dll"})
	dest_path := filepath.join({project_root, "SDL3.dll"})
	log.infof("SDL source path: %s", sdl_path)
	log.infof("SDL destination path: %s", dest_path)
	
	// Make sure the SDL3.dll exists
	if !os.exists(sdl_path) {
		log.errorf("SDL3.dll not found at '%s'", sdl_path)
	} else {
		data, read_err := os.read_entire_file_from_path(sdl_path, context.allocator)
		defer delete(data)
		if read_err != nil {
			log.errorf("Failed to read SDL3.dll: %v", read_err)
		} else {
			write_err := os.write_entire_file(dest_path, data)
			if write_err != nil {
				log.errorf("Failed to write SDL3.dll: %v", write_err)
			} else {
				log.info("Successfully copied SDL3.dll")
			}
		}
	}
	
	log.info("Debug build complete!")
}

build_release :: proc() {
	// Get paths from config
	project_root := PROJECT_ROOT
	
	// Create directories
	log.info("Creating directory structure...")
	os.make_directory_all(filepath.join({project_root, "assets/meshes"}))
	os.make_directory_all(filepath.join({project_root, "assets/scenes"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/bin"}))
	os.make_directory_all(filepath.join({project_root, "assets/shaders/src"}))
	os.make_directory_all(filepath.join({project_root, "assets/textures"}))
	os.make_directory_all(filepath.join({project_root, "src"}))
	os.make_directory_all(filepath.join({project_root, "bin/release"}))
	
	// Set up build paths
	release_dir := filepath.join({project_root, "bin/release"})
	
	// Always build in release mode
	output_path := filepath.join({release_dir, RELEASE_EXE_NAME})
	build_flag := "-o:speed"
	
	// Get source directory - absolute path
	src_dir := filepath.join({project_root, "src"})
	
	log.info("Building project in release mode...")
	log.infof("Source directory: %s", src_dir)
	log.infof("Output path: %s", output_path)
	
	command := []string{"odin", "build", src_dir, build_flag, fmt.tprintf("-out:%s", output_path)}
	
	// Run the build command
	build_process, process_err := os.process_start({
		command = command,
		stdin = os.stdin,
		stdout = os.stdout,
		stderr = os.stderr,
	})
	
	if process_err != nil {
		log.errorf("Failed to start build process: %v", process_err)
		os.exit(1)
	}
	
	build_state, wait_err := os.process_wait(build_process)
	if wait_err != nil {
		log.errorf("Failed to wait for build process: %v", wait_err)
		os.exit(1)
	}
	
	close_err := os.process_close(build_process)
	if close_err != nil {
		log.errorf("Failed to close build process: %v", close_err)
		os.exit(1)
	}
	
	if build_state.exit_code != 0 {
		log.error("Build failed")
		os.exit(1)
	}
	
	// Copy SDL3.dll
	log.info("Copying SDL3.dll...")
	sdl_path := filepath.join({ODIN_VENDOR_PATH, "sdl3/SDL3.dll"})
	dest_path := filepath.join({release_dir, "SDL3.dll"})
	log.infof("SDL source path: %s", sdl_path)
	log.infof("SDL destination path: %s", dest_path)
	
	// Make sure the SDL3.dll exists
	if !os.exists(sdl_path) {
		log.errorf("SDL3.dll not found at '%s'", sdl_path)
	} else {
		data, read_err := os.read_entire_file_from_path(sdl_path, context.allocator)
		defer delete(data)
		if read_err != nil {
			log.errorf("Failed to read SDL3.dll: %v", read_err)
		} else {
			write_err := os.write_entire_file(dest_path, data)
			if write_err != nil {
				log.errorf("Failed to write SDL3.dll: %v", write_err)
			} else {
				log.info("Successfully copied SDL3.dll")
			}
		}
	}
	
	// Copy assets directory
	assets_dir := filepath.join({project_root, "assets"})
	if os.exists(assets_dir) && os.is_dir(assets_dir) {
		log.info("Copying assets directory...")
		dest_assets_dir := filepath.join({release_dir, "assets"})
		
		// Create the destination assets directory if it doesn't exist
		if !os.exists(dest_assets_dir) {
			os.make_directory(dest_assets_dir)
		}
		
		// Use robocopy to ensure all files and subdirectories are copied
		// /E = copy subdirectories including empty ones
		// /NFL = no file names in log
		// /NDL = no directory names in log
		// /NJH = no job header
		// /NJS = no job summary
		// /NC = no class names
		// /NS = no file sizes
		
		copy_assets_cmd := []string{
			"robocopy", 
			assets_dir, 
			dest_assets_dir, 
			"/E", 
			"/NFL", 
			"/NDL", 
			"/NJH", 
			"/NJS", 
			"/NC", 
			"/NS"
		}
		
		log.infof("Copying from %s to %s", assets_dir, dest_assets_dir)
		
		assets_process, assets_err := os.process_start({
			command = copy_assets_cmd,
			stdin = os.stdin,
			stdout = os.stdout,
			stderr = os.stderr,
		})
		
		if assets_err != nil {
			log.errorf("Failed to start assets copy process: %v", assets_err)
		} else {
			assets_state, assets_wait_err := os.process_wait(assets_process)
			if assets_wait_err != nil {
				log.errorf("Failed to wait for assets copy process: %v", assets_wait_err)
			}
			
			// Robocopy return codes:
			// 0 = No errors, no files copied
			// 1 = Files copied successfully
			// 2 = Extra files/dirs detected but not copied
			// >8 = At least one failure during copy
			if assets_state.exit_code > 8 {
				log.errorf("Assets copy failed with exit code: %d", assets_state.exit_code)
			} else {
				log.info("Assets directory copied successfully")
			}
			
			assets_close_err := os.process_close(assets_process)
			if assets_close_err != nil {
				log.errorf("Failed to close assets copy process: %v", assets_close_err)
			}
		}
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
	}
	
	log.info("Release build complete!")
	log.info("The release package is ready in the 'bin/release' directory.")
	log.info("You can copy this folder and run it from anywhere.")
}

main :: proc() {
	// Setup logging
	context.logger = log.create_console_logger()
	
	// Check if we're on Windows
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
	if build_type == "debug" {
		build_debug()
	} else {
		build_release()
	}
} 