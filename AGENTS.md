# AGENTS.md - Godot Project Guide

This document provides essential information for AI agents working on this Godot project. It covers project structure, conventions, development practices, and available tools.

## Project Overview

- **Godot Version:** 4.5.1
- **Target Platform:** Mobile (with mobile rendering method)
- Prefer `Control`-based scenes and UI-centric architecture.
- All gameplay code should be written in **typed GDScript** unless explicitly requested otherwise.

## MCP Usage

- This repo uses a Godot MCP server named **`godot-mcp`** when available.
- When working in this project, agents should:
  - Prefer `godot-mcp` for:
    - Inspecting scenes, nodes, attached scripts, and autoloads.
    - Checking resource paths and existing scenes.
    - Confirming Godot API details (methods, properties, signals).
  - Trust `godot-mcp` results over assumptions when they conflict.
  - If `godot-mcp` is unavailable, proceed with reasonable assumptions but say so briefly.

## GDScript & Typing Rules

- Use **typed GDScript** everywhere.
- Always explicitly type local variables that:
  - Participate in arithmetic, `min()`, `max()`, or other Variant-returning APIs.
  - Are used in APIs that expect a concrete type (e.g. `int`, `float`).
- Use type hints when possible:
  - Prefer: `var amount: int = min(2, juror.i)`
  - Avoid: `var amount := min(2, juror.i)` (becomes `Variant`).
- For arrays/dictionaries with a logical type, declare the element type:
  - `var jurors: Array[JurorState] = []`
- When using functions that return `Variant` (e.g. `Dictionary.get()`, `min()`, `max()`):
  - Use explicit types: `var loop_start: int = max(value1 - 1, 0)`
  - Use `Variant` type explicitly if needed: `var card: Variant = data.get("card_data")`.
- Use `@export` for inspector-visible properties

## Godot-Specific Rules

- **Ternary operators**:
  - GDScript does not support C-style `condition ? a : b`.
  - Use Python-style: `a if condition else b`.
- **`preload()` and custom Resources with `class_name`**:
  - Do **not** use `preload()` in `const` dictionaries for resources whose scripts use `class_name`.
  - Use lazy loading with `load()` inside functions instead.
- **`@icon` on `class_name` Resources**:
  - If you see `"Cannot get class"` errors, consider removing `@icon` from the Resource script as a troubleshooting step.
- **Naming collisions**:
  - Avoid class or variable names that mask existing singletons or globals (e.g. don’t use `class_name GameManager` if there is already a `GameManager` autoload).
- **Formatting**
  - GDScript requires the use of tabs for indentation, not spaces.
 
## UI & Scene Practices

- Default to `Control` for card game objects unless Node2D is truly needed.
- Use `@onready var` for node references.
- Favor small, modular scenes:
  - Examples: `CardUI.tscn`, `Hand.tscn`, `Deck.tscn`, `PlayArea.tscn`, `GameHUD.tscn`, `GameManager.gd` (autoload).
- Communicate between UI nodes using signals instead of deep `$` node paths.
- Use Godot’s container/layout system when possible; otherwise manage absolute positioning deliberately.

## Testing & Runtime Checks

- After non-trivial code changes, agents attempt to:
  - Running the game in the Godot editor.
  - Checking for runtime errors in the debugger/output.
  - If errors exist, close the game, fix any reported errors and rerunning until clean.
  - If no errors exist, close the game

## Development Guidelines

### Code Organization

1. **Scripts (GDScript)**
   - Store scripts in a `scripts/` or `src/` directory
   - Use PascalCase for class names
   - Use snake_case for variables and functions
   - Keep scripts focused and under 500 lines when possible

2. **Scenes**
   - Store scenes in a `scenes/` directory
   - Use descriptive names (e.g., `MainMenu.tscn`, `Player.tscn`)
   - Organize by feature/component when the project grows

3. **Assets**
   - Organize assets by type: `textures/`, `audio/`, `fonts/`, etc.
   - Use descriptive file names

### GDScript Best Practices

### Scene Structure

- Keep scene trees organized and logical
- Use groups for finding related nodes
- Leverage autoloads (singletons) for global systems
- Use scene inheritance when appropriate

## Workflow Recommendations

### Starting a New Feature

1. **Plan First**: Create a technical specification in `PLAN.md` before implementing
2. **Use MCP Tools**: Leverage Godot MCP tools for scene/script creation rather than manual file editing
3. **Test Incrementally**: Run the project frequently to test changes
4. **Document**: Update project notes as you work

### Making Changes

1. **Scenes**: Use MCP tools to modify scenes programmatically
2. **Scripts**: Create scripts using `mcp_godot_create_script` with appropriate templates
3. **Settings**: Use `mcp_godot_update_project_settings` for project configuration
4. **Validation**: Always validate scripts before committing

### Testing

1. Use `mcp_godot_run_with_debug` for comprehensive testing
2. Check `mcp_godot_get_debug_output` for errors and warnings
3. Use `mcp_godot_capture_screenshot` to verify visual changes
4. Use `mcp_godot_remote_tree_dump` to inspect runtime scene structure

### Debugging

1. Use `mcp_godot_get_error_context` to get detailed error information
2. Check Godot documentation using `mcp_godot_search_docs` or `mcp_godot_get_class_info`
3. Review best practices with `mcp_godot_get_best_practices`

## Important Notes

1. **Mobile Optimization**: This project uses mobile rendering method - keep performance in mind
2. **Godot 4.5 Features**: Can use Godot 4.5-specific features and APIs
3. **Import Files**: `.import` files should be committed to version control
4. **Project Settings**: Prefer using MCP tools or Godot editor for project settings rather than direct file editing
5. **Scene Files**: Scene files (`.tscn`) are text-based but complex - prefer using MCP tools or Godot editor

## Version Control

- Commit `.import` files
- Ignore `.godot/` directory (build cache)
- Use descriptive commit messages following conventional commits
- Create branches for major features

## Getting Help

- Use `mcp_godot_search_docs` to search Godot documentation
- Use `mcp_godot_get_class_info` for specific class information
- Use `mcp_godot_get_best_practices` for development guidance
- Use `mcp_godot_get_error_context` for error troubleshooting
