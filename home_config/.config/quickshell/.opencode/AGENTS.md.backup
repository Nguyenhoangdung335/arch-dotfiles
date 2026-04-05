<!-- Agent Multi-Instruction Integration Start -->

# 🧠 Multi-Instruction Agent Directive

This agent must integrate and respect guidelines from all of the following instruction sources:

1. **This primary AGENT.md** — operational rules and technical style.
2. **EDUCATIONAL_AGENT.md** — mentorship, pedagogy, and tutor behavior directives.
3. **ARCHITECTURE_INTENT.md** — long-term architectural strategy and frontend/backend boundaries.

Before responding or proposing changes, the agent must:

- Read and internalize all three instruction files.
- Resolve conflicts by prioritizing the **Educational** and then **Architectural** intent for learning-focused guidance.
- Apply **Operational** rules for concrete implementation actions.

Do not ignore any of the above instruction sources when producing responses.

<!-- Agent Multi-Instruction Integration End -->

# Quickshell AI Agent Guidelines

This file contains essential instructions for AI coding agents operating in this repository, particularly within the Quickshell configuration (`home_config/.config/quickshell`).
This repository follows a long-term architectural direction described in `ARCHITECTURE_INTENT.md`. All implementations must remain compatible with that evolution.

## 1. Build, Lint, and Test Commands

This project uses Quickshell (a Wayland/Qt/QML-based shell configuration) and relies on runtime execution rather than a traditional compiled build step.

### 1.1 Running the Shell (Testing/Preview)

To test the full shell configuration or view changes to the UI layout, use the quickshell executable:

```bash
quickshell -c /home/dung/git_projects/arch-dotfiles/home_config/.config/quickshell/shell.qml
```

_(Note: If testing UI, you may need a nested Wayland session or to replace the current shell depending on the environment)._

### 1.2 IPC Testing (Command Line Interactions)

You can test specific IPC commands using the Quickshell CLI to invoke `IpcHandler` functions (e.g., toggling the sidebar, triggering themes):

```bash
qs ipc call sidebar toggle
qs ipc call sidebar open
```

### 1.3 Linting

There is no strict JS/QML linter enforced currently. However, as an agent, you must:

- Ensure syntax validation by checking for QML syntax errors upon runtime execution.
- Utilize `qmlls` (QML Language Server) diagnostics if available.
- Validate QML bindings and check that imported modules resolve correctly.

### 1.4 Testing a Single File or Component

