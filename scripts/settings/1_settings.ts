import {ethers} from "hardhat";


let aqaroAddress: string; // propertyFactory
let mortgagePoolAddress: string;
let mortgageFactoryAddress: string;
let aqaroTokenAddress: string;
let aqaroPresaleAddress: string;

aqaroAddress = process.env.AQARO || "";
mortgagePoolAddress = process.env.MORTGAGE_POOL || "";
mortgageFactoryAddress = process.env.MORTGAGE_FACTORY || "";
aqaroTokenAddress = process.env.AQARO_TOKEN || "";
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

  // purchase presale tokens
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  aqaroToken = await aqaroTokenFactory.attach(`${aqaroTokenAddress}`);
  const aqaroPresaleFactory = await ethers.getContractFactory("AqaroPresale");
  aqaroPresale = await aqaroPresaleFactory.attach(`${aqaroPresaleAddress}`);
  await buyPresaleTokens(alice, 10000);
  await buyPresaleTokens(bob, 20000);
  await buyPresaleTokens(dave, 5000);
  console.log(`aqaro presale balance: ${ethers.utils.formatEther(await aqaroToken.balanceOf(aqaroPresale.address))}AQARO`);
  console.log(`ETH balance of aqaro presale: ${ethers.utils.formatEther(await ethers.provider.getBalance(aqaroPresale.address))}ETH`);

  // list property
  const aqaroFactory = await ethers.getContractFactory("Aqaro");
  aqaro = await aqaroFactory.attach(`${aqaroAddress}`);

  const createProp = {
    addr: {
      street: "Muntinglaan 44",
      city: "Groningen",
      state: "Groningen",
      country: "nl",
      zip: "9727"
    },
    askingPrice: 100
  }

  // check emit PropertyCreated event
  aqaro.on("PropertyCreated", (propertyAddress: any, owner: any, propertyCount: any) => {
    console.log(`PropertyCreated: ${propertyAddress}`);
    console.log(`owner: ${owner}`);
    console.log(`propertyCount: ${propertyCount.toString()}`);
  });
  const result = await aqaro.connect(charlie).createProperty(createProp);
  console.log({result});


}

async function addMortgageLiquidity(user: any, amount: number) {
  await mortgagePool
    .connect(user)
    .provideMortgageLiquidity({value: ethers.utils.parseEther(`${amount}`)});

  console.log(`added ${amount} ETH to mortgage pool by ${user.address}`);
}

async function buyPresaleTokens(user: any, amount: number) {
  const tokenPrice = 0.0003;
  const ethPrice = Number(amount * tokenPrice).toFixed(4);

  await aqaroPresale
    .connect(user)
    .buyAqaroToken(
      ethers.utils.parseUnits(`${amount}`, 18),
      {value: ethers.utils.parseEther(`${ethPrice}`)}
    );

  console.log(`bought ${amount} AQARO tokens by ${user.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
