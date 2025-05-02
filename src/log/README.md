# Log

A flexible logging system with dedicated context for the engine.

## Features
- Multiple log levels (VERBOSE, DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Category-based logging for different engine components
- Dedicated runtime context for consistent logging behavior
- Two-row formatted output with metadata header and message content
- Colored console output
- Filtering by level and category
- Simple API

## Usage

```odin
import "log"

// Initialize logging
log.init()
defer log.shutdown() // Clean up resources when done

// Basic logging with category
log.info(.CORE, "Engine initialized")
log.warning(.PHYSICS, "Collision system performance degraded")
log.error(.RENDERER, "Failed to load texture: %s", texture_path)

// Convenience functions for common categories
log.app("Application started")
log.core("Core system initialized")
log.renderer("Renderer initialized")
log.game("Game logic initialized")

// Error convenience functions
log.app_error("Application error: %s", err_message)

// Configure logging behavior
log.set_min_level(.WARNING) // Only show warnings and above
log.set_use_colors(false)   // Disable colored output
log.set_use_multi_line(false) // Switch to single-line format
log.set_category_enabled(.PHYSICS, false) // Disable physics logs
```

## Log Format

The default multi-line format shows:

```
[TIMESTAMP] [CATEGORY] [LEVEL]
    The actual message content
```

For example:

```
[2025-05-01 22:38:45] [CORE] [INFO]
    Engine initialized successfully

[2025-05-01 22:38:46] [PHYSICS] [WARNING]
    Collision system performance degraded
```

You can switch to a single-line format with `log.set_use_multi_line(false)`.

## Advanced Usage

For more advanced use cases, you can create multiple loggers with different configurations:

```odin
my_logger: log.Logger
// Initialize custom logger with its own context...
``` 