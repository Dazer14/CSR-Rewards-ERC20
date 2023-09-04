// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src/Test.sol";

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

contract BaseTest is Test {
    TestToken public token;

    address public turnstile = address(0xEcf044C5B4b867CFda001101c617eCd347095B44);
    address public turnstileOwner = address(0xC27338c453067b437471aFBCE792704D816112c6);

    address public origin = address(0x555);
    address public user1 = address(0x111);
    address public user2 = address(0x222);
    address public user3 = address(0x333);
    address public user4 = address(0x444);

    uint256 public totalSupply = 4_000_000e18;
    uint256 public userBalance = totalSupply / 4;

    EligibilityFaucet public faucet;

    uint16 public constant MAX_FRACTION = 10000;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("canto"));
        
        // Testing with no withdraw call fee
        token = new TestToken("Test", "TEST");

        vm.deal(turnstileOwner, type(uint256).max);

        // Deal then transfer to make sure after transfer hook is run
        // Only these users will have an eligible account initially
        deal(address(token), origin, totalSupply, true);
        vm.startPrank(origin);
        token.transfer(user1, userBalance);
        token.transfer(user2, userBalance);
        token.transfer(user3, userBalance);
        token.transfer(user4, userBalance);
        vm.stopPrank();

        // Create faucet and provide with 10 tokens
        faucet = new EligibilityFaucet(address(token));
        deal(address(token), address(faucet), 10, true);
    }

    // Helpers

    function _distributeAmount(uint256 amount) internal {
        // Mocking a wide range of reward amounts
        vm.assume(amount < 10000e18 && amount > 1000);
        vm.startPrank(turnstileOwner);
        TurnstileOwnerControls(turnstile).distributeFees{value:amount}(token.csrID());
        vm.stopPrank();
    }

    function _transfer(address from, address to, uint256 amount) internal {
        vm.prank(from);
        token.transfer(to, amount);
    }

    function _distributeAndWithdraw(uint256 amount) internal {
        _distributeAmount(amount);
        token.withdrawFromTurnstile();
    }

    function _calculateRewardsByEligibleBalance(uint256 amountToDistribute, address user) internal view returns (uint256) {
        return amountToDistribute * token.rewardEligibleBalanceOf(user) / token.totalRewardEligibleSupply();
    }

    function _validateFraction(uint16 fraction) internal pure {
        vm.assume(fraction >= 0 && fraction <= MAX_FRACTION);
    }

    function _amountToTransfer(address account, uint16 fraction) internal view returns (uint256) {
        return token.balanceOf(account) * fraction / MAX_FRACTION;
    }

    function _transferAndDistributeMultiple(
        address from, 
        address to, 
        uint16 fractionToTransfer, 
        uint256[] memory distributionAmounts
    ) internal returns (uint256 fromRewards, uint256 toRewards) {
        _validateFraction(fractionToTransfer);

        _transfer(from, to, _amountToTransfer(from, fractionToTransfer));

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < distributionAmounts.length; i++) {
            _distributeAndWithdraw(distributionAmounts[i]);
            totalDistributed += distributionAmounts[i];
        }

        // Calculate rewards by eligible balance
        fromRewards = _calculateRewardsByEligibleBalance(totalDistributed, from);
        toRewards = _calculateRewardsByEligibleBalance(totalDistributed, to);
    }

    // Asserts

    function _assertEarnedRewards(address user, uint256 amountToDistribute) internal {
        uint256 calculatedRewards = _calculateRewardsByEligibleBalance(amountToDistribute, user);
        assertEq(token.earned(user), calculatedRewards);
    }

    function _assertBalance(address user, uint256 expectedBalance) internal {
        assertEq(token.balanceOf(user), expectedBalance);
    }

    function _assertRewardEligibleBalance(address user, uint256 expectedBalance) internal {
        assertEq(token.rewardEligibleBalanceOf(user), expectedBalance);
    }

}
