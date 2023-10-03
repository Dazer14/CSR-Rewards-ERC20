## Scalar Analysis
- Choosing the optimal value for the SCALAR is critical and varies on a token by token basis.
- It is responsible for ensuring reward calculation precision but needs to be constrained within a specific range to prevent overflow on intermediate calculations.
- A rough rule of thumb is that the SCALAR should be proportional to the total supply range considering the absolute numeric value of the supply without decimals. 
- It's very critical to consider possible reward sizes from CSR earnings. Possible minimal  values could drastically decrease after migrating to an L2, which would require increasing the SCALAR to maintain precision.

---
## Testing 
- Assuming these factors:
    - Total supply range of 1 token to 1000000000000000000 (billion billion) tokens
    - 18 decimals
    - CANTO reward input ranging between ~ 1e12 and 1e24 (dust to 10k CANTO)
- Tests using a SCALAR value of 1e36 pass basic operations.
