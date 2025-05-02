package log

import "core:fmt"
import "core:time"
import "core:strings"
import "base:runtime"
import "core:path/filepath"

// Log levels for different message priorities
Level :: enum {
    VERBOSE,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    CRITICAL,
}

// Log categories to differentiate message sources
Category :: enum {
    APP,      // Application-specific logs
    CORE,     // Engine core functionality
    RENDERER, // Rendering system
    AUDIO,    // Audio system
    INPUT,    // Input system
    PHYSICS,  // Physics system
    SCRIPT,   // Scripting system
    EDITOR,   // Editor-specific logs
    GAME,     // Game-specific logs
}

// Logger holds a dedicated context and configuration
Logger :: struct {
    ctx: runtime.Context,
    min_level: Level,         // Minimum level to display
    enabled_categories: map[Category]bool, // Categories that should be logged
    use_colors: bool,         // Whether to use colors in output
    use_multi_line: bool,     // Whether to use multi-line format
    show_source_loc: bool,    // Whether to show source location information
}

// Create a global default logger
default_logger: Logger

// Initialize the logging system with a dedicated context
init :: proc() {
    // Create a dedicated context for logging
    default_logger.ctx = runtime.default_context()
    default_logger.min_level = .VERBOSE
    default_logger.use_colors = true
    default_logger.use_multi_line = true
    default_logger.show_source_loc = true
    
    // By default enable all categories
    default_logger.enabled_categories = make(map[Category]bool)
    for i in Category {
        default_logger.enabled_categories[i] = true
    }
}

// Shutdown logging, free resources
shutdown :: proc() {
    delete(default_logger.enabled_categories)
}

// Get current timestamp as formatted string with local timezone
get_timestamp :: proc() -> string {
    // Get current time (already in local timezone in Odin)
    now := time.now()
    
    // Get year, month, day components
    year, month, day := time.date(now)
    
    // Get hour, minute, second, nanosecond components with precision
    hour, min, sec, nano := time.precise_clock_from_time(now)
    
    // Convert nanoseconds to milliseconds (divide by 1,000,000)
    milliseconds := nano / 1_000_000
    
    // Format to standard format: YYYY-MM-DD HH:MM:SS.mmm
    return fmt.tprintf("%04d-%02d-%02d %02d:%02d:%02d.%03d", 
                      year, int(month), day,
                      hour, min, sec, milliseconds)
}

// Get string representation of category
category_to_string :: proc(category: Category) -> string {
    #partial switch category {
    case .APP:      return "APP"
    case .CORE:     return "CORE"
    case .RENDERER: return "RENDER"
    case .AUDIO:    return "AUDIO"
    case .INPUT:    return "INPUT"
    case .PHYSICS:  return "PHYSICS"
    case .SCRIPT:   return "SCRIPT"
    case .EDITOR:   return "EDITOR"
    case .GAME:     return "GAME"
    }
    return "UNKNOWN"
}

// Format a source location into a string
format_source_location :: proc(loc: runtime.Source_Code_Location) -> string {
    // Get just the filename without the path
    filename := filepath.base(loc.file_path)
    return fmt.tprintf("%s:%d:%s", filename, loc.line, loc.procedure)
}

// Get string representation and color for level
level_to_string_and_color :: proc(level: Level, use_colors: bool) -> (string, string, string) {
    level_str := ""
    level_color := ""
    reset_color := use_colors ? "\x1b[0m" : ""
    
    if use_colors {
        #partial switch level {
        case .VERBOSE:
            level_str = "VERBOSE"
            level_color = "\x1b[90m" // Dark gray
        case .DEBUG:
            level_str = "DEBUG"
            level_color = "\x1b[94m" // Blue
        case .INFO:
            level_str = "INFO"
            level_color = "\x1b[92m" // Green
        case .WARNING:
            level_str = "WARNING"
            level_color = "\x1b[93m" // Yellow
        case .ERROR:
            level_str = "ERROR"
            level_color = "\x1b[91m" // Red
        case .CRITICAL:
            level_str = "CRITICAL"
            level_color = "\x1b[97;41m" // White on red background
        }
    } else {
        #partial switch level {
        case .VERBOSE:  level_str = "VERBOSE"
        case .DEBUG:    level_str = "DEBUG"
        case .INFO:     level_str = "INFO"
        case .WARNING:  level_str = "WARNING"
        case .ERROR:    level_str = "ERROR"
        case .CRITICAL: level_str = "CRITICAL"
        }
    }
    
    return level_str, level_color, reset_color
}

