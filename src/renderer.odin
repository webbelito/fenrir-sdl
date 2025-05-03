package main

import "core:math/linalg"
import im "shared:imgui"
import im_sdl "shared:imgui/imgui_impl_sdl3"
import im_sdlgpu "shared:imgui/imgui_impl_sdlgpu3"
import sdl "vendor:sdl3"

Renderer :: struct {
    gpu: ^sdl.GPUDevice,
    swapchain_texture_format: sdl.GPUTextureFormat,
    clear_color: Vec4,
}

renderer: Renderer

// Rendering system functionality

renderer_init :: proc(window: ^sdl.Window) -> bool {
    log_info(.RENDERER, "Initializing renderer")

    // Create GPU device
    renderer.gpu = sdl.CreateGPUDevice({.SPIRV, .DXIL, .MSL}, true, nil)
    if renderer.gpu == nil {
        log_error(.RENDERER, "Failed to create GPU device")
        return false
    }

    // Claim the window for our GPU device
    ok := sdl.ClaimWindowForGPUDevice(renderer.gpu, window)    
    if !ok {
        log_error(.RENDERER, "Failed to claim window for GPU device")
        return false
    }

    // Set up swapchain with SDR linear color space and vsync
    ok = sdl.SetGPUSwapchainParameters(renderer.gpu, window, .SDR_LINEAR, .VSYNC)
    if !ok {
        log_error(.RENDERER, "Failed to set GPU swapchain parameters")
        return false
    }

    // Get the swapchain texture format for the swapchain
    renderer.swapchain_texture_format = sdl.GetGPUSwapchainTextureFormat(renderer.gpu, window)
    if renderer.swapchain_texture_format == nil {
        log_error(.RENDERER, "Failed to get GPU swapchain texture format")
        return false
    }

    // Set a dark blue clear color (RGB in 0-1 range)
    renderer.clear_color = {0.0, 0.0, 0.2, 1.0}
    
    log_info(.RENDERER, "Renderer initialized successfully")
    return true
}

// Render ImGui to screen (this function assumes ImGui's frame has been prepared by the editor)
renderer_render_imgui :: proc(window: ^sdl.Window) {
    // Acquire the command buffer
    command_buffer := sdl.AcquireGPUCommandBuffer(renderer.gpu)
    if command_buffer == nil {
        log_error(.RENDERER, "Failed to get GPU command buffer")
        return
    }

    // Clear the screen with our blue color
    swapchain_texture: ^sdl.GPUTexture
    ok := sdl.WaitAndAcquireGPUSwapchainTexture(command_buffer, window, &swapchain_texture, nil, nil)
    if !ok {
        log_error(.RENDERER, "Failed to acquire swapchain texture")
        return
    }
    
    if swapchain_texture != nil {
        // First, clear the screen with our blue color
        color_target := sdl.GPUColorTargetInfo {
            texture = swapchain_texture,
            load_op = .CLEAR,
            store_op = .STORE,
            clear_color = {renderer.clear_color.x, renderer.clear_color.y, renderer.clear_color.z, renderer.clear_color.w},
        }
        
        render_pass := sdl.BeginGPURenderPass(command_buffer, &color_target, 1, nil)
        sdl.EndGPURenderPass(render_pass)
        
        // Now render ImGui
        im_draw_data := im.GetDrawData()
        
        // Render if we have an active window
        if im_draw_data.DisplaySize.x > 0.0 && im_draw_data.DisplaySize.y > 0.0 {
            im_sdlgpu.PrepareDrawData(im_draw_data, command_buffer)
        
            im_color_target := sdl.GPUColorTargetInfo{
                texture = swapchain_texture,
                load_op = .LOAD,  // Load the previously cleared screen
                store_op = .STORE,
            }

            im_render_pass := sdl.BeginGPURenderPass(command_buffer, &im_color_target, 1, nil)
            im_sdlgpu.RenderDrawData(im_draw_data, command_buffer, im_render_pass)
            sdl.EndGPURenderPass(im_render_pass)
        } else {
            log_warning(.RENDERER, "Display size invalid: %.1f x %.1f", im_draw_data.DisplaySize.x, im_draw_data.DisplaySize.y)
        }
    }

    ok = sdl.SubmitGPUCommandBuffer(command_buffer)
    if !ok {
        log_error(.RENDERER, "Failed to submit GPU command buffer")
    }
}

renderer_shutdown :: proc() {
    log_info(.RENDERER, "Shutting down renderer")
    
    if renderer.gpu != nil {
        sdl.DestroyGPUDevice(renderer.gpu)
        renderer.gpu = nil
    }
}

