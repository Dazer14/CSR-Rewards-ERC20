// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TurnstileInterface} from "./TurnstileInterface.sol";

contract TurnstileRegister {
    uint256 public csrID;

    TurnstileInterface public constant TURNSTILE = TurnstileInterface(0xEcf044C5B4b867CFda001101c617eCd347095B44);

    constructor() {
        csrID = TURNSTILE.register(address(this));
    }
}
