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

### Debugging Visual/Animation Bugs

When fixing visual feedback bugs (animations, projectiles, highlights):
1. **Trace the complete signal flow** - Find ALL signal handlers, not just the obvious one
2. **Search for ALL related code** - Use `grep` for related terms (e.g., "projectile", "fire", "highlight")
3. **Check for name-based lookups** - When multiple identical items exist (same card name, same enemy type), name-based lookups will return the first match. Consider if index/ID-based lookup is needed.
4. **List all visual effects** - Before coding, identify ALL visual changes that should happen (projectile origin, card pulse, damage floater, etc.)

### Automated Testing Requirements

**NEVER ask the user to manually test.** Always write automated tests:

1. **For visual/UI features:**
   - Create a test scene in `scenes/tests/` with a test script in `scripts/tests/`
   - Set up required nodes programmatically (don't rely on full game state)
   - Trigger the behavior being tested
   - Use `print("[TEST] ...")` statements to output state for verification
   - Verify expected values (visibility, position, scale, alpha, etc.)
   - Call `get_tree().quit(0)` on pass, `get_tree().quit(1)` on fail

2. **Run tests using MCP tools:**
   - `mcp_godot_run_with_debug` with the test scene
   - `mcp_godot_get_debug_output` to capture results
   - `mcp_godot_stop_project` to clean up

3. **Test verification pattern:**
   ```gdscript
   print("[TEST] Value check: ", actual_value)
   var passed: bool = actual_value == expected_value
   print("[TEST] RESULT: ", "PASSED ✓" if passed else "FAILED ✗")
   get_tree().quit(0 if passed else 1)
   ```

4. **Wait for async operations:**
   - Use `await get_tree().process_frame` to wait for nodes to initialize
   - Use `await get_tree().create_timer(X).timeout` when testing animations/tweens
   - Example: wait 0.5-1.0 seconds after triggering a morph animation before verifying final state

### Use MCP Godot Tools (Preferred Method)

Always use the MCP Godot tools for running and testing the game. **Do NOT use terminal commands** for running Godot because:
- PowerShell syntax differs from bash (`&&` not valid, need `;`)
- Godot executable path varies per machine and is unknown
- Output capture is inconsistent via terminal

### Correct Testing Workflow

**CRITICAL: Understand blocking vs non-blocking tools:**

| Tool | Blocking? | Use Case |
|------|-----------|----------|
| `mcp_godot_run_with_debug` | **NO** (async) | Interactive testing - game runs in background |
| `mcp_godot_run_scene` | **YES** (sync) | Quick validation - WAITS for game to close |

#### For Interactive Testing (RECOMMENDED):

1. **Start the game (non-blocking):**
   ```
   mcp_godot_run_with_debug(projectPath, scene="scenes/Combat.tscn", captureOutput=true)
   ```
   - Game runs in background, returns immediately
   - Can specify a scene with `scene` parameter

2. **Check ongoing output while game is running:**
   ```
   mcp_godot_get_debug_output()
   ```

3. **Stop the game and get final output:**
   ```
   mcp_godot_stop_project()
   ```
   - **ALWAYS** call this when done testing to properly close the game
   - Returns final output including any errors

#### For Quick Validation Only:

```
mcp_godot_run_scene(projectPath, scenePath, debug=true)
```
- ⚠️ **WARNING: This BLOCKS until the user closes the game window!**
- Only use when you want a one-shot test that waits for completion
- The agent will STALL if used expecting to continue working

### Standard Test Cycle

After non-trivial code changes:
1. Run `mcp_godot_run_scene` or `mcp_godot_run_with_debug`
2. Check output for errors or expected debug messages via `mcp_godot_get_debug_output`
3. Call `mcp_godot_stop_project` to close and get final output
4. If errors exist, fix them and repeat
5. If no errors exist, testing is complete

### Debug Output Best Practices

- Add `print()` statements with prefixed tags like `[ClassName DEBUG]` for tracking
- Check debug output for these tags to verify code paths executed
- Use `print()` liberally during debugging, clean up after fix is verified

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

See **"Testing & Runtime Checks"** section above for detailed workflow.

Key tools:
1. `mcp_godot_run_with_debug` - Run project with output capture
2. `mcp_godot_run_scene` - Run specific scene for focused testing
3. `mcp_godot_get_debug_output` - Check output while running
4. `mcp_godot_stop_project` - Stop game and get final output (ALWAYS call this)
5. `mcp_godot_capture_screenshot` - Verify visual changes
6. `mcp_godot_remote_tree_dump` - Inspect runtime scene structure

**Never use terminal commands to run Godot** - use MCP tools instead.

### Debugging

1. Use `mcp_godot_get_error_context` to get detailed error information
2. Check Godot documentation using `mcp_godot_search_docs` or `mcp_godot_get_class_info`
3. Review best practices with `mcp_godot_get_best_practices`

## Documentation Requirements

**CRITICAL: After every prompt/task, agents MUST update these files:**

### DESIGN.md
- Contains game design, technical architecture, and implementation status
- **MUST BE HYPER-SPECIFIC** - Any new agent should be able to read this and know EXACTLY:
  - What each card/enemy/artifact does (exact numbers, effects, costs)
  - What each mechanic means (how Hex works, how Armor works, etc.)
  - What's implemented vs what needs to be built
  - The exact behavior expected from any system
- Update when:
  - Adding new features or systems
  - Changing architecture or file structure
  - Completing or starting new implementation phases
  - Fixing significant bugs
  - Adding or changing any game content (cards, enemies, etc.)
- **Never use vague descriptions** like "deals damage" - always specify "deals 6 damage to all enemies in Close ring"

### PROGRESS.md  
- Contains current status tracker with checkboxes
- Update when:
  - Completing any task
  - Finding new bugs or issues
  - Changing what's working vs broken
  - Testing reveals new status

**Both files should reflect the TRUE current state of the project at all times.**

---

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
