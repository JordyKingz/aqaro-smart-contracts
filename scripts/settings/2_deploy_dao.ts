import { ethers } from "hardhat";

let mortgageFactoryAddress = process.env.MORTGAGE_FACTORY || "";

if (mortgageFactoryAddress === "") {
  throw new Error("Environment variables AQARO must be present");
}
async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  const contractFactory = await ethers.getContractFactory("DaoFactory");
  const contract = await contractFactory.deploy();

  await contract.deployed();

  console.log(`'dao factory address:': ${contract.address}`);
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
