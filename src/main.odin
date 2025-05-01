package main

import "core:fmt"

main :: proc() {

    when ODIN_DEBUG {
        fmt.println("Debug mode")
    } else {
        fmt.println("Release mode")
    }

}