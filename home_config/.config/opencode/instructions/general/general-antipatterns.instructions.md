---
description: "General Anti-Patterns and Best Practices"
---

# General Anti-Patterns & Best Practices

You are an experienced developer. Before implementing any change, check whether any anti-pattern below applies to your context. Refactor or plan around them where needed.

---

## A. Common Programming Anti-Patterns

### Excessive Copying/Cloning

**Anti-pattern:** Copying data to satisfy ownership/borrowing rules instead of understanding references.

[Language-specific examples would go here]

**Rule:** Ask: "Do I need ownership, or would a reference/view work?" Copy only when semantically necessary.

### Overusing Shared References

**Anti-pattern:** Using shared references (like Rc/Arc in Rust) when simple borrowing suffices.

**Rule:** Use shared references only when ownership is genuinely shared across multiple owners. Prefer immutable/mutable references first.

### Primitive Obsession

**Anti-pattern:** Using primitive types (strings, numbers) for domain concepts that should have their own types.

```java
// BAD: Using strings for email addresses
public void sendEmail(String emailAddress, String subject, String body) { ... }

// GOOD: Using proper types
public void sendEmail(EmailAddress email, Subject subject, Body body) { ... }
```

**Rule:** Encapsulate domain concepts in proper types/classes/structs to gain type safety and self-documenting code.

### Long Parameter Lists

**Anti-pattern:** Functions with many parameters, especially of the same type.

```csharp
// BAD: Hard to remember parameter order
public void CreateUser(string firstName, string lastName, string email, 
                      string phone, DateTime birthDate, string address) { ... }

// GOOD: Parameter object
public void CreateUser(UserDetails details) { ... }

// OR: Builder pattern
public void CreateUser(UserBuilder builder) { ... }
```

**Rule:** Use parameter objects, builder patterns, or named parameters when functions have more than 2-3 parameters.

### Temporary Fields

**Anti-pattern:** Instance variables that are only used in certain situations, leading to confusing state.

**Rule:** If a field is only used in some methods, consider if those methods should be in a separate class, or if the field should be a local variable passed as needed.

### Refused Bequest

**Anti-pattern:** Subclasses that don't use inherited methods or fields, or override them to do nothing.

**Rule:** If a subclass doesn't need the parent's behavior, reconsider the inheritance hierarchy. Maybe composition is more appropriate.

### Comments

**Anti-pattern:** Using comments to explain bad code instead of making the code self-explanatory.

```javascript
// BAD: Explaining complex logic with comments
// Calculate total price with tax and discount
let total = (price * quantity) * (1 + taxRate) * (1 - discountRate);

// GOOD: Self-explanatory code
const subtotal = price * quantity;
const taxAmount = subtotal * taxRate;
const discountAmount = (subtotal + taxAmount) * discountRate;
const total = subtotal + taxAmount - discountAmount;
```

**Rule:** Use comments to explain why, not what or how. If code needs explaining, refactor it to be clearer.

---

## B. Performance Anti-Patterns

### Premature Optimization

**Anti-pattern:** Optimizing code before it's proven to be a bottleneck.

**Rule:** Make it work, make it right, then make it fast. Profile first, optimize second.

### Inefficient Loops

**Anti-pattern:** Doing expensive operations inside loops that could be moved outside.

```python
# BAD: Computing length on every iteration
for i in range(len(items)):
    if i == len(items) - 1:  # len() called n times
        # do something

# GOOD: Computing once
last_index = len(items) - 1
for i in range(len(items)):
    if i == last_index:  # len() called once
        # do something
```

**Rule:** Move loop-invariant computations outside loops.

### String Concatenation in Loops

**Anti-pattern:** Building strings by concatenation in loops (inefficient in many languages).

**Rule:** Use string builders, join operations, or appropriate efficient concatenation methods.

### Database Queries in Loops

**Anti-pattern:** Executing a database query for each item in a collection.

**Rule:** Batch operations or use joins to fetch related data in a single query when possible.

---

## C. Safety Anti-Patterns

### Null/Undefined Dereferencing

**Anti-pattern:** Not checking for null/undefined before using values.

**Rule:** Use language-appropriate null safety features (optional types, null checks, etc.) or follow the "billion dollar mistake" prevention patterns.

### Resource Leaks

**Anti-pattern:** Not closing/releasing resources like files, network connections, or database connections.

**Rule:** Use RAII (Resource Acquisition Is Initialization), try-with-resources, using statements, or ensure proper cleanup in finally blocks.

### Race Conditions

