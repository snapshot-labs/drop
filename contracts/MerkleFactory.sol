// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ISnapshotDrop.sol";
import "./MerkleDrop.sol";

contract MerkleFactory {
    MerkleDrop[] public drops;
    event CreateDrop(address dropAddress);

    function createDrop(
        address templateAddress,
        address tokenAddress,
        bytes32 merkleRoot,
        uint256 expireTimestamp,
        bytes32 salt
    ) external returns (MerkleDrop drop) {
        drop = MerkleDrop(Clones.cloneDeterministic(templateAddress, salt));
        drop.init(msg.sender, tokenAddress, merkleRoot, expireTimestamp);
        drops.push(drop);
        emit CreateDrop(address(drop));
    }

    function getAllMerkleDrops() external view returns (MerkleDrop[] memory) {
        return drops;
    }
}
