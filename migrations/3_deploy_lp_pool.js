const Token = artifacts.require("Token");
const RewardPool = artifacts.require("RewardPool");

module.exports = async function (deployer, network, accounts) {
    console.log(accounts);

    // await deployer.deploy(Token, 'Test Token', 'TT');
    const token = await Token.deployed();
    console.log(token.address);
    await deployer.deploy(
        RewardPool,
        '0x85792AD831761EBEFbAdF03b2b4c99e654a071C7',
        token.address,
        1615617600,
        86400,
    );

    // const token = await Token.deployed();
    const pool = await RewardPool.deployed();
    const amount = '1000000000000000000000000';

    // await token.setMinter(accounts[0]);
    await token.mint(accounts[0], amount);
    await token.approve(pool.address, amount);

    await pool.setRewardDistribution(accounts[0]);
    return pool.notifyRewardAmount(amount);
};
