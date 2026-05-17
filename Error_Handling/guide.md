# Error Handling in Cairo

## What Is Error Handling?

Error handling is the process of anticipating, detecting and responding to errors that occur during program execution. Instead of letting your program crash silently or produce wrong results you handle errors explicitly and communicate what went wrong.

In Cairo, error handling is explicit by design. The language forces you to deal with errors, you cannot ignore them like you might in some other languages.


## Why Error Handling Matters in Smart Contracts

Smart contracts handle real money and real state on a blockchain. A bug or unhandled error can:

- Lock funds permanently
- Allow unauthorized actions
- Corrupt contract state
- Cause silent failures that are hard to debug on-chain

This makes proper error handling not optional but it is a core part of writing safe contracts.


## Core Tools for Error Handling in Cairo

### 1. `panic`

`panic` is the most basic way to halt execution and signal that something went wrong. When a panic is triggered, execution stops immediately and all state changes in the current call are reverted. Panics in Cairo are not catchable within the same contract call. They are terminal and execution stops.

**Syntax:**
```cairo
panic_with_felt252('some error message');
```

Or using the `panic!` macro:
```cairo
panic!("something went wrong");
```

**When to use it:**
- When a condition is violated that should never happen
- When there is no valid way to continue execution


### 2. `assert`

`assert` checks a condition. If the condition is false, it panics with a message you provide.

**Syntax:**
```cairo
assert(condition, 'error message');
```

**Example:**
```cairo
assert(balance >= amount, 'Insufficient balance');
```

`assert` is syntactic sugar for:
```cairo
if !condition {
    panic_with_felt252('error message');
}
```

**When to use it:**
- Input validation
- Access control checks
- State invariant checks


### 3. `Result<T, E>`

`Result` is an enum that represents either a successful value (`Ok`) or an error (`Err`).

**Definition:**
```cairo
enum Result<T, E> {
    Ok: T,
    Err: E,
}
```

**When to use it:**
- When a function can fail in an expected, recoverable way
- When the caller should decide how to handle the failure
- When you want to chain operations that might fail

**Example:**
```cairo
fn divide(a: u64, b: u64) -> Result<u64, felt252> {
    if b == 0 {
        Result::Err('Division by zero')
    } else {
        Result::Ok(a / b)
    }
}
```


### 4. `Option<T>`

`Option` represents a value that may or may not exist.

**Definition:**
```cairo
enum Option<T> {
    Some: T,
    None,
}
```

**When to use it:**
- When a value might not exist (e.g., looking up a key in a map)
- When absence of a value is a valid, expected case (not an error)

**Example:**
```cairo
fn find_user(id: u64) -> Option<User> {
    if id == 0 {
        Option::None
    } else {
        Option::Some(User { id })
    }
}
```


### 5. `unwrap()` and `expect()`

Both are used to extract a value from `Option` or `Result`. If the value is `None` or `Err`, they panic.

```cairo
let value = some_result.unwrap();               // panics with generic message
let value = some_result.expect('custom error'); // panics with your message
```

**Use `expect` over `unwrap`** — it gives you a meaningful error message.



### 6. `match` for Pattern Matching

`match` lets you handle each variant of `Result` or `Option` explicitly. This is the safest and most explicit approach.

```cairo
match divide(10, 0) {
    Result::Ok(val) => // use val,
    Result::Err(e) => // handle error e,
}
```


### 7. `?` Operator (Error Propagation)

The `?` operator is shorthand for propagating errors up the call stack. If the result is `Err`, it returns early from the current function with that error. This keeps error-handling code clean without deep nesting.

```cairo
fn process(a: u64, b: u64) -> Result<u64, felt252> {
    let result = divide(a, b)?; // returns Err early if divide fails
    Result::Ok(result * 2)
}
```


## Access Control Pattern (Common in Smart Contracts)

A very common pattern in Cairo smart contracts is using `assert` for access control. This pattern is used in OpenZeppelin's Cairo contracts and is considered standard practice.

```cairo
fn only_owner(caller: ContractAddress, owner: ContractAddress) {
    assert(caller == owner, 'Caller is not the owner');
}
```


## Custom Error Types

Instead of using raw `felt252` strings as errors, you can define your own error enum.Then use it with `Result<T, MyError>`. This makes your errors structured, readable and easier to handle for callers.

```cairo
#[derive(Drop)]
enum MyError {
    DivisionByZero,
    Overflow,
    Unauthorized,
}
```


## Resources

- [Cairo Book] - Error Handling , Enums and Pattern Matching
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)
- [Starknet Foundry Docs](https://foundry-rs.github.io/starknet-foundry/)