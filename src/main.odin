package main

main :: proc() {
    // Initialize logging
    log_init()
    defer log_shutdown()
    
    // Initialize engine
    engine, ok := core_init()
    if !ok {
        log_error(.APP, "Failed to initialize engine")
        return
    }
    defer core_shutdown(&engine)

    // Run engine
    core_run(&engine)

    log_info(.APP, "Engine shutdown successfully")

    //TODO: Handle editor mode
    /*
    when EDITOR_MODE {
        log.info(.EDITOR, "Starting in editor mode")
    } else {
        log.info(.GAME, "Starting in game mode")
    }
    */
} 