## CSR Rewards ERC20

- ERC20 extension for a CSR accumulating token
- This contract provides accounting for CSR reward eligible holders and distributes CANTO accumulated from all CSR generated by the token contract
- Non contract accounts (EOA) will automatically become reward eligible when first receiving tokens
- Auto-whitelist for new contract accounts (see below) 
- Unaudited, not mainnet ready

### Reward Eligible Contracts
- New contracts that receive any amount of this token either before or during their construction become reward eligible
    - Can use faucet, buy off DEX, create2, etc...
- Existing smart contracts are not eligible for rewards
    - Manually set with access control
- Custom contracts can hold this token and collect CSR generated by the token
- Developers need to implement neccessary functions to claim rewards and transfer out
- This makes the token safe to deploy in existing contracts (pools, DEXs, etc... contracts that do not have logic to process rewards) and permissionlessly composable for contracts that intend to use the rewards

### Use
- Refer to SimpleTokenExample.sol for basic implementation
- Need to override `_afterTokenTransfer`
- **Important** - Need to choose appropriate `scalar` value, refer to Scalar.md
- Excessively large total supply amounts could lead to overflow issues
    - Take caution beyond trillion trillion w/ 18 decimals