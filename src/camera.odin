package main

import "core:math/linalg"
import "core:math"

// Camera struct for scene viewport
Camera :: struct {
    position: Vec3,                        // Camera position in world space
    target: Vec3,                          // Point camera is looking at
    up: Vec3,                              // Up vector for camera orientation
    
    fov: f32,                              // Field of view in degrees
    aspect_ratio: f32,                     // Aspect ratio (width/height)
    near_plane: f32,                       // Near clipping plane
    far_plane: f32,                        // Far clipping plane
    
    view_matrix: linalg.Matrix4f32,        // View transformation matrix
    projection_matrix: linalg.Matrix4f32,  // Projection transformation matrix
}

// Initialize a new camera with default parameters
camera_create :: proc() -> Camera {
    camera := Camera{
        position = {0, 5, 10},       // Position slightly back and up from origin
        target = {0, 0, 0},          // Looking at origin
        up = {0, 1, 0},              // Y-up orientation
        
        fov = 60,                    // 60 degrees field of view
        aspect_ratio = 16.0/9.0,     // Default aspect ratio
        near_plane = 0.1,            // Near clipping plane
        far_plane = 1000.0,          // Far clipping plane
    }
    
    // Calculate initial matrices
    camera_update_matrices(&camera)
    
    return camera
}

// Update the camera's view and projection matrices
camera_update_matrices :: proc(camera: ^Camera) {
    // Calculate view matrix (look at target)
    camera.view_matrix = linalg.matrix4_look_at_f32(
        camera.position, 
        camera.target, 
        camera.up
    )
    
    // Calculate projection matrix (perspective)
    camera.projection_matrix = linalg.matrix4_perspective_f32(
        math.to_radians(camera.fov),
        camera.aspect_ratio,
        camera.near_plane,
        camera.far_plane
    )
}

// Update the camera's aspect ratio (called when viewport is resized)
camera_set_aspect_ratio :: proc(camera: ^Camera, width, height: f32) {
    if height <= 0 {
        return
    }
    
    camera.aspect_ratio = width / height
    camera_update_matrices(camera)
}

// Move the camera to a new position
camera_set_position :: proc(camera: ^Camera, position: Vec3) {
    camera.position = position
    camera_update_matrices(camera)
}

// Set the target the camera is looking at
camera_set_target :: proc(camera: ^Camera, target: Vec3) {
    camera.target = target
    camera_update_matrices(camera)
}

// Orbit camera around target point
camera_orbit :: proc(camera: ^Camera, horizontal_angle, vertical_angle: f32) {
    // Calculate distance from target
    direction := camera.position - camera.target
    distance := linalg.length(direction)
    
    // Calculate new position based on angles
    x := distance * math.sin(vertical_angle) * math.cos(horizontal_angle)
    y := distance * math.cos(vertical_angle)
    z := distance * math.sin(vertical_angle) * math.sin(horizontal_angle)
    
    // Update camera position
    camera.position = {
        camera.target.x + x,
        camera.target.y + y,
        camera.target.z + z,
    }
    
    camera_update_matrices(camera)
}

// Pan camera (move target and position in tandem)
camera_pan :: proc(camera: ^Camera, offset: Vec3) {
    camera.position += offset
    camera.target += offset
    camera_update_matrices(camera)
}

// Zoom camera (move closer to or further from target)
camera_zoom :: proc(camera: ^Camera, zoom_factor: f32) {
    // Calculate direction from target to camera
    direction := linalg.normalize(camera.position - camera.target)
    
    // Move camera along this direction
    camera.position = camera.target + direction * zoom_factor
    
    camera_update_matrices(camera)
} 