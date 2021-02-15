const PRA = artifacts.require("PRA");
const StakingRewardLockFactory = artifacts.require("StakingRewardsLockFactory");

module.exports = function(deployer, network) {
  console.log(`network is ${network}`)
  deployer.deploy(PRA).then(function() {
    return deployer.deploy(StakingRewardLockFactory, PRA.address, 1619982000);
  });
};
