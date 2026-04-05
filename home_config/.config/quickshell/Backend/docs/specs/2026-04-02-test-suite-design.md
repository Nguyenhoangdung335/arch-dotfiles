# Test Suite Design - 2026-04-02

## Overview
Comprehensive test suite for the QuickShell Backend project using standard Rust testing patterns.

## Architecture

### 1. Unit Tests (Inline `#[cfg(test)]`)

| Module | Test Cases |
|--------|------------|
| `utils/compare.rs` | `update_if_changed` - same value, different value, nested types |
| `modules/network/enums.rs` | `From<u32>` for all enum variants, invalid values |
| `modules/network/state.rs` | `band_from_frequency`, `channel_from_frequency`, `is_secured`, `TryFrom<HashMap>` |
| `config.rs` | `socket_path` with/without env var, edge cases |

### 2. Integration Tests (`tests/` directory)

| Test File | Coverage |
|-----------|----------|
| `tests/config_test.rs` | Config loading, creation, file watching |
| `tests/ipc_test.rs` | Request parsing, response serialization |
| `tests/network_module_test.rs` | Module initialization, state updates |

### 3. Test Fixtures

Shared test data for D-Bus mocks and IPC requests/responses.

## Dependencies

```toml
[dev-dependencies]
tempfile = "3"
```

## Implementation Order

1. Add dev-dependencies to Cargo.toml
2. Create unit tests for utils/compare.rs
3. Create unit tests for modules/network/enums.rs
4. Create unit tests for modules/network/state.rs
5. Create unit tests for config.rs
6. Create integration tests for config
7. Create integration tests for IPC
8. Verify all tests pass
