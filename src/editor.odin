package main

import im "shared:imgui"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import im_sdlgpu "shared:imgui/imgui_impl_sdlgpu3"

import sdl "vendor:sdl3"

// Editor-specific code that may import game functionality

Editor :: struct {
    is_initialized: bool,
    window: ^sdl.Window,
}

editor_init :: proc(window: ^sdl.Window) -> (editor: Editor, success: bool) {
    log_info(.EDITOR, "Initializing editor")
    
    editor.is_initialized = true
    editor.window = window
    
    return editor, true
}

editor_update :: proc(editor: ^Editor, delta_time: f32) {
    // Handle editor-specific logic here
}

editor_render :: proc(editor: ^Editor) {
    // Start the ImGui frame
    im_sdlgpu.NewFrame()
    im_sdl.NewFrame()
    im.NewFrame()
    
    // Build ImGui UI here
    im.ShowDemoWindow()
    
    // Finalize the ImGui frame
    im.Render()
    
    // Render ImGui to screen
    renderer_render_imgui(editor.window)
}

editor_update_imgui :: proc(editor: ^Editor) {
    // This function is now redundant as we moved the frame setup to editor_render
}

editor_shutdown :: proc(editor: ^Editor) {
    log_info(.EDITOR, "Shutting down editor")
    
    // TODO: Cleanup editor resources
    
    editor.is_initialized = false
}

// In the future, implement editor UI components, scene editing, asset management, etc.