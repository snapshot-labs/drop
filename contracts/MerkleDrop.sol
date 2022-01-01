// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "./IDrop.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleDrop is IDrop, Ownable {
    using SafeERC20 for IERC20;

    address public override token;
    bytes32 public override merkleRoot;
    bool public initialized;
    uint256 public expireTimestamp;

    mapping(address => bool) public claimed;

    function init(
        address _owner,
        address _token,
        bytes32 _merkleRoot,
        uint256 _expireTimestamp
    ) external {
        require(!initialized, "Drop already initialized");
        initialized = true;
        token = _token;
        merkleRoot = _merkleRoot;
        expireTimestamp = _expireTimestamp;
        _transferOwnership(_owner);
    }

    /**
     * @dev Implementation to claim token.
     * @param _recipient Address of user who claims the drop.
     * @param _amount Amount of tokens allotcated based on voting power.
     * @param _merkleProof Proof of merkle root generated from recipient address and value
     *
     * This implementation is the way to claim tokens, that were allocated to accounts. This means
     * that the recipient and the value to claim data is converted to merkle root and given to this contract
     * at the time of deployment.
     *
     * To claim caller should pass the recipient address, amount value and proof, after verifying the
     * proof, recipient and its value were right, we transfer the tokens and mark it as claimed.
     */
    function claim(
        address _recipient,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external override {
        require(!claimed[_recipient], "Drop already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _amount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        claimed[_recipient] = true;
        IERC20(token).safeTransfer(_recipient, _amount);
        emit Claimed(_recipient, _amount);
    }

    /**
     * @dev Implementation to sweep out remaining tokens back.
     * @param _token Address of the drop token
     *
     * Only the owner of the contract can sweep all the remaining tokens back to their account.
     * The owner access is transfered from factory to deployer of the contract during initialization.
     *
     * Only after the drop expiry time, owner can sweep out the tokens.
     */
    function sweepOut(address _token) external onlyOwner {
        require(
            block.timestamp >= expireTimestamp || _token != token,
            "Drop not ended"
        );
        IERC20 tokenContract = IERC20(_token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(msg.sender, balance);
    }
}
