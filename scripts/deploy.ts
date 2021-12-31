import { ethers } from "hardhat";

async function main() {
  const MyToken = await ethers.getContractFactory("MyToken");
  const MyTokenReceipt = await MyToken.deploy();
  await MyTokenReceipt.deployed();

  const MerkleDrop = await ethers.getContractFactory("MerkleDrop");
  const MerkleDropReceipt = await MerkleDrop.deploy();
  await MerkleDropReceipt.deployed();

  const MerkleDropERC721 = await ethers.getContractFactory("MerkleDropERC721");
  const MerkleDropERC721Receipt = await MerkleDropERC721.deploy();
  await MerkleDropERC721Receipt.deployed();

  console.log({
    MyToken: MyTokenReceipt.address,
    MerkleDrop: MerkleDropReceipt.address,
    MerkleDropERC721: MerkleDropERC721Receipt.address,
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
