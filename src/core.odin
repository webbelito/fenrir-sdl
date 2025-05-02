package main

// Vendor imports
import sdl "vendor:sdl3"

// Engine mode enum to track current operating mode
Engine_Mode :: enum {
    Editor,
    Game,
}

Engine :: struct {
    window: ^sdl.Window,
    is_running: bool,

    game: Game,
    game_state: Game_State,
    
    mode: Engine_Mode,
    has_editor: bool,
    editor: Editor,
}

// Set to true in debug builds to enable editor mode
EDITOR_MODE :: #config(EDITOR_MODE, ODIN_DEBUG)

core_init :: proc() -> (engine: Engine, success: bool) {

    log_info(.CORE, "Initializing engine")

    // Initialize SDL
    if ok := sdl.Init({.VIDEO}); !ok {
        log_error(.CORE, "Failed to initialize SDL")
        return {}, false
    }

    // Create window
    engine.window = sdl.CreateWindow(WINDIW_TITLE, WINDOW_WIDTH, WINDOW_HEIGHT, {.RESIZABLE})

    if engine.window == nil {
        log_error(.CORE, "Failed to create window during engine initialization: %s", sdl.GetError())
        return {}, false
    }

    // Initialize game
    game, game_ok := game_init()
    if !game_ok {
        log_error(.CORE, "Failed to initialize game")
        return {}, false
    }
    engine.game = game
    engine.game_state = .Stopped

    // Set initial engine mode
    engine.has_editor = EDITOR_MODE
    if engine.has_editor {
        // Initialize editor
        editor, editor_ok := editor_init()
        if !editor_ok {
            log_error(.CORE, "Failed to initialize editor")
            return {}, false
        }
        engine.editor = editor
        
        engine.mode = .Editor
        log_info(.CORE, "Starting in Editor mode - press F1 to toggle Play mode")
    } else {
        engine.mode = .Game
        engine.game_state = .Running
        log_info(.CORE, "Starting in Game mode (editor not available) - press P to pause/resume")
    }

    engine.is_running = true
    return engine, true
}

core_toggle_game_mode :: proc(engine: ^Engine) {
    if engine.mode == .Editor {
        // Switch from Editor to Game mode
        engine.mode = .Game
        engine.game_state = .Running
        log_info(.CORE, "Switched to Game mode")
    } else {
        // Switch from Game to Editor mode if editor is available
        if engine.has_editor {
            engine.mode = .Editor
            engine.game_state = .Stopped
            log_info(.CORE, "Switched to Editor mode")
        } else {
            log_info(.CORE, "Editor mode not available in this build")
        }
    }
}

core_toggle_pause :: proc(engine: ^Engine) {
    if engine.mode == .Game {
        if engine.game_state == .Running {
            engine.game_state = .Paused
            log_info(.CORE, "Game paused")
        } else if engine.game_state == .Paused {
            engine.game_state = .Running
            log_info(.CORE, "Game resumed")
        }
    } else {
        log_info(.CORE, "Cannot pause in Editor mode")
    }
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
                    } else if event.key.scancode == .F1 {
                        // Toggle between editor and game mode when F1 is pressed
                        core_toggle_game_mode(engine)
                    } else if event.key.scancode == .P {
                        // Toggle pause when P is pressed
                        core_toggle_pause(engine)
                    }
            }
        }

        // Update based on current mode
        if engine.mode == .Game && engine.game_state == .Running {
            // In game mode, update the game
            game_update(&engine.game, 1.0/60.0) // Fixed timestep for now
            log_verbose(.GAME, "Game update")
        } else if engine.mode == .Editor {
            // In editor mode, handle editor updates
            editor_update(&engine.editor, 1.0/60.0)
            log_verbose(.EDITOR, "Editor update")
        } else if engine.mode == .Game && engine.game_state == .Paused {
            // Game is paused, no updates but we'll still render
            log_verbose(.GAME, "Game paused")
        }

        // Render based on current mode
        if engine.mode == .Game {
            // Render game view
            game_render(&engine.game)
        } else {
            // Render editor view
            editor_render(&engine.editor)
        }
    }
}

core_update :: proc(engine: ^Engine) {
    // Update logic moved to core_run
}

core_render :: proc(engine: ^Engine) {
    // Render logic moved to core_run
}

core_shutdown :: proc(engine: ^Engine) {
    
    log_info(.CORE, "Shutting down engine")

    // Shutdown game
    game_shutdown(&engine.game)
    
    // Shutdown editor if available
    if engine.has_editor {
        editor_shutdown(&engine.editor)
    }

    // TODO: Shutdown renderer

    sdl.DestroyWindow(engine.window)
    sdl.Quit()
}
