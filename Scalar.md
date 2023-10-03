## Scalar Analysis
- Choosing a safe and more ideal value for the scalar is important and varies on a token by token basis.
- scalar is responsible for ensuring reward calculation precision but needs to be constrained below an upper bound that could lead to overflow in intermediate calculations.
- A rough rule of thumb is that scalar should be increased to accomodate the upper end of the total supply range considering the absolute numeric value of the supply without decimals. 
- It's very critical to consider possible reward sizes from CSR earnings. Possible minimal  values could drastically decrease after migrating to an L2, which would require increasing the scalar to maintain precision.

---
### Testing 
- Using a scalar value of 1e42 passes basic operations, assuming these factors:
    - Total supply range of 1 token to 1 billion tokens, 18 decimals
    - CANTO reward input ranging between 1 wei and 1e24 (10k CANTO)
- Modify all variables needed to simulate your token and run the tests

---
### Current Conclusions
- Favor precision above overflow concern 
- It is ok to use a larger value for scalar
- Accumulator should not realistically grow into overflow range
- It's better to ensure precision for accumulated rewards