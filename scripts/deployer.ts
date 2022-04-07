// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre from "hardhat";

async function main() {
  const RemixV1 = await hre.ethers.getContractFactory("RemixUUPSV1");
  const v1ProxyUUPS = await hre.upgrades.deployProxy(RemixV1, [], {
    kind: "uups",
  });

  await v1ProxyUUPS.deployed();
  console.log("Remix reward deployed to Ropsten:", v1ProxyUUPS.address);

  setTimeout(async () => {
    const RemixV2 = await hre.ethers.getContractFactory("RemixUUPSV2");
    const v2ProxyUUPS = await hre.upgrades.upgradeProxy(v1ProxyUUPS, RemixV2);

    await v2ProxyUUPS.deployed();
    console.log("Upgrade successful!", v1ProxyUUPS);
  }, 10000);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