**Anti-pattern:** Unsynchronized access to shared mutable state from multiple threads/processes.

**Rule:** Use appropriate synchronization mechanisms (mutexes, locks, atomic operations, etc.) or immutable data structures.

### Insecure Direct Object References

**Anti-pattern:** Exposing internal object references (like database keys) in URLs or APIs without authorization checks.

**Rule:** Always check authorization before allowing access to objects, even if the user can guess/reference them.

---

## D. API Design Anti-Patterns

### Inconsistent Naming

**Anti-pattern:** Using different naming conventions for similar concepts.

**Rule:** Establish and follow consistent naming conventions throughout the codebase.

### Leaky Abstractions

**Anti-pattern:** Exposing internal implementation details in public APIs.

**Rule:** Hide internals and expose only what's necessary through well-designed interfaces.

### Long Methods/Functions

**Anti-pattern:** Functions that try to do too much and are hundreds of lines long.

**Rule:** Break down large functions into smaller, focused helper functions that do one thing well.

### Large Classes/Files

**Anti-pattern:** Classes or files that have too many responsibilities.

**Rule:** Follow the Single Responsibility Principle - split large classes into smaller, focused ones.

### Magic Numbers/Strings

**Anti-pattern:** Using unexplained numeric or string literals in code.

```c
// BAD: What does 86400 mean?
if (timeout > 86400) { ... }

// GOOD: Named constants
const int SECONDS_PER_DAY = 86400;
if (timeout > SECONDS_PER_DAY) { ... }
```

**Rule:** Replace magic numbers/strings with named constants or enums.

### Boolean Parameter Trap

**Anti-pattern:** Multiple boolean parameters with unclear meaning at call sites.

```java
// BAD: What do these booleans mean?
connect("host", true, false, true);

// GOOD: Self-documenting with enums or named parameters
connect("host", Encryption.ENCRYPTED, Connection.TRANSIENT, Verbosity.VERBOSE);
```

**Rule:** Use enums, named parameters, or builder patterns instead of multiple booleans.

---

## E. Testing Anti-Patterns

### Flaky Tests

**Anti-pattern:** Tests that sometimes pass and sometimes fail for no apparent reason.

**Rule:** Eliminate sources of non-determinism (timing, external services, random seeds) or mock/control them properly.

### Testing Implementation Details

**Anti-pattern:** Tests that are too coupled to implementation details, making refactoring difficult.

**Rule:** Test behavior, not implementation. Focus on public APIs and observable outcomes.

### No Tests for Error Conditions

**Anti-pattern:** Only testing happy paths and ignoring error conditions.

**Rule:** Test both success and failure paths, including edge cases and invalid inputs.

### Overly Complex Test Setup

**Anti-pattern:** Tests that require complex setup that obscures what's being tested.

**Rule:** Keep test setup simple and focused. Use fixtures, builders, or mocks to reduce complexity.

### Ignoring Test Performance

**Anti-pattern:** Slow test suites that discourage frequent running.

**Rule:** Keep unit tests fast. Use appropriate test doubles (mocks, fakes) to isolate units and avoid slow dependencies.

---

## F. Architecture Anti-Patterns

### God Objects

**Anti-pattern:** Classes that know too much or do too much.

**Rule:** Split responsibilities into smaller, focused classes with clear interfaces.

### Spaghetti Code

**Anti-pattern:** Complex, tangled control flow with lots of gotos, breaks, continues, or deeply nested conditionals.

**Rule:** Structure code with clear entry/exit points, use early returns, and break down complex logic.

### Copy-Paste Programming

**Anti-pattern:** Duplicating code instead of creating reusable functions/modules.

**Rule:** Follow DRY (Don't Repeat Yourself) - extract common code into reusable components.

### Golden Hammer

**Anti-pattern:** Trying to solve every problem with a familiar tool/technique.

**Rule:** Learn multiple approaches and choose the right tool for each job.

### Boat Anchor

**Anti-pattern:** Keeping unnecessary or unused code "just in case."

**Rule:** Remove dead code. If you need it later, version control has you covered.

---

## G. Comments on Language-Specific Patterns

While many anti-patterns are universal, some are language-specific. When working in a particular language/ecosystem:

1. Consult language-specific style guides and best practices
2. Follow community-established conventions
3. Use language-specific linting/formatting tools
4. Be aware of performance characteristics specific to the language/runtime
5. Consider idiomatic ways to accomplish tasks in that language

The key is to write code that feels natural to experienced developers in that language while avoiding common pitfalls.