import { ethers } from "hardhat";

async function main() {
  const MyToken = await ethers.getContractFactory("MyToken");
  const MyTokenReceipt = await MyToken.deploy();
  await MyTokenReceipt.deployed();

  const MerkleFactory = await ethers.getContractFactory("MerkleFactory");
  const MerkleFactoryReceipt = await MerkleFactory.deploy();
  await MerkleFactoryReceipt.deployed();

  const MerkleDrop = await ethers.getContractFactory("MerkleDrop");
  const MerkleDropReceipt = await MerkleDrop.deploy();
  await MerkleDropReceipt.deployed();

  console.log({
    MyToken: MyTokenReceipt.address,
    MerkleFactory: MerkleFactoryReceipt.address,
    MerkleDrop: MerkleDropReceipt.address,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
