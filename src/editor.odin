package main

import "core:math/linalg"
import "core:fmt"
import im "shared:imgui"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import im_sdlgpu "shared:imgui/imgui_impl_sdlgpu3"

import sdl "vendor:sdl3"
import "core:os"
import "core:strings"

// Editor-specific code that may import game functionality

Editor :: struct {
    is_initialized: bool,
    window: ^sdl.Window,
    
    // UI state
    show_demo_window: bool,
    show_metrics: bool,
    
    // Currently selected node for the inspector
    selected_node: ^Node,
    
    // Current scene being edited
    current_scene: ^Scene,
}

editor_init :: proc(window: ^sdl.Window) -> (editor: Editor, success: bool) {
    log_info(.EDITOR, "Initializing editor")
    
    // Initialize ImGui
    im.CHECKVERSION()
    im.CreateContext()
    io := im.GetIO()
    
    // Initialize renderers
    im_sdl.InitForSDLGPU(window)
    im_sdlgpu.Init(&{
        Device = renderer.gpu,
        ColorTargetFormat = renderer.swapchain_texture_format,
    })
    
    // Using default ImGui font
    log_info(.EDITOR, "Using default ImGui font")
    
    // Set up sRGB to linear conversion for ImGui colors
    style := im.GetStyle()
    for &color in style.Colors {
        color.rgb = linalg.pow(color.rgb, 2.2)
    }
    
    // Set initial UI state
    editor.is_initialized = true
    editor.window = window
    editor.show_demo_window = false
    editor.show_metrics = false
    
    // Create a mock default scene with a parent and child node
    editor.current_scene = create_mock_default_scene()
    
    // Select the parent node by default
    if editor.current_scene != nil && editor.current_scene.root != nil {
        editor.selected_node = editor.current_scene.root
    }
    
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
            if im.MenuItem("New Scene", "Ctrl+N") {
                editor.current_scene = scene_create()
            }
            
            if im.MenuItem("Open Scene", "Ctrl+O") {
                // TODO: Implement open scene
            }
            
            if im.MenuItem("Save Scene", "Ctrl+S") {
                if editor.current_scene != nil {
                    scene_save(editor.current_scene)
                }
            }
            
            im.Separator()
            
            if im.MenuItem("Exit", "Alt+F4") {
                // Signal to core to shut down
            }
            
            im.EndMenu()
        }
        
        if im.BeginMenu("Edit") {
            if im.MenuItem("Create Node", nil) {
                if editor.current_scene != nil {
                    new_node := node_create()
                    scene_add_node(editor.current_scene, new_node)
                }
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
    
    // Since full docking is not available, use simple window layout
    
    // Show demo window if enabled
    if editor.show_demo_window {
        im.ShowDemoWindow(&editor.show_demo_window)
    }
    
    // Show metrics window if enabled
    if editor.show_metrics {
        im.ShowMetricsWindow(&editor.show_metrics)
    }
    
    // Left Panel: Scene Tree
    im.SetNextWindowPos({0, 20})
    im.SetNextWindowSize({300, 700})
    if im.Begin("Scene Tree", nil) {
        if editor.current_scene != nil {
            im.Text("Scene: %s", editor.current_scene.name)
            im.Separator()
            
            // Display root node and children recursively
            if editor.current_scene.root != nil {
                display_node_tree(editor, editor.current_scene.root)
            } else {
                im.TextColored({1, 0.5, 0, 1}, "Empty Scene")
            }
            
            // Right-click context menu in scene tree
            if im.BeginPopupContextWindow() {
                if im.MenuItem("Add Node") {
                    new_node := node_create()
                    scene_add_node(editor.current_scene, new_node)
                }
                im.EndPopup()
            }
        }
        im.End()
    }
    
    // Middle Panel: Scene View
    im.SetNextWindowPos({300, 20})
    im.SetNextWindowSize({700, 700})
    if im.Begin("Scene View", nil) {
        // Just use simple text for now until we better understand the ImGui bindings
        im.Text("Scene Viewport")
        im.Text("Background color: %.2f, %.2f, %.2f", 
            renderer.clear_color.r, 
            renderer.clear_color.g, 
            renderer.clear_color.b)
        im.End()
    }
    
    // Right Panel: Inspector
    im.SetNextWindowPos({1000, 20})
    im.SetNextWindowSize({280, 700})
    if im.Begin("Inspector", nil) {
        if editor.selected_node != nil {
            im.Text("Node: %s", editor.selected_node.name)
            im.Separator()
            
            // Transform properties
            if im.CollapsingHeader("Transform") {
                // Revised widths for more compact layout
                label_width: f32 = 20
                value_width: f32 = 55
                spacing: f32 = 3
                button_size := im.Vec2{label_width, 0} // Auto height for buttons
                
                im.PushItemWidth(value_width)
                
                // Position section
                im.Text("Position")
                im.Spacing()
                
                // Position X - Red text
                im.PushID("pos_x_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({1, 0.2, 0.2, 1}, "X")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("pos_x")
                position_x := editor.selected_node.position.x
                if im.DragInt("##value", &position_x, 1.0) {
                    editor.selected_node.position.x = position_x
                }
                im.PopID()
                
                // Position Y - Green text
                im.SameLine(0, spacing*3)
                im.PushID("pos_y_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({0.2, 1, 0.2, 1}, "Y")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("pos_y")
                position_y := editor.selected_node.position.y
                if im.DragInt("##value", &position_y, 1.0) {
                    editor.selected_node.position.y = position_y
                }
                im.PopID()
                
                // Position Z - Blue text
                im.SameLine(0, spacing*3)
                im.PushID("pos_z_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({0.2, 0.2, 1, 1}, "Z")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("pos_z")
                position_z := editor.selected_node.position.z
                if im.DragInt("##value", &position_z, 1.0) {
                    editor.selected_node.position.z = position_z
                }
                im.PopID()
                
                im.Spacing()
                im.Separator()
                
                // Rotation section
                im.Text("Rotation")
                im.Spacing()
                
                // Placeholder for euler angles (will need proper conversion later)
                rotation_x, rotation_y, rotation_z := linalg.euler_angles_xyx_from_quaternion_f32(editor.selected_node.rotation)
                
                // Rotation X - Red text
                im.PushID("rot_x_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({1, 0.2, 0.2, 1}, "X")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("rot_x")
                if im.DragFloat("##value", &rotation_x, 0.1) {
                    editor.selected_node.rotation = linalg.quaternion_from_euler_angle_x_f32(rotation_x)
                }
                im.PopID()
                
                // Rotation Y - Green text
                im.SameLine(0, spacing*3)
                im.PushID("rot_y_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({0.2, 1, 0.2, 1}, "Y")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("rot_y")
                if im.DragFloat("##value", &rotation_y, 0.1) {
                    editor.selected_node.rotation = linalg.quaternion_from_euler_angle_y_f32(rotation_y)
                }
                im.PopID()
                
                // Rotation Z - Blue text
                im.SameLine(0, spacing*3)
                im.PushID("rot_z_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({0.2, 0.2, 1, 1}, "Z")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("rot_z")
                if im.DragFloat("##value", &rotation_z, 0.1) {
                    editor.selected_node.rotation = linalg.quaternion_from_euler_angle_z_f32(rotation_z)
                }
                im.PopID()
                
                im.Spacing()
                im.Separator()
                
                // Scale section
                im.Text("Scale")
                im.Spacing()
                
                // Scale X - Red text
                im.PushID("scale_x_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({1, 0.2, 0.2, 1}, "X")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("scale_x")
                scale_x := editor.selected_node.scale.x
                if im.DragInt("##value", &scale_x, 1.0) {
                    editor.selected_node.scale.x = scale_x
                }
                im.PopID()
                
                // Scale Y - Green text
                im.SameLine(0, spacing*3)
                im.PushID("scale_y_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({0.2, 1, 0.2, 1}, "Y")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("scale_y")
                scale_y := editor.selected_node.scale.y
                if im.DragInt("##value", &scale_y, 1.0) {
                    editor.selected_node.scale.y = scale_y
                }
                im.PopID()
                
                // Scale Z - Blue text
                im.SameLine(0, spacing*3)
                im.PushID("scale_z_btn")
                im.AlignTextToFramePadding()  // Align text baseline to match widgets
                im.TextColored({0.2, 0.2, 1, 1}, "Z")
                im.PopID()
                
                im.SameLine(0, spacing)
                im.PushID("scale_z")
                scale_z := editor.selected_node.scale.z
                if im.DragInt("##value", &scale_z, 1.0) {
                    editor.selected_node.scale.z = scale_z
                }
                im.PopID()
                
                // Reset item width
                im.PopItemWidth()
            }
            
            // Node properties
            if im.CollapsingHeader("Properties") {
                is_active := editor.selected_node.is_active
                if im.Checkbox("Active", &is_active) {
                    editor.selected_node.is_active = is_active
                }
            }
        } else {
            im.TextColored({0.5, 0.5, 0.5, 1}, "No node selected")
        }
        
        // Renderer settings section
        if im.CollapsingHeader("Renderer") {
            clear_color := [3]f32{
                renderer.clear_color.r,
                renderer.clear_color.g,
                renderer.clear_color.b,
            }
            if im.ColorEdit3("Background Color", &clear_color) {
                renderer.clear_color.r = clear_color[0]
                renderer.clear_color.g = clear_color[1]
                renderer.clear_color.b = clear_color[2]
            }
        }
        
        im.End()
    }
    
    // Finalize the ImGui frame
    im.Render()
    
    // Render ImGui to screen
    renderer_render_imgui(editor.window)
}

// Recursively display a node and its children in the scene tree
display_node_tree :: proc(editor: ^Editor, node: ^Node) {
    if node == nil do return
    
    // Simple approach with just text and mouse detection
    is_selected := editor.selected_node == node
    
    // Show node name, with prefix to indicate hierarchy
    if len(node.children) > 0 {
        if is_selected {
            im.TextColored({1, 1, 0, 1}, "+ %s", node.name) 
        } else {
            im.Text("+ %s", node.name)
        }
    } else {
        if is_selected {
            im.TextColored({1, 1, 0, 1}, "  %s", node.name)
        } else {
            im.Text("  %s", node.name)
        }
    }
    
    // Handle clicking
    if im.IsItemClicked() {
        editor.selected_node = node
    }
    
    // Context menu for this node - use a generic popup instead of context item
    if im.IsItemClicked(im.MouseButton.Right) {
        im.OpenPopup("NodeContextMenu")
    }
    
    if im.BeginPopup("NodeContextMenu") {
        im.Text("%s", node.name)
        im.Separator()
        
        if im.MenuItem("Add Child", "Ctrl+A") {
            child := node_create()
            node_add_child(node, child)
        }
        
        if im.MenuItem("Remove", "Del") {
            scene_remove_node(editor.current_scene, node)
        }
        
        im.EndPopup()
    }
    
    // Always show children for now
    im.Indent()
    for child in node.children {
        display_node_tree(editor, child)
    }
    im.Unindent()
}

editor_shutdown :: proc(editor: ^Editor) {
    log_info(.EDITOR, "Shutting down editor")
    
    // Clean up scene
    if editor.current_scene != nil {
        scene_destroy(editor.current_scene)
    }
    
    // Clean up ImGui
    im_sdlgpu.Shutdown()
    im_sdl.Shutdown()
    im.DestroyContext(nil)
    
    editor.is_initialized = false
}

// Creates a mock default scene with a parent node and child node for testing
create_mock_default_scene :: proc() -> ^Scene {
    scene := scene_create()
    if scene != nil {
        scene.name = "Default Scene"
        
        // Create parent node (root)
        parent := node_create()
        if parent != nil {
            // Make sure node has a proper ID and name
            if parent.id == 0 {
                parent.id = 1
            }
            parent.name = "RootNode"
            parent.position = {0, 0, 0}
            parent.scale = {1, 1, 1}
            parent.is_active = true
            
            // Set as scene root
            scene.root = parent
            append(&scene.nodes, parent)
            
            // Create child node
            child := node_create()
            if child != nil {
                // Make sure node has a proper ID and name
                if child.id == 0 {
                    child.id = 2
                }
                child.name = "ChildNode"
                child.position = {2, 0, 0}
                child.scale = {1, 1, 1}
                child.is_active = true
                
                // Add child to parent
                node_add_child(parent, child)
                
                // Add to scene nodes list
                append(&scene.nodes, child)
                
                // Create a second child node
                child2 := node_create()
                if child2 != nil {
                    // Make sure node has a proper ID and name
                    if child2.id == 0 {
                        child2.id = 3
                    }
                    child2.name = "ChildNode2"
                    child2.position = {0, 2, 0}
                    child2.scale = {1, 1, 1}
                    child2.is_active = false
                    
                    // Add second child to parent
                    node_add_child(parent, child2)
                    
                    // Add to scene nodes list
                    append(&scene.nodes, child2)
                }
            }
        }
    }
    
    return scene
}

// In the future, implement editor UI components, scene editing, asset management, etc.