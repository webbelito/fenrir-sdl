package main

import "core:math/linalg"
import im "shared:imgui"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import im_sdlgpu "shared:imgui/imgui_impl_sdlgpu3"

import sdl "vendor:sdl3"

// Editor-specific code that may import game functionality

Editor :: struct {
    is_initialized: bool,
    window: ^sdl.Window,
    
    // UI state
    show_demo_window: bool,
    show_metrics: bool,
}

editor_init :: proc(window: ^sdl.Window) -> (editor: Editor, success: bool) {
    log_info(.EDITOR, "Initializing editor")
    
    // Initialize ImGui
    im.CHECKVERSION()
    im.CreateContext()
    im_sdl.InitForSDLGPU(window)
    im_sdlgpu.Init(&{
        Device = renderer.gpu,
        ColorTargetFormat = renderer.swapchain_texture_format,
    })
    
    // Set up sRGB to linear conversion for ImGui colors
    style := im.GetStyle()
    for &color in style.Colors {
        color.rgb = linalg.pow(color.rgb, 2.2)
    }
    
    // Set initial UI state
    editor.is_initialized = true
    editor.window = window
    editor.show_demo_window = true
    editor.show_metrics = false
    
    return editor, true
}

editor_process_event :: proc(editor: ^Editor, event: ^sdl.Event) {
    im_io := im.GetIO()
    if im_io.WantCaptureMouse || im_io.WantCaptureKeyboard {
        im_sdl.ProcessEvent(event)
    }
}

editor_update :: proc(editor: ^Editor, delta_time: f32) {
    // Non-UI editor logic here if needed
}

editor_render :: proc(editor: ^Editor) {
    // Start the ImGui frame
    im_sdlgpu.NewFrame()
    im_sdl.NewFrame()
    im.NewFrame()
    
    // Main menu bar
    if im.BeginMainMenuBar() {
        if im.BeginMenu("File") {
            if im.MenuItem("New", "Ctrl+N") {
                // TODO: Implement new project
            }
            
            if im.MenuItem("Open", "Ctrl+O") {
                // TODO: Implement open project
            }
            
            if im.MenuItem("Save", "Ctrl+S") {
                // TODO: Implement save project
            }
            
            im.Separator()
            
            if im.MenuItem("Exit", "Alt+F4") {
                // Signal to core to shut down
            }
            
            im.EndMenu()
        }
        
        if im.BeginMenu("View") {
            // Toggle various editor windows
            if im.MenuItem("Demo Window", nil, editor.show_demo_window) {
                editor.show_demo_window = !editor.show_demo_window
            }
            
            if im.MenuItem("Metrics", nil, editor.show_metrics) {
                editor.show_metrics = !editor.show_metrics
            }
            
            im.EndMenu()
        }
        
        im.EndMainMenuBar()
    }
    
    // Show demo window if enabled
    if editor.show_demo_window {
        im.ShowDemoWindow(&editor.show_demo_window)
    }
    
    // Show metrics window if enabled
    if editor.show_metrics {
        im.ShowMetricsWindow(&editor.show_metrics)
    }
    
    // Properties panel
    if im.Begin("Properties") {
        // Renderer settings
        if im.CollapsingHeader("Renderer") {
            // Edit clear color
            im.ColorEdit3("Background Color", cast(^[3]f32)&renderer.clear_color[0])
        }
        
        im.End()
    }
    
    // Scene view
    if im.Begin("Scene") {
        im.Text("Scene View")
        im.End()
    }
    
    // Finalize the ImGui frame
    im.Render()
    
    // Render ImGui to screen
    renderer_render_imgui(editor.window)
}

editor_shutdown :: proc(editor: ^Editor) {
    log_info(.EDITOR, "Shutting down editor")
    
    // Clean up ImGui
    im_sdlgpu.Shutdown()
    im_sdl.Shutdown()
    im.DestroyContext(nil)
    
    editor.is_initialized = false
}

// In the future, implement editor UI components, scene editing, asset management, etc.