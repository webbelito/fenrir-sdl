package main

// Vendor imports
import sdl "vendor:sdl3"

Engine :: struct {
    window: ^sdl.Window,
    is_running: bool,

    game: Game,
    game_state: Game_State,
}

EDITOR_MODE :: #config(EDITOR_MODE, ODIN_DEBUG)

core_init :: proc() -> (engine: Engine, success: bool) {

    log_info(.CORE, "Initializing engine")

    // Initialize SDL
    if ok := sdl.Init({.VIDEO}); !ok {
        log_error(.CORE, "Failed to initialize SDL")
        return {}, false
    }

    // Create window
    engine.window = sdl.CreateWindow("Fenrir", 1920, 1080, {.RESIZABLE})

    if engine.window == nil {
        log_error(.CORE, "Failed to create window during engine initialization: %s", sdl.GetError())
        return {}, false
    }

    // TODO: Initialize renderer

    engine.is_running = true
    return engine, true
}

core_run :: proc(engine: ^Engine) {
 
    log_info(.CORE, "Running engine")

    // Main loop
    for engine.is_running {
        // Process SDL Events
        for event: sdl.Event; sdl.PollEvent(&event); {
            #partial switch event.type {
                case .QUIT:
                    engine.is_running = false
                case .KEY_DOWN:
                    if event.key.scancode == .ESCAPE {
                        log_info(.CORE, "Escape key pressed, quitting")
                        engine.is_running = false
                    }
            }
        }
    }

    // TODO: Update Game State

    // TODO: Render

}

core_update :: proc(engine: ^Engine) {

}

core_render :: proc(engine: ^Engine) {

}

core_shutdown :: proc(engine: ^Engine) {
    
    log_info(.CORE, "Shutting down engine")

    // TODO: Shutdown renderer

    sdl.DestroyWindow(engine.window)
    sdl.Quit()
}
