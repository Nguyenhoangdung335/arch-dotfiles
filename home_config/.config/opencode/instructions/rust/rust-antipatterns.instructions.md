---
description: "Rust Anti-Patterns and Best Practices"
---

# Rust Anti-Patterns & Best Practices

You are an experienced Rust developer. Before implementing any change, check whether any anti-pattern below applies to your context. Refactor or plan around them where needed.

---

## A. Ownership & Borrowing Anti-Patterns

### Excessive .clone()

**Anti-pattern:** Cloning data to satisfy the borrow checker instead of understanding ownership.

```rust
// BAD: 3 clones = 3x memory
fn process(data: Vec<String>) {
    let a = data.clone();
    let b = data.clone();
    let c = data.clone();
    use(a); use(b); use(c);
}

// GOOD: borrow where possible, move when done
fn process(data: Vec<String>) {
    print_all(&data);      // borrow for read
    let transformed = transform(&data); // borrow, returns new data
    save(data);            // move ownership when done
}
```

**Rule:** Ask: "Do I need ownership, or would a reference work?" Clone only when semantically necessary.

### Overusing Rc/Arc

**Anti-pattern:** Using reference counting for shared ownership when simple borrowing suffices.

```rust
// BAD: Rc adds heap + refcount overhead for single-owner data
struct Service {
    config: Rc<Config>,
    logger: Rc<Logger>,
}

// GOOD: borrow with lifetimes
struct Service<'a> {
    config: &'a Config,
    logger: &'a Logger,
}
```

**Rule:** Use `Rc`/`Arc` only when ownership is genuinely shared across multiple owners. Prefer `&'a T` references first. Use `Arc` only when thread safety is needed.

### String vs &str Confusion

**Anti-pattern:** Forcing callers to allocate by accepting `String` in function parameters.

```rust
// BAD: forces allocation on every caller
fn greet(name: String) -> String { format!("Hello, {name}") }

// GOOD: accept &str, flexible for both literals and owned strings
fn greet(name: &str) -> String { format!("Hello, {name}") }
// Works: greet("Alice") and greet(&owned_string)
```

**Rule:** Accept `&str` (or `impl AsRef<str>`) in parameters. Return `String` only when creating new owned data.

### Returning Owned When Borrowed Suffices

**Anti-pattern:** Cloning data just to return it from a getter.

```rust
// BAD: allocates on every call
impl User {
    fn name(&self) -> String { self.name.clone() }
}

// GOOD: zero-cost borrow
impl User {
    fn name(&self) -> &str { &self.name }
}
```

**Rule:** Return `&str`, `&[T]`, or `&T` for data you already own. Return owned data only when creating something new.

### Fighting the Borrow Checker

**Anti-pattern:** Using workarounds (unsafe, excessive clones, unnecessary Rc) instead of restructuring.

**Rule:** If the borrow checker complains, the design is likely wrong. Consider:
- Restructuring ownership (move instead of share)
- Splitting data into disjoint parts (`split_at_mut`)
- Using iterators instead of indexed access
- Copying small `Copy` types instead of borrowing

---

## B. Performance Anti-Patterns

### Unnecessary .collect()

**Anti-pattern:** Calling `.collect()` mid-chain, creating intermediate allocations.

```rust
// BAD: 2 intermediate Vecs allocated
let result: Vec<_> = data.iter().filter(|x| x.is_valid()).collect();
let result: Vec<_> = result.iter().map(|x| x.process()).collect();

// GOOD: single pass, zero allocations
let result: i32 = data.iter()
    .filter(|x| x.is_valid())
    .map(|x| x.process())
    .sum();
```

**Rule:** Chain iterators without intermediate collections. Only `.collect()` when you need the final container.

### Vec When Arrays Suffice

**Anti-pattern:** Using heap-allocated `Vec<T>` for fixed-size, small data.