To isolate and test a single component visually (if it's a window or root item), you can run it directly:

```bash
quickshell -c /path/to/Component.qml
```

_Note: Ensure the component does not have strict dependencies on `ShellRoot` if you are testing it entirely in isolation._

## 2. Code Style Guidelines

### 2.1 QML Components and Structure

- **File Naming:** Use `PascalCase` for QML files (e.g., `Sidebar.qml`, `ConnectionGraph.qml`) and `PascalCase` for directories (`Modules/`, `Components/`).
- **Component Structure:**
  - Include `pragma ComponentBehavior: Bound` at the top of QML files.
  - Follow imports with `id: root` for the outermost component.
  - Group properties, then signals, then visual items, then functions to maintain readability.
- **Imports:**
  - Use relative paths mapped to standard aliases. Standard aliases in this project:
    - `import "../../Themes" as Th`
    - `import "../../Components" as Comp`
    - `import "../../Config" as Cfg`
    - `import "../../Services" as Svc`
- **Styling & Theming:**
  - DO NOT hardcode colors. Use the centralized `Theme` singleton (e.g., `Th.Theme.bg`, `Th.Theme.fg`).
  - Use `Qt.rgba()` for transparency (e.g., `Qt.rgba(Th.Theme.bg.r, Th.Theme.bg.g, Th.Theme.bg.b, 0.85)`).
- **State & Animations:**
  - Prefer declarative state changes or QML `Behavior on` properties over complex imperative animation logic. Avoid creating continuous layout recalculations that can impact performance.

### 2.2 JavaScript and Logic

- **File Naming:** Use `PascalCase` for standalone JS utilities (e.g., `Logging.js`, `GraphMath.js`).
- **Typing & Documentation:** Use JSDoc annotations (`@param {string} name`, `@returns {number}`) for function parameters and return types to clarify expected types, as QML/JS lacks strict type checking.
- **Naming Conventions:**
  - Functions: `camelCase` (e.g., `toggleSidebar()`, `logInfo()`).
  - Variables/Properties: `camelCase`.
- **Logging:** Use the project's custom logging utility (`JSUtils/Logging.js`) instead of raw `console.log()` where possible. Example: `Logging.info("User clicked button")`. Ensure nested objects are stringified cleanly within the logger utility.
- **Error Handling:**
  - Wrap potentially failing JavaScript logic (like file I/O or JSON parsing) in `try...catch` blocks.
  - Log caught errors gracefully using `Logging.error(...)` to avoid crashing the shell implicitly.
  - Fall back to safe default values (e.g., empty arrays, default themes) in QML models when backend parsing fails.
- **Architectural Boundary (Future Rust Migration):**
  - The `Services/` layer currently contains system logic implemented in QML/JS. However, this logic is considered transitional.
  - System-level responsibilities (e.g., network status polling, Bluetooth state monitoring, DBus interaction, file system watchers, or any continuous background processing) are intended to migrate to a future Rust daemon.
  - When implementing new features, isolate system interaction code in a way that can later be replaced by an IPC-based backend (e.g., avoid tightly coupling UI components to raw shell command output).
  - Services should primarily transform and propagate structured data to `Models/`, not directly manipulate UI components.

### 2.3 Quickshell Specifics

- **Global Shortcuts:** Use `Quickshell.Hyprland` `GlobalShortcut` for registering keybinds (refer to `Cfg.KeyBinds` for centralized shortcuts). Always provide a descriptive `name` and `description` to make them easily discoverable.
- **IPC Handlers:** Expose internal API functions via `Quickshell.Io` `IpcHandler`. Limit IPC functions to a maximum of 10 arguments of the supported base types: `["string", "int", "bool", "real", "color"]`.
- **Service Layer Discipline:**
  - Services must not import or depend on `Components/` or `Modules/`.
  - Services should operate only on `Models/` and emit signals or update properties.
  - Avoid embedding visual state logic (animations, layout decisions) inside Services.

## 3. General Agent Protocols

- **Understand Before Editing:** Always use `read` and `glob` tools to examine the context of a component (e.g., related Models and Services) before altering it. Do not guess structure.
- **Idempotency & Syntax Context:** When editing QML structures, ensure exact matching of indentation and nested object structure to prevent deep syntax errors. Be aware of QML's specific scope resolution.
- **No Fictional Dependencies:** Do not import `QtQuick.Controls` or other Qt modules unless they are explicitly present or verified working in the environment. Rely heavily on custom components defined in `Components/`.
- **Preserve Existing Implementations:** When refactoring, do not remove features that currently work unless explicitly instructed. Instead, optimize their logic or modularize them appropriately.
- **Test Logs Analysis:** Read the output of `quickshell` logs to debug binding loops or IPC failure issues after deploying a fix. Pay close attention to warnings regarding `TypeError` or `ReferenceError` inside QML signals.

## 4. Forward Architecture Compatibility

This project is designed to evolve into a two-layer system:

- Frontend:
  - Quickshell (QML/Qt) for UI rendering and interaction.
- Backend (Planned):
  - A Rust daemon responsible for system interaction and event-driven updates.

When introducing new system-facing logic:

- Prefer designing it in a way that could later be replaced by a Unix socket or DBus-based IPC bridge.
- Avoid deeply coupling UI logic to shell command outputs or polling loops.
- Keep system interaction modular and replaceable.
