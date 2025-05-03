package main

import "core:fmt"

Node :: struct {
    
    id: u64,
    name: string,
    parent: ^Node,
    children:[dynamic]^Node,

    // TODO: Create a proper Transform Component
    position: Vec3i,
    rotation: Quat,
    scale: Vec3i,

    is_active: bool,

}

// Global counter for generating unique node IDs
_next_node_id: u64 = 1

node_create :: proc() -> ^Node {
    node := new(Node)
    if node != nil {
        // Assign a unique ID
        node.id = _next_node_id
        _next_node_id += 1
        
        // Make sure we never use ID 0 (it causes ImGui assertion failures)
        if node.id == 0 {
            node.id = _next_node_id
            _next_node_id += 1
        }
        
        // Default values
        node.name = fmt.tprintf("Node_%d", node.id)
        node.parent = nil
        node.children = make([dynamic]^Node)
        node.position = {0, 0, 0}
        node.rotation = {} // Default identity quaternion
        node.scale = {1, 1, 1}
        node.is_active = true
        
        log_debug(.EDITOR, "Node created: %s (ID: %d)", node.name, node.id)
    }
    return node
}

node_add_child :: proc(parent: ^Node, child: ^Node) {
    if parent == nil || child == nil {
        log_error(.EDITOR, "Cannot add child: parent or child is nil")
        return
    }
    
    // Set parent-child relationship
    child.parent = parent
    append(&parent.children, child)
    
    log_debug(.EDITOR, "Node %s added as child to %s", child.name, parent.name)
}

node_remove_child :: proc(parent: ^Node, child: ^Node) {
    if parent == nil || child == nil {
        log_error(.EDITOR, "Cannot remove child: parent or child is nil")
        return
    }
    
    // Remove from parent's children array
    for i := 0; i < len(parent.children); i += 1 {
        if parent.children[i] == child {
            ordered_remove(&parent.children, i)
            child.parent = nil
            log_debug(.EDITOR, "Node %s removed from parent %s", child.name, parent.name)
            return
        }
    }
    
    log_warning(.EDITOR, "Node %s is not a child of %s", child.name, parent.name)
}

node_destroy :: proc(node: ^Node) {
    if node == nil {
        return
    }
    
    // Detach from parent if any
    if node.parent != nil {
        node_remove_child(node.parent, node)
    }
    
    // Destroy all children recursively
    for len(node.children) > 0 {
        child := node.children[0]
        node_destroy(child)
    }
    
    // Free the children array
    delete(node.children)
    
    log_debug(.EDITOR, "Node destroyed: %s (ID: %d)", node.name, node.id)
    free(node)
}
