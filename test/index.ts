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
    let contractOne: any;
    before(async function () {
      const erc20DropTemplate = await deploy("MerkleDrop");
      // Test token
      deployedToken = await deploy("MyToken");
      // Create a new contract from factory contract
      const test = await factory.createDrop(
        erc20DropTemplate.address,
        deployedToken.address,
        this.merkleTree.getHexRoot(),
        Date.now() + 1000000
      );
      console.log("🚀 ~ file: index.ts ~ line 50 ~ test", await test.address());
      const createdMerkleDrops = await factory.getAllMerkleDrops();
      contractOne = createdMerkleDrops[0];
      console.log("🚀 ~ file: index.ts ~ line 53 ~ contractOne", contractOne);
      await deployedToken.transfer(createdMerkleDrops[0], 500000);
    });

    for (const [account, value] of Object.entries(sampleData)) {
      it("element", async function () {
        /**
         * Create merkle proof (anyone with knowledge of the merkle tree)
         */
        const proof = this.merkleTree.getHexProof(hashToken(account, value));
        const deployedMerkleDropContract = await hre.ethers.getContractAt(
          "MerkleDrop",
          contractOne
        );
        /**
         * Claims token using merkle proof
         */
        await deployedMerkleDropContract.claim(account, value, proof);
        console.log(
          "Token available in account %s is",
          account,
          await deployedToken.balanceOf(account)
        );
      });
    }
    after(async function () {
      console.log(
        "🚀 ~ Final balance before sweep",
        await deployedToken.balanceOf(
          "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
        )
      );
      const deployedMerkleDropContract = await hre.ethers.getContractAt(
        "MerkleDrop",
        contractOne
      );
      await expect(
        deployedMerkleDropContract.sweepOut(deployedToken.address)
      ).to.be.revertedWith("Drop not ended");
    });
  });
});