```rust
// BAD: heap allocation for 3 bytes
fn get_rgb(pixel: u32) -> Vec<u8> { vec![r, g, b] }

// GOOD: stack-allocated
fn get_rgb(pixel: u32) -> [u8; 3] { [r, g, b] }
```

**Rule:** Use `[T; N]` for fixed-size data. Use `Vec<T>` only when size is truly dynamic.

### HashMap for Small Key Sets

**Anti-pattern:** Using `HashMap` for collections with <10 items.

```rust
// BAD: hash overhead for 3 items
let mut codes = HashMap::new();
codes.insert("ok", 200);
codes.insert("error", 500);

// GOOD: match compiles to jump table
fn get_code(s: &str) -> u16 {
    match s {
        "ok" => 200,
        "error" => 500,
        _ => 500,
    }
}
```

**Rule:** Use `match` for <10 known variants. Use `HashMap` only for larger or dynamic collections.

### Premature String Allocation

**Anti-pattern:** Converting to `String` early when `&str` suffices.

```rust
// BAD: allocates even when filtered out
fn process(line: &str) -> Option<String> {
    let owned = line.to_string();
    if !owned.starts_with("ERROR") { return None; }
    Some(owned.to_uppercase())
}

// GOOD: check first, allocate only when needed
fn process(line: &str) -> Option<String> {
    if !line.starts_with("ERROR") { return None; }
    Some(line.to_uppercase())
}
```

**Rule:** Work with `&str` as long as possible. Use `Cow<str>` for conditional allocation.

### Boxed Trait Objects Everywhere

**Anti-pattern:** Using `Box<dyn Trait>` when static dispatch with generics works.

```rust
// BAD: heap allocation + virtual dispatch
fn run(processors: Vec<Box<dyn Processor>>) { ... }

// GOOD: zero-cost monomorphization
fn run<P: Processor>(processors: &[P]) { ... }
```

**Rule:** Use generics for static dispatch when types are known at compile time. Use `dyn Trait` only for runtime polymorphism (plugin systems, heterogeneous collections).

### Ignoring Iterator Combinators

**Anti-pattern:** Manual loops with mutable accumulators.

```rust
// BAD: mutable state, harder to parallelize
fn sum_squares(nums: &[i32]) -> i32 {
    let mut sum = 0;
    for &n in nums { sum += n * n; }
    sum
}

// GOOD: declarative, easy to parallelize with rayon
fn sum_squares(nums: &[i32]) -> i32 {
    nums.iter().map(|&n| n * n).sum()
}
```

**Rule:** Prefer `.filter()`, `.map()`, `.fold()`, `.sum()` over manual loops. Enables `par_iter()` with zero code changes.

---

## C. Safety Anti-Patterns

### unsafe for Convenience

**Anti-pattern:** Bypassing the borrow checker with `unsafe` when safe alternatives exist.

```rust
// BAD: unsound if i == j
unsafe fn get_two(&mut self, i: usize, j: usize) -> (&mut T, &mut T) {
    let ptr = self.data.as_mut_ptr();
    (&mut *ptr.add(i), &mut *ptr.add(j))
}

// GOOD: safe, handles overlapping indices
fn get_two(&mut self, i: usize, j: usize) -> Option<(&mut T, &mut T)> {
    if i == j { return None; }
    // use split_at_mut or similar
}
```

**Rule:** Exhaust safe alternatives first. Every `unsafe` block must have a safety comment explaining why it's sound. If you can't write the safety comment, you shouldn't use `unsafe`.

### .unwrap() in Production Code

**Anti-pattern:** Using `.unwrap()` or `.expect()` that can panic on unexpected input.

```rust
// BAD: panics if file missing or JSON invalid
fn load_config(path: &str) -> Config {
    let s = std::fs::read_to_string(path).unwrap();
    serde_json::from_str(&s).unwrap()
}

// GOOD: returns Result with context
fn load_config(path: &str) -> Result<Config> {
    let s = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {path}"))?;
    serde_json::from_str(&s)
        .with_context(|| "failed to parse config")
}
```

