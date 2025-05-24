const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying LimitOrderDEX contract with account:", deployer.address);

  const LimitOrderDEX = await hre.ethers.getContractFactory("LimitOrderDEX");
  const dex = await LimitOrderDEX.deploy();

  await dex.deployed();

  console.log("LimitOrderDEX deployed to:", dex.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
