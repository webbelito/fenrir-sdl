package main

import "core:fmt"
import "./log"

// For conditional compilation
// EDITOR_MODE uses the ODIN_DEBUG flag to determine if we are in editor mode, i.e. -debug is passed to the compiler
EDITOR_MODE :: ODIN_DEBUG

main :: proc() {
    // Initialize logging
    log.init()
    defer log.shutdown()
    
    log.app(format = "Fenrir SDL Engine starting...")
    
    when EDITOR_MODE {
        log.info(.EDITOR, format = "Starting in editor mode")
    } else {
        log.info(.GAME, format = "Starting in game mode")
    }
}