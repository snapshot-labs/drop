// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MerkleDrop.sol";

contract MerkleFactory {
    MerkleDrop[] public drops;
    event CreateDrop(address dropAddress);

    function createDrop(
        address _templateAddress,
        address _tokenAddress,
        bytes32 _merkleRoot,
        uint256 _expireTimestamp
    ) external returns (MerkleDrop drop) {
        drop = MerkleDrop(Clones.clone(_templateAddress));
        drop.init(msg.sender, _tokenAddress, _merkleRoot, _expireTimestamp);
        drops.push(drop);
        emit CreateDrop(address(drop));
    }

    function getAllMerkleDrops() external view returns (MerkleDrop[] memory) {
        return drops;
    }
}