**Rule:** Use `?` with `.context()` in applications. Use `thiserror` in libraries. Only `.unwrap()` when the value is guaranteed by construction (e.g., `unwrap` on a `Some` after `if let Some`).

### RefCell/Mutex as First Resort

**Anti-pattern:** Using interior mutability everywhere instead of proper `&mut self`.

```rust
// BAD: runtime borrow checking, can panic
struct App {
    state: RefCell<State>,
}

// GOOD: honest about mutation, compile-time checked
struct App {
    state: State,
}
impl App {
    fn update(&mut self) { ... }  // clearly needs mutation
    fn read(&self) -> &State { &self.state }  // clearly read-only
}
```

**Rule:** Use `&mut self` when mutation is needed. Use `RefCell`/`Mutex` only when the API requires shared references but mutation is genuinely needed (graphs, callbacks, caches).

### Ignoring Send/Sync Implications

**Anti-pattern:** Using thread-unsafe types (`Rc`, `RefCell`) across threads.

```rust
// BAD: Rc is not Send, data race
let data = Rc::new(RefCell::new(vec![1, 2, 3]));
thread::spawn(move || data.borrow_mut().push(4));

// GOOD: Arc<Mutex<T>> for thread-safe sharing
let data = Arc::new(Mutex::new(vec![1, 2, 3]));
let d = Arc::clone(&data);
thread::spawn(move || d.lock().unwrap().push(4));
```

**Rule:** Use `Arc<Mutex<T>>` or channels (`mpsc`) for cross-thread sharing. Understand `Send` and `Sync` before sharing types across threads.

---

## D. API Design Anti-Patterns

### Stringly-Typed APIs

**Anti-pattern:** Using strings for values that should be enums.

```rust
// BAD: typo "degub" compiles fine, panics at runtime
fn set_level(level: &str) { match level { "debug" => ... , _ => panic!() } }

// GOOD: compile-time checked, IDE autocomplete
enum LogLevel { Debug, Info, Warn, Error }
fn set_level(level: LogLevel) { match level { LogLevel::Debug => ... } }
```

**Rule:** Use enums for fixed sets of values. Strings only for truly dynamic data.

### Boolean Parameter Trap

**Anti-pattern:** Multiple boolean parameters with unclear meaning at call sites.

```rust
// BAD: what do these booleans mean?
connect("host", true, false, true);

// GOOD: self-documenting
connect("host", Encryption::Encrypted, Connection::Transient, Verbosity::Verbose);
```

**Rule:** Use enums or builder pattern instead of multiple booleans.

### Leaky Abstractions

**Anti-pattern:** Exposing internal data structures in public APIs.

```rust
// BAD: can't change internals without breaking users
pub struct Cache {
    pub store: HashMap<String, Vec<u8>>,
}

// GOOD: hide internals, expose only necessary interface
pub struct Cache {
    store: HashMap<String, Vec<u8>>,  // private
}
impl Cache {
    pub fn get(&self, key: &str) -> Option<&[u8]> { ... }
}
```

**Rule:** Keep struct fields private. Expose methods, not internals.

### Deref Coercion Abuse

**Anti-pattern:** Using `Deref` to emulate inheritance.

```rust
// BAD: implicit, confusing, not real inheritance
impl Deref for Manager {
    type Target = Employee;
    fn deref(&self) -> &Employee { &self.employee }
}

// GOOD: explicit methods
impl Manager {
    fn employee(&self) -> &Employee { &self.employee }
    fn name(&self) -> &str { &self.employee.name }
}
```

**Rule:** `Deref` is for smart pointers, not inheritance. Use explicit delegation methods.

### Overengineered Generic APIs

**Anti-pattern:** Complex trait bounds when simple concrete types suffice.

```rust
// BAD: 5 bounds for simple printing
fn print<I, T>(items: I)
where I: IntoIterator<Item = T>,
      T: Display + Debug + Clone + Send + 'static { ... }

// GOOD: simple and clear
fn print(items: &[impl Display]) { ... }
```

