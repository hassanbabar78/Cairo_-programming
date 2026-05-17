// Topic: Error Handling in Cairo
// Name: Amna Amir
// Roll No: BSCS22059


// Enum used to make errors structured and readable.
#[derive(Drop, PartialEq)]
enum MathError {
    DivisionByZero,  // tried to divide by zero
    Overflow,        // result would exceed the type's max value
}


// Return either Ok(value) on success or Err(reason) on failure.
// Divides a by b. Fails if b is zero.
fn safe_divide(a: u64, b: u64) -> Result<u64, MathError> {
    if b == 0 {
        return Result::Err(MathError::DivisionByZero);
    }
    Result::Ok(a / b)
}

// Multiplies two u8 values. Fails if the result would overflow u8 (max 255).
fn safe_multiply(a: u8, b: u8) -> Result<u8, MathError> {
    if a != 0 && b > (255_u8 / a) {
        return Result::Err(MathError::Overflow);
    }
    Result::Ok(a * b)
}


// Returns the first element of the array, or None if the array is empty using Option<T>
fn first_element(arr: @Array<u64>) -> Option<u64> {
    if arr.len() == 0 {
        Option::None
    } else {
        Option::Some(*arr[0])
    }
}


// Deducts amount from sender_balance. Panics if amount is zero or balance is insufficient using assert(condition, message)
fn transfer(sender_balance: u64, amount: u64) -> u64 {
    assert(amount > 0, 'Amount must be positive');
    assert(sender_balance >= amount, 'Insufficient balance');
    sender_balance - amount
}


// Validates age using panic-based error handling.
fn validate_age(age: u8) {
    if age > 150 {
        panic!("Age value is unrealistic");
    }
    // If we reach here, age is acceptable
}


// Uses expect() for error handling and provides a useful panic message.
fn demo_expect() -> u64 {
    // We know 10/2 cannot fail, so expect() is safe here
    safe_divide(10, 2).expect('Unexpected division failure')
}


// Uses match to safely handle every possible Result case.
fn demo_match(a: u64, b: u64) -> u64 {
    match safe_divide(a, b) {
        Result::Ok(value) => value,
        Result::Err(err) => {
            match err {
                MathError::DivisionByZero => 0_u64, // fallback to 0
                MathError::Overflow => 0_u64,
            }
        },
    }
}


// ? Operator 
// If a Result is Err ? returns that Err from the current function.
fn compute(a: u64, b: u64, c: u8, d: u8) -> Result<u64, MathError> {
    // If safe_divide fails, compute() immediately returns that Err
    let div_result = safe_divide(a, b)?;

    // If safe_multiply fails, compute() immediately returns that Err
    let mul_result = safe_multiply(c, d)?;

    // Both succeeded — combine and return
    Result::Ok(div_result + mul_result.into())
}



use starknet::ContractAddress;

fn only_owner(caller: ContractAddress, owner: ContractAddress) {
    // Panics and reverts all state if caller is not the owner
    assert(caller == owner, 'Caller is not the owner');
}


// A minimal Starknet contract that combines all error handling
#[starknet::interface]
trait IVault<TContractState> {
    fn deposit(ref self: TContractState, amount: u64);
    fn withdraw(ref self: TContractState, amount: u64) -> Result<u64, felt252>;
    fn get_balance(self: @TContractState) -> u64;
}

#[starknet::contract]
mod Vault {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        balance: u64,
    }

    #[abi(embed_v0)]
    impl VaultImpl of super::IVault<ContractState> {

        // Deposit: uses assert for hard requirement (no zero deposits)
        fn deposit(ref self: ContractState, amount: u64) {
            assert(amount > 0, 'Deposit must be positive');
            let current = self.balance.read();
            self.balance.write(current + amount);
        }

        // Withdraw: uses Result for expected failure (not enough balance)
        fn withdraw(ref self: ContractState, amount: u64) -> Result<u64, felt252> {
            assert(amount > 0, 'Withdraw must be positive');
            let current = self.balance.read();
            if current < amount {
                // This is a recoverable, expected failure — use Result
                return Result::Err('Insufficient balance');
            }
            let new_balance = current - amount;
            self.balance.write(new_balance);
            Result::Ok(new_balance)
        }

        fn get_balance(self: @ContractState) -> u64 {
            self.balance.read()
        }
    }
}


//testing
#[cfg(test)]
mod tests {
    use super::{
        safe_divide, safe_multiply, first_element,
        transfer, compute, demo_expect, demo_match, MathError
    };

    // --- Result tests ---

    #[test]
    fn test_divide_success() {
        assert(safe_divide(10, 2) == Result::Ok(5_u64), 'Expected Ok(5)');
    }

    #[test]
    fn test_divide_by_zero_returns_err() {
        match safe_divide(10, 0) {
            Result::Ok(_) => panic!("Should have been Err"),
            Result::Err(e) => assert(e == MathError::DivisionByZero, 'Wrong error'),
        }
    }

    #[test]
    fn test_multiply_success() {
        assert(safe_multiply(3, 4) == Result::Ok(12_u8), 'Expected Ok(12)');
    }

    #[test]
    fn test_multiply_overflow_returns_err() {
        match safe_multiply(200, 200) {
            Result::Ok(_) => panic!("Should have been Err"),
            Result::Err(e) => assert(e == MathError::Overflow, 'Wrong error'),
        }
    }

    // --- Option tests ---

    #[test]
    fn test_first_element_empty_array() {
        let arr: Array<u64> = ArrayTrait::new();
        assert(first_element(@arr) == Option::None, 'Expected None');
    }

    #[test]
    fn test_first_element_returns_value() {
        let mut arr: Array<u64> = ArrayTrait::new();
        arr.append(42);
        assert(first_element(@arr) == Option::Some(42_u64), 'Expected Some(42)');
    }

    // --- assert tests ---

    #[test]
    fn test_transfer_success() {
        assert(transfer(100, 30) == 70, 'Expected 70');
    }

    #[test]
    #[should_panic(expected: ('Insufficient balance',))]
    fn test_transfer_panics_on_insufficient_balance() {
        transfer(50, 100); // should panic
    }

    #[test]
    #[should_panic(expected: ('Amount must be positive',))]
    fn test_transfer_panics_on_zero_amount() {
        transfer(100, 0); // should panic
    }

    // --- expect / match tests ---

    #[test]
    fn test_demo_expect_returns_correct_value() {
        assert(demo_expect() == 5, 'Expected 5');
    }

    #[test]
    fn test_demo_match_division_by_zero_returns_zero() {
        // match falls back to 0 on error
        assert(demo_match(10, 0) == 0, 'Expected 0 fallback');
    }

    // --- ? operator tests ---

    #[test]
    fn test_compute_success() {
        // safe_divide(10,2)=5, safe_multiply(3,4)=12, total=17
        assert(compute(10, 2, 3, 4) == Result::Ok(17_u64), 'Expected Ok(17)');
    }

    #[test]
    fn test_compute_propagates_division_error() {
        match compute(10, 0, 3, 4) {
            Result::Ok(_) => panic!("Should have been Err"),
            Result::Err(e) => assert(e == MathError::DivisionByZero, 'Wrong error'),
        }
    }

    #[test]
    fn test_compute_propagates_overflow_error() {
        match compute(10, 2, 200, 200) {
            Result::Ok(_) => panic!("Should have been Err"),
            Result::Err(e) => assert(e == MathError::Overflow, 'Wrong error'),
        }
    }
}
