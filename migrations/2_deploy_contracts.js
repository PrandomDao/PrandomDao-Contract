const Token = artifacts.require("Token");
const RewardPool = artifacts.require("RewardPool");

module.exports = async function (deployer, network, accounts) {
  console.log(accounts);
  
  await deployer.deploy(Token, 'Test Token', 'TT');
  await deployer.deploy(
    RewardPool,
    '0x0298c2b32eae4da002a15f36fdf7615bea3da047',
    Token.address,
    1615617600,
    86400,
  );

  const token = await Token.deployed();
  const pool = await RewardPool.deployed();
  const amount = '1000000000000000000000000';

  await token.setMinter(accounts[0]);
  await token.mint(accounts[0], amount);
  await token.approve(pool.address, amount);

  await pool.setRewardDistribution(accounts[0]);
  return pool.notifyRewardAmount(amount);
};
