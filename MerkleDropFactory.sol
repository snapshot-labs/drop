// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MerkleDrop.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MerkleFactory {
    address immutable merkleDropImplementation;

    constructor() public {
        merkleDropImplementation = address(new MerkleDrop());
    }

    function createMerkleDrop(IERC20 _token) external returns (address) {
        address clone = Clones.clone(merkleDropImplementation);
        MerkleDrop(clone).initialize(_token ,msg.sender);
        return clone;
    }
}