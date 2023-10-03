// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "@forge/Test.sol";

import {CsrRewardsERC20, ERC20} from "src/contracts/CsrRewardsERC20.sol";
import {TurnstileInterface} from "src/contracts/TurnstileInterface.sol";

interface TurnstileOwnerControls {
    function distributeFees(uint256 _tokenId) external payable;
}

contract TestToken is ERC20, CsrRewardsERC20 {
    constructor(
        string memory _name, 
        string memory _symbol
    ) ERC20(_name, _symbol) CsrRewardsERC20() {}

    function _afterTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._afterTokenTransfer(from, to, amount);
    }
}

contract EligibilityFaucet {
    address public immutable csrRewardsToken;

    constructor(address _csrRewardsToken) {
        csrRewardsToken = _csrRewardsToken;
    }

    function drip() external {
        (bool success,) = csrRewardsToken.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, 1));
        require(success, "EligibilityFaucet: Transfer failed");
    }
}

contract RewardEligibleContract {
    constructor(address _faucet) {
        // Use a low-level call to drip
        (bool success,) = _faucet.call(abi.encodeWithSignature("drip()"));
        require(success, "RewardEligibleContract: Drip failed");
    }
}

contract ExistingContract {}

contract Base is Test {
    TestToken public token;

    address public turnstile = address(0xEcf044C5B4b867CFda001101c617eCd347095B44);
    address public turnstileOwner = address(0xC27338c453067b437471aFBCE792704D816112c6);
    address public origin = address(0x555);
    address public user1 = address(0x111);
    address public user2 = address(0x222);
    address public user3 = address(0x333);

    address public faucet;
    address public existingContract;
    address public rewardEligibleContract;

    uint256 public constant MIN_TOTAL_SUPPLY = 1e18;
    // CANTO - 1 Billion - 1_000_000_000e18
    // Billion Billion - 1_000_000_000_000_000_000e18
    // Trillion Trillion - 1_000_000_000_000_000_000_000_000e18
    uint256 public constant MAX_TOTAL_SUPPLY = 1_000_000_000e18;

    uint16 public constant MAX_FRACTION = type(uint16).max;
    uint16 public constant MIN_FRACTION = 0;
    // Doing (rewards * balance / total supply) on some fuzz runs loses exact precision
    // Checking an extremely close value instead
    uint256 public constant REWARD_DELTA = 0.00000001e18; // 99.999999% of expected value
    // Reward distribution fuzz range
    // This is testing as low as a manually transfered single wei of CANTO
    uint256 public constant DISTRIBUTION_MIN = 1;
    uint256 public constant DISTRIBUTION_MAX = 1e24; 
    uint256 public constant DIRECT_SEND_MAX = 1_000_000e18;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("canto"));
        
        token = new TestToken("Test", "TEST");

        vm.deal(turnstileOwner, type(uint256).max);

        // Deploy faucet and provide with single wei, keep out of supply accounting
        // Reward eligible setup function will transfer back
        faucet = address(new EligibilityFaucet(address(token)));
        deal(address(token), faucet, 1, false);

        rewardEligibleContract = _setUpRewardEligibleContract();
        existingContract = _setUpExistingContract();
    }

    function _setUpToken(uint256 _totalSupply, uint16 fraction1, uint16 fraction2) internal {
        vm.assume(_totalSupply >= MIN_TOTAL_SUPPLY && _totalSupply <= MAX_TOTAL_SUPPLY);

        // Validate fractions
        _validateFraction(fraction1);
        _validateFraction(fraction2);

        // totalSupply = _totalSupply;
        uint256 remainingSupply = _totalSupply;

        // Calculate user balances based on fractions
        uint256 user1Balance = remainingSupply * fraction1 / MAX_FRACTION;
        remainingSupply -= user1Balance;
        uint256 user2Balance = remainingSupply * fraction2 / MAX_FRACTION;
        remainingSupply -= user2Balance;

        // Deal then transfer to make sure after transfer hook is run
        // Only these users will have an eligible account initially
        deal(address(token), origin, _totalSupply, true);
        vm.startPrank(origin);
        token.transfer(user1, user1Balance);
        token.transfer(user2, user2Balance);
        token.transfer(user3, remainingSupply); // Remaining supply goes to user3
        vm.stopPrank();
    }

    // Helpers

    function _distributeAmount(uint256 amount) internal {
        vm.assume(amount < DISTRIBUTION_MAX && amount > DISTRIBUTION_MIN);
        vm.startPrank(turnstileOwner);
        TurnstileOwnerControls(turnstile).distributeFees{value:amount}(token.csrID());
        vm.stopPrank();
    }

    function _validateFraction(uint16 fraction) internal pure {
        vm.assume(fraction > MIN_FRACTION && fraction < MAX_FRACTION);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        vm.prank(from);
        token.transfer(to, amount);
    }

    function _distributeAndWithdraw(uint256 amount) internal {
        _distributeAmount(amount);
        token.withdrawFromTurnstile();
    }

    function _rewardsFromDistributionByEligibleBalance(uint256 amountToDistribute, address user) internal view returns (uint256) {
        return amountToDistribute * token.rewardEligibleBalanceOf(user) / token.totalRewardEligibleSupply();
    }

    function _amountToTransfer(address account, uint16 fraction) internal view returns (uint256) {
        return token.balanceOf(account) * fraction / MAX_FRACTION;
    }

    function _sendCANTOToTokenContract(uint256 amountToSend) internal {
        vm.assume(amountToSend < DIRECT_SEND_MAX);
        vm.deal(address(this), amountToSend);
        (bool success,) = payable(address(token)).call{value: amountToSend}("");
        require(success, "CANTO send failed");
    }

    function _setUpRewardEligibleContract() internal returns (address rewardEligibleContractAddress) {
        rewardEligibleContractAddress = address(new RewardEligibleContract(faucet));
        _transfer(rewardEligibleContractAddress, faucet, 1);
    }

    function _setUpExistingContract() internal returns (address existingContractAddress) {
        existingContractAddress = address(new ExistingContract());
    }
    

    // Asserts

    function _assertApproxRewardsFromDistribution(address user, uint256 amountToDistribute) internal {
        uint256 rewardsFromDistribution = _rewardsFromDistributionByEligibleBalance(amountToDistribute, user);
        assertApproxEqRel(token.earned(user), rewardsFromDistribution, REWARD_DELTA);
    }

    function _assertBalance(address user, uint256 expectedBalance) internal {
        assertEq(token.balanceOf(user), expectedBalance);
    }

    function _assertRewardEligibleBalance(address user, uint256 expectedBalance) internal {
        assertEq(token.rewardEligibleBalanceOf(user), expectedBalance);
    }

}
