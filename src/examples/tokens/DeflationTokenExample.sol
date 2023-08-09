// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "../../contracts/CsrRewardsERC20.sol";

contract DeflationTokenExample is ERC20, CsrRewardsERC20 {
    uint public immutable deflationBasisPoints;

    constructor(
        string memory _name, 
        string memory _symbol,
        bool _usingFee,
        uint8 _feeBasisPoints,
        uint _deflationBasisPoints,
        uint _supply
    ) ERC20(_name, _symbol) CsrRewardsERC20(_usingFee, _feeBasisPoints) {
        deflationBasisPoints = _deflationBasisPoints;

        _mint(msg.sender, _supply);
    }

    function _afterTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _burnAmount(uint amount) internal virtual returns (uint amountToTransfer) {
        uint amountToBurn = amount * deflationBasisPoints / 10000;
        amountToTransfer = amount - amountToBurn;
        _burn(msg.sender, amountToBurn);
    }  

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        uint amountToTransfer = _burnAmount(amount);
        super.transfer(to, amountToTransfer);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        uint amountToTransfer = _burnAmount(amount);
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amountToTransfer);
        return true;
    }
}
