This is what I learned about quickshell while working and reading the docs:

# Quickshell.Hyprland module

## GlobalShortcut : QtObject

- This is the QtObject that is used to register a global shortcut integrated with Hyprland.
- Setting the `id`, `name`, and `description` properties is required.
- There are two listener properties: `onPressed` and `onReleased`.

# Quickshell.Io module

## IpcHandler : QtObject

- This is the QtObject that is used to expose custom functions to Command Line Interface (CLI) commands, through the uses of the `qs ipc call` command.
- It has two properties: `enabled` and `target` (unique).
- Inside of the `IpcHandler` object, there can be as much functions as possible, as long as each of them are limited to only ten arguments and have a type of: `["string", "int", "bool", "real", "color"]`
