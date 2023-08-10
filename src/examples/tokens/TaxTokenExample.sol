// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "../../contracts/CsrRewardsERC20.sol";

/// @dev Need to pass in array of tax collectors and the tax basis points for each one
contract TaxTokenExample is ERC20, CsrRewardsERC20 {
    struct TaxCollector {
        address collector;
        uint8 taxBasisPoints;
    }

    TaxCollector[] public taxCollectors;

    constructor(
        string memory _name, 
        string memory _symbol,
        bool _usingFee,
        uint16 _feeBasisPoints,
        uint _supply,
        TaxCollector[] memory _taxCollectors
    ) ERC20(_name, _symbol) CsrRewardsERC20(_usingFee, _feeBasisPoints) {
        _mint(msg.sender, _supply);

        for (uint i = 0; i < _taxCollectors.length; ++i) {
            taxCollectors[i] = _taxCollectors[i];
        }
    }

    function _afterTokenTransfer(address from, address to, uint amount) 
        internal 
        override(ERC20, CsrRewardsERC20) 
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _processTaxes(address _from, uint _amount) internal virtual returns (uint totalAmountTaxed) {
        for (uint i = 0; i < taxCollectors.length; ++i) {
            TaxCollector memory tc = taxCollectors[i];
            uint taxAmount = _amount * tc.taxBasisPoints / 10000;
            totalAmountTaxed += taxAmount;
            _transfer(_from, tc.collector, taxAmount);
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        uint totalAmountTaxed = _processTaxes(msg.sender, amount);
        super.transfer(to, amount - totalAmountTaxed);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        uint totalAmountTaxed = _processTaxes(from, amount);
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount - totalAmountTaxed);
        return true;
    }
}
