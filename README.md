## CSR Rewards ERC20

- This contract is a hybrid ERC20 with Synthetix StakingRewards.sol logic included to provide accounting of non contract holders and evenly distribute CSR to them
- "Staking" and "Withdraw" logic occurs in a token transfer hook, only processing transfers to and from non contract addresses
- Holders can claim CSR rewards at any time and will receive all rewards when transferring out
- Contract is ownerless and the use of a 1% caller kickback when calling the turnstile claim will aid in ongoing reward accumulation

### Reward eligible contracts
- It is possible for a contract to be eligible for CSR reward accumulation and claiming 
- If a contract has a constructor routine that transfers some tokens in, it will perform a one time bypass of the contract check and be registered in the reward distribution accounting
- Any amount transferred out from the contract will reduce its reward eligible balance with no possibility to increase
- Attempting to use this pattern should be done carefully and NOT include logic to further accumulate tokens after deploy, only claiming and selling

### Use
- Testing/auditing still needed, not recommended for use yet