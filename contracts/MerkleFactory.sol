// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./MerkleDrop.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./MerkleProof.sol";

contract MerkleFactory is Ownable {
    using BitMaps for BitMaps.BitMap;
    bytes32 public validatorRoot;
    
    address immutable dropImplementation;
    MerkleDrop[] public drops;
    event CreateDrop(address dropAddress);
    event CreateTickets(address batchAdress);
    BitMaps.BitMap private claimeddrop;

    constructor(bytes32[] _validatorRoot) public {
        validatorRoot = _validatorRoot;
        dropImplementation = address(new MerkleDrop());
        
    }

    function createDrop(
        address _tokenAddress,
        bytes32 _merkleRoot,
        uint256 _expireTimestamp,
        bytes32[] calldata _validatorProof,
        uint256 code
    ) public returns (MerkleDrop drop) {
        bytes32 leaf = keccak256(abi.encodePacked(code));
        (bool valid, uint256 index) = MerkleProof.verify(
            _validatorProof,
            validatorRoot,
            leaf
        );
        require(valid, "Factory: Invalid validator proof.");
        require(!isDropClaimed(index), "Factory: MerkleDrop already claimed.");
        claimeddrop.set(index);
        drop = MerkleDrop(Clones.clone(dropImplementation));
        drop.init(msg.sender, _tokenAddress, _merkleRoot, _expireTimestamp);
        drops.push(drop);
        emit CreateDrop(address(drop));
    }


    function isDropClaimed(uint256 index) public view returns (bool) {
        return claimeddrop.get(index);
    }


    function getAllMerkleDrops() external view returns (MerkleDrop[] memory) {
        return drops;
    }
}
