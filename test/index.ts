import { ethers } from "ethers";

const hre = require("hardhat");
const { expect } = require("chai");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

const sampleData: { string: string } = require("./sample-data.json");

async function deploy(name: any, ...params: any) {
  const Contract = await hre.ethers.getContractFactory(name);
  return await Contract.deploy(...params).then((f: any) => f.deployed());
}

function getIndex(address: string, value: string, proof: any) {
  let index = 0;
  let computedHash = ethers.utils.solidityKeccak256(
    ["address", "uint256"],
    [address, value]
  );
  for (let i = 0; i < proof.length; i++) {
    index *= 2;
    const proofElement = proof[i];
    if (computedHash <= proofElement) {
      computedHash = ethers.utils.solidityKeccak256(
        ["bytes32", "bytes32"],
        [computedHash, proofElement]
      );
    } else {
      computedHash = ethers.utils.solidityKeccak256(
        ["bytes32", "bytes32"],
        [proofElement, computedHash]
      );
      index += 1;
    }
  }
  return index;
}

function hashToken(account: string, value: string) {
  return Buffer.from(
    hre.ethers.utils
      .solidityKeccak256(["address", "uint256"], [account, value])
      .slice(2),
    "hex"
  );
}

describe("Create ERC20 Merkle Drop and test", function () {
  let factory: any;
  before(async function () {
    factory = await deploy("MerkleFactory");
    this.accounts = await hre.ethers.getSigners();
    this.merkleTree = new MerkleTree(
      Object.entries(sampleData).map((data: any) =>
        hashToken(data[0], data[1])
      ),
      keccak256,
      { sortPairs: true }
    );
  });

  describe("Claim tokens", function () {
    let deployedToken: any;
    let clonedContractAddress: any;
    before(async function () {
      const erc20DropTemplate = await deploy("MerkleDrop");
      // Test token
      deployedToken = await deploy("MyToken");
      // Create a new contract from factory contract
      await factory.createDrop(
        erc20DropTemplate.address,
        deployedToken.address,
        this.merkleTree.getHexRoot(),
        Date.now() + 1000000
      );
      const createdMerkleDrops = await factory.getAllMerkleDrops();
      clonedContractAddress = createdMerkleDrops[0];
      await deployedToken.transfer(clonedContractAddress, 500000);
    });

    it("element", async function () {
      const address = this.accounts[0].address;
      /**
       * Create merkle proof (anyone with knowledge of the merkle tree)
       */
      const proof = this.merkleTree.getHexProof(hashToken(address, "4000"));
      const deployedMerkleDropContract = await hre.ethers.getContractAt(
        "MerkleDrop",
        clonedContractAddress
      );
      const index = getIndex(address, "4000", proof);
      expect(await deployedMerkleDropContract.isClaimed(index)).to.equal(false);
      /**
       * Claims token using merkle proof
       */
      await deployedMerkleDropContract.claim("4000", proof);
      expect(await deployedMerkleDropContract.isClaimed(index)).to.equal(true);
      console.log(
        "Token available in account %s is",
        address,
        await deployedToken.balanceOf(address)
      );
    });

    after(async function () {
      const deployedMerkleDropContract = await hre.ethers.getContractAt(
        "MerkleDrop",
        clonedContractAddress
      );
      await expect(
        deployedMerkleDropContract.sweepOut(deployedToken.address)
      ).to.be.revertedWith("Drop not ended");
    });
  });
});
