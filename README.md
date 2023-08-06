## CSR Rewards ERC20

- This contract provides accounting of reward eligible holders and evenly distributes CSR to them
- Holders can claim CSR rewards at any time
- Contract is ownerless
- Caller fee paid for calling turnstile withdraw function
- Auto-whitelist for contract holders (see below) 
- Testing/auditing still needed, not mainnet ready

### Reward Eligible Contracts
- Contracts that transfer in some amount of tokens during construction become reward eligible
- Existing smart contracts are not eligible for rewards
- Custom contracts can hold this ERC20 and collect CSR 
    - Ex. Extra source of fee revenue from Collateralized positions