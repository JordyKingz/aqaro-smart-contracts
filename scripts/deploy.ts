import { ethers } from "hardhat";

async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  const contractFactory = await ethers.getContractFactory("Aqaro");
  const contract = await contractFactory.deploy(deployer.address);

  await contract.deployed();

  console.log(`${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
