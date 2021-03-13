// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


abstract contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}


contract TokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    
    constructor(address token) public {
        stakeToken = IERC20(token);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakeToken.safeTransfer(msg.sender, amount);
    }
}


contract RewardPool is TokenWrapper, IRewardDistributionRecipient {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
     
    IERC20 public rewardToken;
    uint256 public duration = 10 days;
    uint256 public startTime = 0; 
    uint256 public periodFinish = 0;
    uint256 private rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    
    constructor (
        address _stakeToken,
        address _rewardToken,
        uint256 _starttime,
        uint256 _duration
    )
        public
        TokenWrapper(_stakeToken)
    {
        rewardToken = IERC20(_rewardToken);
        startTime = _starttime;
        duration = _duration;
        periodFinish = startTime.add(duration);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        uint256 reward = balanceOf(account)
                    .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                    .div(1e18)
                    .add(rewards[account]);
        return reward;
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) checkStart checkFinish { 
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            uint256 newReward = reward.add(leftover);
            rewardRate = newReward.div(duration);
        }
        rewardToken.transferFrom(msg.sender, address(this), reward);
        // rewardToken.mint(address(this), reward);
        // periodFinish = block.timestamp.add(duration);
        // startTime = block.timestamp;
        // lastUpdateTime = block.timestamp;
        lastUpdateTime = startTime;
        periodFinish = startTime.add(duration);
        emit RewardAdded(reward);
    }

    modifier checkFinish() {
        require(block.timestamp < periodFinish, "already finished");
        _;
    }
    modifier checkStart() {
        require(block.timestamp > startTime, "not start");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}

// reward token: 0x2720F428ED30b1D7BDc0959C6205a5e9b77CB77e
// stake token: 0x8dd66eefef4b503eb556b1f50880cc04416b916b
// stake pool: 0xDf429467bB7801f67fc632F29d523824E25c7B6e