package main

Game :: struct {
    is_initialized: bool,
}

Game_State :: enum {
    Stopped,
    Running,
    Paused,
}

game_init :: proc() -> (game: Game, success: bool) {

    log_info(.GAME, "Initializing game")

    game.is_initialized = true

    return game, true
}

game_update :: proc(game: ^Game, delta_time: f32) {
    // TODO: Update game logic
}

game_render :: proc(game: ^Game) {
    // TODO: Render game
}

game_shutdown :: proc(game: ^Game) {

    log_info(.GAME, "Shutting down game")
 
    // TODO: Shutdown game

    game.is_initialized = false
}

// Game-specific code with no editor dependencies 