// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./mocks/KukuTokenMock.sol";
import "hardhat/console.sol";


/** 
    @title IMigrator Interface
    @notice  Perform LP token migration from legacy Factory to new KukuSwap Factory.
    Take the current LP token address and return the new LP token address.
    Migrator should have full access to the caller's LP token.
    Return the new LP token address.
    
    Migrator must have allowance access to Kukuswap LP tokens.
    KukuSwap must mint EXACTLY the same amount of KukuSwap LP tokens or
    else something bad will happen.
*/

interface IMigratorChef {

    function migrate(IERC20 token) external returns (IERC20);
}

/** 
    @title  KukuFarmer is the master of farming KUKU.
*/

contract KukuFarmer is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    //// @notice Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Kukus
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accKukuPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accKukuPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    /// @notice  Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Kukus to distribute per block.
        uint256 lastRewardBlock; // Last block number that Kukus distribution occurs.
        uint256 accKukuPerShare; // Accumulated Kukus per share, times 1e12. See below.
    }
    /// @notice  The Kuku TOKEN!
    
    KukuTokenMock public Kuku;
    // Block number when bonus Kuku period ends.
    uint256 public bonusEndBlock;
    // Kuku tokens created per block.
    uint256 public KukuPerBlock;
    // Bonus muliplier for early Kuku makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Kuku farming starts.
    uint256 public startBlock;
    // The block number when Kuku farming ends.
    uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        KukuTokenMock _kuku,
        uint256 _kukuPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bonusEndBlock
    ) public {
        Kuku = _kuku;
        KukuPerBlock = _kukuPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accKukuPerShare: 0
            })
        );
    }

    /// @notice Update the given pool's Kuku allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /// @notice Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    /// @notice Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    /// @notice View function to see pending Kukus on frontend.
    function pendingKuku(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        uint256 blockNumber = currentBlockNumber();

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accKukuPerShare = pool.accKukuPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (blockNumber > pool.lastRewardBlock && lpSupply != 0) {


            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, blockNumber);
            uint256 KukuReward =
                multiplier.mul(KukuPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accKukuPerShare = accKukuPerShare.add(
                KukuReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accKukuPerShare).div(1e12).sub(user.rewardDebt);
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        uint256 blockNumber = currentBlockNumber();

        PoolInfo storage pool = poolInfo[_pid];
        if (blockNumber <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = blockNumber;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, blockNumber);

        uint256 KukuReward =
            multiplier.mul(KukuPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );

        pool.accKukuPerShare = pool.accKukuPerShare.add(
            KukuReward.mul(1e12).div(lpSupply)
        );

        pool.lastRewardBlock = blockNumber;
    }

    /// @notice Deposit LP tokens to KukuFarmer for Kuku allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(block.number <= endBlock, "KukuMaster: Farming is ended");

        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);
        
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accKukuPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeKukuTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accKukuPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens from KukuFarmer.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        

        updatePool(_pid);
        
        uint256 pending =
            user.amount.mul(pool.accKukuPerShare).div(1e12).sub(
                user.rewardDebt
            );

    
        safeKukuTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accKukuPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /// @notice Safe Kuku transfer function, just in case if rounding error causes pool to not have enough Kukus.
    function safeKukuTransfer(address _to, uint256 _amount) internal {
        uint256 KukuBal = Kuku.balanceOf(address(this));
        if (_amount > KukuBal) {
            Kuku.transfer(_to, KukuBal);
        } else {
            Kuku.transfer(_to, _amount);
        }
    }

    /// @notice get current active block. if farming ends, block number = end block number
    function currentBlockNumber() internal view returns (uint256 blockNumber) {
        blockNumber = block.number;
        if (block.number >= endBlock) {
            blockNumber = endBlock;
        }
    }
}