**Rule:** Use concrete types or simple generics. Add trait bounds only when they provide real value.

---

## E. Async Anti-Patterns

### Blocking in Async Context

**Anti-pattern:** Running blocking operations (file I/O, heavy compute) in async functions, blocking the executor.

```rust
// BAD: blocks the tokio worker thread
async fn load() -> String {
    std::fs::read_to_string("data.txt").unwrap()
}

// GOOD: offload to blocking thread pool
async fn load() -> String {
    tokio::task::spawn_blocking(|| {
        std::fs::read_to_string("data.txt")
    }).await.unwrap()
}
```

**Rule:** Use `spawn_blocking` for any blocking I/O or CPU-heavy work in async code. Keep async hot path clear for high-concurrency I/O.

### Ignoring Cancellation Safety

**Anti-pattern:** Using `tokio::select!` with operations that aren't cancellation-safe.

When `select!` completes one branch, other branches are dropped. If a dropped branch was mid-write, data may be corrupted.

**Rule:** Check crate docs for cancellation safety. Wrap non-safe operations in a task that runs to completion.

---

## F. Error Handling Anti-Patterns

### anyhow in Libraries

**Anti-pattern:** Using `anyhow` in library crates where callers need to match on specific errors.

**Rule:** Libraries use `thiserror` for structured, machine-readable errors. Applications use `anyhow` with `.context()`.

### Missing Error Context

**Anti-pattern:** Using bare `?` without adding context.

```rust
// BAD: error message is just "No such file or directory"
let s = std::fs::read_to_string(path)?;

// GOOD: error chain tells the story
let s = std::fs::read_to_string(path)
    .with_context(|| format!("failed to read config from {path}"))?;
```

**Rule:** Always attach context with `.context("what was happening")` in application code.

### Swallowing Errors

**Anti-pattern:** Using `let _ =` to ignore errors silently.

```rust
// BAD: error silently ignored
let _ = socket.write(data);

// GOOD: handle or propagate
socket.write(data).context("failed to send response")?;
// or explicitly document why it's safe to ignore:
let _ = socket.write(data); // best-effort flush on drop
```

**Rule:** Don't ignore errors unless explicitly documented as safe to ignore.

---

## G. Architecture Anti-Patterns

### Premature Crate Splitting

**Anti-pattern:** Splitting into many crates before needed, increasing compile times.

**Rule (2026 consensus):** Use deeply nested modules within a single library crate. Split into a separate crate only when you need:
1. Procedural macros (required by language)
2. Strict visibility boundaries (crate-level privacy)
3. Parallel compilation of large independent chunks

### Global Mutable State

**Anti-pattern:** Using `static mut`, `lazy_static!`, or `OnceCell` for shared mutable state.

**Rule:** Use dependency injection or pass state explicitly through function parameters. If globals are needed, use `OnceLock` with synchronization.

### Heavy Macro Use Hiding Logic

**Anti-pattern:** Complex procedural macros that make code opaque.

**Rule:** Prefer explicit code. Use macros only for true repetition reduction (derive macros, declarative macros). Always `cargo expand` to verify generated code.

---

## Best Practices Quick Reference (2026)

| Area | Practice | Tool/Crate |
|---|---|---|
| Language | Use 2024 Edition features | `rustc 1.85+` |
| Errors (libs) | `thiserror` for structured errors | `thiserror` |
| Errors (apps) | `anyhow` + `.context()` for propagation | `anyhow` |
| Testing | Property-based + snapshot testing | `proptest`, `insta` |
| Test runner | Faster, isolated test execution | `cargo-nextest` |
| Zero-copy | Map bytes directly to structs | `rkyv` |
| Linting | Run clippy pedantic | `cargo clippy -- -W clippy::pedantic` |
| Expansion | Inspect macro-generated code | `cargo-expand` |
