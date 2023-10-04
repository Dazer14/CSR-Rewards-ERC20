## Scalar Analysis
- Choosing a safe and more ideal value for the scalar is important and varies on a token by token basis.
- The scalar is responsible for ensuring reward calculation precision but needs to be constrained below an upper bound that could lead to overflow in intermediate calculations.
- The overflow concern would occur when multiplying the accumulator (scalar multiple) by a balance value, so have to consider total supply amount in choosing the scalar.

---
### Testing 
- Using a scalar value of 1e36 passes basic operations, assuming these factors:
    - Total supply range of 1 token to 1 billion tokens, 18 decimals
    - CANTO reward input ranging between 1 wei and 1e24 (10k CANTO)
- Modify all variables needed to simulate your token and run the tests
    - You can update scalar, supply range and reward distribution range in test files

---
### Current Thoughts
- A reasonably sized total supply should not run into issues with overflow for a wide range of scalar values. Just need to ensure enough precision so can keep to low-mid range.