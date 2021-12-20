const hre = require("hardhat");
const { expect } = require("chai");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

const sampleData: { string: string } = require("./sample-data.json");

async function deploy(name: any, ...params: any) {
  const Contract = await hre.ethers.getContractFactory(name);
  return await Contract.deploy(...params).then((f: any) => f.deployed());
}

function hashToken(account: string, value: string) {
  return Buffer.from(
    hre.ethers.utils
      .solidityKeccak256(["address", "uint256"], [account, value])
      .slice(2),
    "hex"
  );
}

describe("Create Factory and test", function () {
  let factory: any;
  before(async function () {
    // We need to deploy one contract and make all other child contracts act as proxies
    // that delegate calls to the first child contract
    const deployedContract = await deploy("MerkleDrop");
    factory = await deploy("MerkleFactory", deployedContract.address);
    this.accounts = await hre.ethers.getSigners();
    this.merkleTree = new MerkleTree(
      Object.entries(sampleData).map((data: any) =>
        hashToken(data[0], data[1])
      ),
      keccak256,
      { sortPairs: true }
    );
  });

  describe("Create a merkle drop and claim tokens", function () {
    let deployedToken: any;
    let contractOne: any;
    before(async function () {
      // Test token
      deployedToken = await deploy("MyToken");
      // Create a new contract from factory contract
      await factory.createMerkleDrop(
        deployedToken.address,
        500000,
        this.merkleTree.getHexRoot(),
        900 // end time in seconds
      );
      const createdMerkleDrops = await factory.getAllMerkleDrops();
      contractOne = createdMerkleDrops[0];
      // Transfer token to the newly created merkle drop contract
      await deployedToken.transfer(createdMerkleDrops[0], 500000);
    });

    for (const [account, value] of Object.entries(sampleData)) {
      it("element", async function () {
        /**
         * Create merkle proof (anyone with knowledge of the merkle tree)
         */
        const proof = this.merkleTree.getHexProof(hashToken(account, value));
        const deployedMerkleContract = await hre.ethers.getContractAt(
          "MerkleDrop",
          contractOne
        );
        /**
         * Claims token using merkle proof
         */
        await deployedMerkleContract.claim(account, value, proof);
        console.log(
          "Token available in account %s is",
          account,
          await deployedToken.balanceOf(account)
        );
      });
    }
    after(async function () {
      await expect(factory.claimRemainingToken(contractOne)).to.be.revertedWith(
        "Drop not ended yet!"
      );
    });
  });
});
