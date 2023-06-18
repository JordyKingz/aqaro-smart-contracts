import { ethers } from "hardhat";
import {transferTokensToPresaleContract} from "./helpers/helpers";

async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  const contractFactory = await ethers.getContractFactory("Aqaro");
  const contract = await contractFactory.deploy(deployer.address);

  await contract.deployed();

  console.log(`aqaro: ${contract.address}`);

  const mortgagePool = await ethers.getContractFactory("MortgagePool");
  const mortgage = await mortgagePool.deploy(deployer.address);
  await mortgage.deployed();
  console.log(`mortgage pool: ${mortgage.address}`);

  const mortgageFactory = await ethers.getContractFactory("MortgageFactory");
  const mortgageFactoryContract = await mortgageFactory.deploy(deployer.address);
  await mortgageFactoryContract.deployed();
  console.log(`mortgage factory: ${mortgageFactoryContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
