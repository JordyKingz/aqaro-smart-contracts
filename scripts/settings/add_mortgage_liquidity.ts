import {ethers} from "hardhat";


let aqaroAddress: string; // propertyFactory
let mortgagePoolAddress: string;
let mortgageFactoryAddress: string;
let aqaroTokenAddress: string;
let aqaroEarlySaleAddress: string;
let aqaroPresaleAddress: string;

aqaroAddress = process.env.AQARO || "";
mortgagePoolAddress = process.env.MORTGAGE_POOL || "";
mortgageFactoryAddress = process.env.MORTGAGE_FACTORY || "";
aqaroTokenAddress = process.env.AQARO_TOKEN || "";
aqaroEarlySaleAddress = process.env.AQARO_EARLY_SALE || "";
aqaroPresaleAddress = process.env.AQARO_PRESALE || "";

if (aqaroAddress === "") {
  throw new Error("Environment variables AQARO must be present");
}
else if (mortgagePoolAddress === "") {
  throw new Error("Environment variables MORTGAGE_POOL must be present");
}
else if (mortgageFactoryAddress === "") {
  throw new Error("Environment variables MORTGAGE_FACTORY must be present");
}
else if (aqaroTokenAddress === "") {
  throw new Error("Environment variables AQARO_TOKEN must be present");
}
else if (aqaroPresaleAddress === "") {
  throw new Error("Environment variables AQARO_PRESALE must be present");
}

let aqaro: any;
let mortgagePool: any;
let aqaroToken: any;
let aqaroPresale: any;
let mortgageFactoryInstance: any;
let aqaroEarlySale: any;

async function main() {
  // get signers
  const [
    deployer,
    alice,
    bob,
    charlie,
    dave,
    eve] = await ethers.getSigners();

  // add mortgage liquidity
  const mortgagePoolFactory = await ethers.getContractFactory("MortgagePool");
  mortgagePool = await mortgagePoolFactory.attach(`${mortgagePoolAddress}`);
  await addMortgageLiquidity(alice, 250);
  await addMortgageLiquidity(bob, 200);
  await addMortgageLiquidity(eve, 100);

  // check eth balance of mortgagePool
  const mortgagePoolBalance = await ethers.provider.getBalance(mortgagePool.address);
  console.log(`mortgage pool balance: ${ethers.utils.formatEther(mortgagePoolBalance)}ETH`);
}

async function addMortgageLiquidity(user: any, amount: number) {
  await mortgagePool
    .connect(user)
    .provideMortgageLiquidity({value: ethers.utils.parseEther(`${amount}`)});

  console.log(`added ${amount} ETH to mortgage pool by ${user.address}`);
}

async function buyEarlySaleTokens(user: any, amount: number) {
  const tokenPrice = 0.000125;
  const ethPrice = Number(amount * tokenPrice).toFixed(4);

  await aqaroEarlySale
    .connect(user)
    .investInAqaro(
      ethers.utils.parseUnits(`${amount}`, 18),
      {value: ethers.utils.parseEther(`${ethPrice}`)}
    );

  console.log(`bought ${amount} AQARO tokens by ${user.address}`);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
