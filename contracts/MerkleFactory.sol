// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MerkleDrop.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract MerkleFactory {
    MerkleDrop[] public drops;
    address private masterContract;

    constructor(address _masterContract) {
        masterContract = _masterContract;
    }

    event MerkleContractCreated(address contractAddress);

    function createMerkleDrop(
        ERC20 token,
        uint256 balance,
        bytes32 merkleRoot,
        uint256 expiresInSeconds
    ) external {
        MerkleDrop drop = MerkleDrop(Clones.clone(masterContract));
        drop.init(
            token,
            balance,
            merkleRoot,
            drops.length,
            expiresInSeconds,
            msg.sender
        );
        drops.push(drop);
        emit MerkleContractCreated(address(drop));
    }

    function getAllMerkleDrops() external view returns (MerkleDrop[] memory) {
        return drops;
    }

    function disable(MerkleDrop drop) external {
        drops[drop.index()].disable(msg.sender);
    }

    function claimRemainingTokens(MerkleDrop drop) external {
        drops[drop.index()].claimTokensBack(msg.sender);
    }
}
