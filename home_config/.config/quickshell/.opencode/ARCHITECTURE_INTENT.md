# Architecture Intent: Quickshell + Rust Backend Evolution

This document defines the long-term architectural direction of this repository.
All implementations must remain compatible with this intended evolution.

---

## 1. Purpose of the Architecture

This repository serves two parallel objectives:

1. A modular, maintainable Quickshell configuration.
2. A structured learning environment for:
   - QML and Qt component architecture
   - Declarative UI design principles
   - Service-layer separation
   - Rust systems programming
   - Async Rust
   - IPC (Unix Domain Sockets / DBus)
   - Event-driven backend design

The system must evolve in a way that reinforces these learning goals.

---

## 2. Target Architecture (Two-Layer System)

The project is intended to evolve into a **Frontend + Backend** architecture.

### 2.1 Frontend Layer (Quickshell / QML)

Responsibilities:

- UI rendering
- Animations and transitions
- Declarative state bindings
- User interaction handling
- Keybind registration
- Presentation of structured data

The frontend must:

- Remain declarative where possible.
- Avoid heavy polling loops.
- Avoid long-running background processing.
- Avoid direct system command parsing when a backend abstraction exists.

---

### 2.2 Backend Layer

Responsibilities:

- System interaction (network, bluetooth, filesystem, etc.)
- DBus communication
- Event-driven state monitoring
- Continuous background tasks
- Data normalization and serialization
- IPC exposure to frontend

The backend will:

- Run independently of Quickshell.
- Communicate via Unix Domain Sockets or DBus.
- Send structured JSON or typed messages.
- Operate asynchronously using proper Rust concurrency patterns.

---

## 3. Transitional Service Layer (Current State)

The `Services/` directory currently contains system logic implemented in QML/JavaScript.

This layer is considered transitional.

Rules:

- Services must not depend on UI components.
- Services should update `Models/` and emit signals only.
- Services should isolate system interaction logic to allow future backend replacement.
- Avoid tightly coupling Services to raw shell output formats.

When possible, design Services as if the data source could later be replaced by an IPC adapter.

---

## 4. Architectural Boundary Rules

When introducing new logic, determine its proper layer:

### Logic belongs in QML if it:

- Affects visual presentation.
- Controls animations or transitions.
- Manages UI state.
- Reacts to user interaction.

### Logic belongs in Rust (future backend) if it:

- Requires frequent polling (<2 seconds).
- Listens to DBus signals.
- Monitors system state continuously.
- Requires concurrency.
- Performs heavy parsing or computation.
- Must remain active independently of UI lifecycle.

If uncertain, default to separation rather than convenience.

---

## 5. Migration Strategy

Feature evolution should follow this pattern:

Phase 1:

- Implement logic in QML Services for rapid iteration.
- Clearly separate data acquisition from data presentation.

Phase 2:

- Reimplement system interaction in Rust.
- Replace QML polling with IPC-based data flow.
- Preserve existing `Models/` and UI bindings.

The UI layer should remain largely unchanged during backend migration.

---

## 6. AI Agent Directive

When proposing changes or reviewing code:

- Respect the intended frontend/backend separation.
- Avoid collapsing backend responsibilities into UI logic for convenience.
- Highlight when logic would be better suited for a future Rust daemon.
- Encourage modularity and replaceable boundaries.
- Optimize for long-term architectural clarity over short-term simplicity.

All structural suggestions must align with this architectural direction.
