// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {ERC20, SafeTransferLib, ERC4626} from "@solmate/mixins/ERC4626.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";
import {SafeCastLib} from "@solmate/utils/SafeCastLib.sol";

/// @notice Vote-escrowed SushiToken vault.
contract VeSUSHI is ERC4626, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using SafeCastLib for uint256;
    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event VeSushiDeployed(ERC20 indexed sushi, address veSUSHI);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// -----------------------------------------------------------------------
    /// DAO Storage
    /// -----------------------------------------------------------------------

    mapping(address => address) internal _delegates;

    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    mapping(address => uint256) public numCheckpoints;

    struct Checkpoint {
        uint64 fromTimestamp;
        uint192 votes;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 _sushi) 
        ERC4626(
            _sushi,
            string(abi.encodePacked("Vote-escrowed ", _sushi.name())),
            string(abi.encodePacked("ve", _sushi.symbol()))
        )
    {
        emit VeSushiDeployed(_sushi, address(this));
    }

    /// -----------------------------------------------------------------------
    /// Accounting Logic
    /// -----------------------------------------------------------------------

    /// @notice Check escrowed SUSHI held as underlying.
    /// @return SUSHI balance of this contract.
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// -----------------------------------------------------------------------
    /// Deposit Logic
    /// -----------------------------------------------------------------------

    /// @notice Deposit SUSHI and receive veSUSHI.
    /// @dev This takes `assets` as input.
    /// @param sushiAmount Deposit sum of SUSHI.
    /// @param receiver Account to receive veSUSHI.
    /// @return shares veSUSHI minted.
    function depositSushi(uint256 sushiAmount, address receiver) external nonReentrant returns (uint256 shares) {
        shares = deposit(sushiAmount, receiver);

        _moveDelegates(address(0), delegates(receiver), shares);
    }

    /// @notice Deposit SUSHI and receive veSUSHI.
    /// @dev This takes `shares` as input.
    /// @param veSushiAmount veSUSHI sum to mint.
    /// @param receiver Account to receive veSUSHI.
    /// @return assets SUSHI escrowed.
    function mintVeSushi(uint256 veSushiAmount, address receiver) external nonReentrant returns (uint256 assets) {
        assets = mint(veSushiAmount, receiver);

        _moveDelegates(address(0), delegates(receiver), veSushiAmount);
    }

    /// -----------------------------------------------------------------------
    /// Withdraw Logic
    /// -----------------------------------------------------------------------

    /// @notice Withdraw SUSHI and burn veSUSHI.
    /// @dev This takes `assets` as input.
    /// @param sushiAmount Withdrawal sum of SUSHI.
    /// @param receiver Account to receive SUSHI.
    /// @param owner Account that holds veSUSHI.
    /// @dev If `msg.sender` is not `owner` and approved, 
    /// can make call for `owner`.
    /// @return shares veSUSHI burned.
    function withdrawSushi(
        uint256 sushiAmount,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 shares) {
        shares = withdraw(
            sushiAmount,
            receiver,
            owner
        );

        _moveDelegates(delegates(owner), address(0), shares);
    }

    /// @notice Withdraw SUSHI and burn veSUSHI.
    /// @dev This takes `shares` as input.
    /// @param veSushiAmount veSUSHI sum to burn.
    /// @param receiver Account to receive SUSHI.
    /// @param owner Account that holds veSUSHI.
    /// @dev If `msg.sender` is not `owner` and approved, 
    /// can make call for `owner`.
    /// @return assets SUSHI withdrawn.
    function redeemVeSushi(
        uint256 veSushiAmount,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256 assets) {
        assets = redeem(
            veSushiAmount,
            receiver,
            owner
        );

        _moveDelegates(delegates(owner), address(0), veSushiAmount);
    }

    /// -----------------------------------------------------------------------
    /// DAO Logic
    /// -----------------------------------------------------------------------

    // *** Transfers *** //

    /// @notice Send `amount` tokens by `msg.sender` for `to`.
    /// @dev Updates delegation amounts.
    /// @param to The recipient account.
    /// @param amount The sum of tokens to send.
    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        _moveDelegates(delegates(msg.sender), delegates(to), amount);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /// @notice Send `amount` tokens by `from` for `to`.
    /// @dev Updates delegation amounts.
    /// @param from The owner account.
    /// @param to The recipient account.
    /// @param amount The sum of tokens to send.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        _moveDelegates(delegates(from), delegates(to), amount);

        emit Transfer(from, to, amount);

        return true;
    }

    // *** Delegation *** //

    /// @notice Returns current delegate for an account.
    /// @dev If no delegation, `delegator` is current delegate.
    /// @param delegator The address votes are delegated from.
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];

        return current == address(0) ? delegator : current;
    }

    /// @notice Delegate votes from `msg.sender` to `delegatee`.
    /// @param delegatee The address to delegate votes to.
    function delegate(address delegatee) external {
        _delegate(msg.sender, delegatee);
    }

    /// @notice Gets the current votes balance for `account`.
    /// @param account The address to get votes balance.
    /// @return The number of current votes for `account`.
    function getCurrentVotes(address account) external view returns (uint256) {
        // This is safe from underflow because decrement only occurs if `nCheckpoints` is positive.
        unchecked {
            uint256 nCheckpoints = numCheckpoints[account];

            return nCheckpoints != 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        }
    }

    /// @notice Determine the prior number of votes for an account as of a unix time.
    /// @dev Unix time must be finalized or else this function will revert to prevent misinformation.
    /// @param account The address of the account to check.
    /// @param timestamp The unix time to get the vote balance at.
    /// @return The number of votes the account had as of the given unix time.
    function getPriorVotes(address account, uint256 timestamp) external view returns (uint256) {
        require(block.timestamp > timestamp, "NOT_DETERMINED");

        uint256 nCheckpoints = numCheckpoints[account];

        if (nCheckpoints == 0) return 0;
        
        // This is safe from underflow because decrement only occurs if `nCheckpoints` is positive.
        unchecked {
            if (checkpoints[account][nCheckpoints - 1].fromTimestamp <= timestamp)
                return checkpoints[account][nCheckpoints - 1].votes;
            if (checkpoints[account][0].fromTimestamp > timestamp) return 0;

            uint256 lower;  
            // This is safe from underflow because decrement only occurs if `nCheckpoints` is positive.
            uint256 upper = nCheckpoints - 1;

            while (upper > lower) {
                // This is safe from underflow because `upper` ceiling is provided.
                uint256 center = upper - (upper - lower) / 2;

                Checkpoint memory cp = checkpoints[account][center];

                if (cp.fromTimestamp == timestamp) {
                    return cp.votes;
                } else if (cp.fromTimestamp < timestamp) {
                    lower = center;
                } else {
                    upper = center - 1;
                }
            }

        return checkpoints[account][lower].votes;

        }
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        _moveDelegates(currentDelegate, delegatee, balanceOf[delegator]);

        emit DelegateChanged(delegator, currentDelegate, delegatee);
    }

    function _moveDelegates(
        address srcRep, 
        address dstRep, 
        uint256 amount
    ) private {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];

                uint256 srcRepOld = srcRepNum != 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;

                uint256 srcRepNew = srcRepOld - amount;

                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            
            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];

                uint256 dstRepOld = dstRepNum != 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;

                uint256 dstRepNew = dstRepOld + amount;

                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee, 
        uint256 nCheckpoints, 
        uint256 oldVotes, 
        uint256 newVotes
    ) internal {
        unchecked {
            // This is safe from underflow because decrement only occurs if `nCheckpoints` is positive.
            if (nCheckpoints != 0 && checkpoints[delegatee][nCheckpoints - 1].fromTimestamp == block.timestamp) {
                checkpoints[delegatee][nCheckpoints - 1].votes = newVotes.safeCastTo192();
            } else {
                checkpoints[delegatee][nCheckpoints] = Checkpoint(block.timestamp.safeCastTo64(), newVotes.safeCastTo192());
                // Cannot realistically overflow on human timescales.
                numCheckpoints[delegatee] = nCheckpoints + 1;
            }
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}
