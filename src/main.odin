package main

import "core:fmt"

// For conditional compilation
// EDITOR_MODE is supposed to be defined during build with -define:EDITOR_MODE=true
EDITOR_MODE :: ODIN_DEBUG

main :: proc() {
    fmt.println("Fenrir SDL Engine starting...")
    
    when EDITOR_MODE {
        fmt.println("Starting in editor mode")
    } else {
        fmt.println("Starting in game mode")
    }
}