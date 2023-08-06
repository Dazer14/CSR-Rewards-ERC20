## CSR Rewards ERC20

- This contract is a hybrid ERC20 with Synthetix StakingRewards.sol logic included to provide accounting of reward eligible holders and evenly distribute CSR to them
- `stake` and `withdraw` logic occurs in a token transfer hook, only processing transfers to and from reward eligible addresses
- Holders can claim CSR rewards at any time and will claim all available rewards when transferring out
- Contract is ownerless
- Caller fee paid for calling turnstile withdraw function
- Auto-whitelist for contract holders (see below) 
- Testing/auditing still needed, not mainnet ready

### Reward Eligible Contracts
- Contracts that transfer in some amount of tokens during construction become reward eligible
- Existing smart contracts are not eligible for rewards
- Custom contracts can hold this ERC20 and collect CSR 
    - Ex. Extra source of fee revenue from Collateralized positions
- This makes the token ready to deploy across defi and permissionlessly composite