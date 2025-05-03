package main

import "core:fmt"

Scene :: struct {
    name: string,
    root: ^Node,

    nodes: [dynamic]^Node,
}

// Global counter for generating unique scene IDs
_next_scene_id: u64 = 1

scene_create :: proc() -> ^Scene {
    scene := new(Scene)
    if scene != nil {
        // Default values
        scene.name = fmt.tprintf("Scene_%d", _next_scene_id)
        scene.root = nil
        scene.nodes = make([dynamic]^Node)
        
        _next_scene_id += 1
        
        log_debug(.EDITOR, "Scene created: %s", scene.name)
    }
    return scene
}

scene_load :: proc(scene: ^Scene) {
    if scene == nil {
        log_error(.EDITOR, "Cannot load nil scene")
        return
    }
    
    log_debug(.EDITOR, "Scene loaded: %s", scene.name)
}

scene_save :: proc(scene: ^Scene) {
    if scene == nil {
        log_error(.EDITOR, "Cannot save nil scene")
        return
    }
    
    log_debug(.EDITOR, "Scene saved: %s", scene.name)
}

scene_destroy :: proc(scene: ^Scene) {
    if scene == nil {
        return
    }
    
    // Destroy all nodes in the scene
    for len(scene.nodes) > 0 {
        node := scene.nodes[0]
        scene_remove_node(scene, node)
        node_destroy(node)
    }
    
    // Free the nodes array
    delete(scene.nodes)
    
    log_debug(.EDITOR, "Scene destroyed: %s", scene.name)
    free(scene)
}

scene_add_node :: proc(scene: ^Scene, node: ^Node) {
    if scene == nil || node == nil {
        log_error(.EDITOR, "Cannot add node: scene or node is nil")
        return
    }
    
    // Add node to scene's nodes array
    append(&scene.nodes, node)
    
    // If it's the first node and no root is set, make it the root
    if scene.root == nil && len(scene.nodes) == 1 {
        scene.root = node
    }
    
    log_debug(.EDITOR, "Node %s added to scene %s", node.name, scene.name)
}

scene_remove_node :: proc(scene: ^Scene, node: ^Node) {
    if scene == nil || node == nil {
        log_error(.EDITOR, "Cannot remove node: scene or node is nil")
        return
    }
    
    // Check if node is in the scene's nodes array
    found := false
    for i := 0; i < len(scene.nodes); i += 1 {
        if scene.nodes[i] == node {
            // Remove from the scene's nodes array
            ordered_remove(&scene.nodes, i)
            found = true
            break
        }
    }
    
    if !found {
        log_warning(.EDITOR, "Node %s not found in scene %s", node.name, scene.name)
        return
    }
    
    // If node is the root, clear the root
    if scene.root == node {
        scene.root = nil
    }
    
    // If node has a parent, remove from parent's children
    if node.parent != nil {
        node_remove_child(node.parent, node)
    }
    
    // Handle children (detach them from this node but keep them in the scene)
    for len(node.children) > 0 {
        child := node.children[0]
        node_remove_child(node, child)
    }
    
    log_debug(.EDITOR, "Node %s removed from scene %s", node.name, scene.name)
}