// Format a log message with timestamp and appropriate formatting
format_message :: proc(
    category: Category, 
    level: Level, 
    message: string, 
    loc: runtime.Source_Code_Location,
    use_colors := true, 
    use_multi_line := true,
    show_source_loc := true,
) -> string {
    // Get current timestamp
    time_str := get_timestamp()
    
    // Get category name
    cat_str := category_to_string(category)
    
    // Get level information
    level_str, level_color, reset_color := level_to_string_and_color(level, use_colors)
    
    // Get source location if enabled
    loc_str := ""
    if show_source_loc {
        loc_str = fmt.tprintf(" (%s)", format_source_location(loc))
    }
    
    if use_multi_line {
        // Multi-line format with header and message on separate lines
        header := fmt.tprintf("[%s] [%s] [%s%s%s]%s", 
            time_str, cat_str, level_color, level_str, reset_color, loc_str)
            
        // Add indentation to the message
        indent := "    "
        
        return fmt.tprintf("%s\n%s%s\n", header, indent, message)
    } else {
        // Single-line format
        return fmt.tprintf("[%s] [%s] [%s%s%s]%s %s\n", 
            time_str, cat_str, level_color, level_str, reset_color, loc_str, message)
    }
}

// Set the minimum level for logging - messages below this level will be ignored
set_min_level :: proc(level: Level) {
    default_logger.min_level = level
}

// Enable or disable colored output
set_use_colors :: proc(use_colors: bool) {
    default_logger.use_colors = use_colors
}

// Enable or disable multi-line format
set_use_multi_line :: proc(use_multi_line: bool) {
    default_logger.use_multi_line = use_multi_line
}

// Enable or disable source location information
set_show_source_loc :: proc(show_source_loc: bool) {
    default_logger.show_source_loc = show_source_loc
}

// Enable or disable a specific category
set_category_enabled :: proc(category: Category, enabled: bool) {
    default_logger.enabled_categories[category] = enabled
}

// Log a message with explicit logger
log_with_logger :: proc(
    logger: ^Logger, 
    level: Level, 
    category: Category, 
    loc := #caller_location,
    format: string, 
    args: ..any, 
) #no_bounds_check {
    // Check if this message should be logged
    if int(level) < int(logger.min_level) {
        return
    }
    
    if category in logger.enabled_categories && !logger.enabled_categories[category] {
        return
    }
    
    // Save current context
    prev_context := context
    
    // Switch to logger context
    context = logger.ctx
    
    message := fmt.tprintf(format, ..args)
    fmt_message := format_message(
        category, 
        level, 
        message, 
        loc, 
        logger.use_colors, 
        logger.use_multi_line,
        logger.show_source_loc,
    )
    fmt.eprint(fmt_message)
    
    // Restore context
    context = prev_context
}

// Log functions for each level
verbose :: proc(category: Category, loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .VERBOSE, category, loc, format, ..args)
}

debug :: proc(category: Category, loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .DEBUG, category, loc, format, ..args)
}

info :: proc(category: Category, loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .INFO, category, loc, format, ..args)
}

warning :: proc(category: Category, loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .WARNING, category, loc, format, ..args)
}

error :: proc(category: Category, loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .ERROR, category, loc, format, ..args)
}

critical :: proc(category: Category, loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .CRITICAL, category, loc, format, ..args)
}

// Convenience functions with preset categories
app :: proc(loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .INFO, .APP, loc, format, ..args)
}

core :: proc(loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .INFO, .CORE, loc, format, ..args)
}

renderer :: proc(loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .INFO, .RENDERER, loc, format, ..args)
}

game :: proc(loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .INFO, .GAME, loc, format, ..args)
}

// Shorthand error loggers
app_error :: proc(loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .ERROR, .APP, loc, format, ..args)
}

core_error :: proc(loc := #caller_location, format: string, args: ..any) {
    log_with_logger(&default_logger, .ERROR, .CORE, loc, format, ..args)
} 