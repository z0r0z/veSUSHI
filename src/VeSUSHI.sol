// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {ERC20, SafeTransferLib, ERC4626} from "@solmate/mixins/ERC4626.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

/// @notice Vote-escrowed SushiToken vault.
contract VeSUSHI is ERC4626, ReentrancyGuard {
    /// -----------------------------------------------------------------------
    /// Library Usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event VeSushiDeployed(ERC20 indexed sushi, address veSUSHI);

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
    /// @return veSUSHI minted.
    function depositSushi(uint256 sushiAmount, address receiver) external nonReentrant returns (uint256) {
        return deposit(sushiAmount, receiver);
    }

    /// @notice Deposit SUSHI and receive veSUSHI.
    /// @dev This takes `shares` as input.
    /// @param veSushiAmount veSUSHI sum to mint.
    /// @param receiver Account to receive veSUSHI.
    /// @return SUSHI escrowed.
    function mintVeSushi(uint256 veSushiAmount, address receiver) external nonReentrant returns (uint256) {
        return mint(veSushiAmount, receiver);
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
    /// @return veSUSHI burned.
    function withdrawSushi(
        uint256 sushiAmount,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256) {
        return withdraw(
            sushiAmount,
            receiver,
            owner
        );
    }

    /// @notice Withdraw SUSHI and burn veSUSHI.
    /// @dev This takes `shares` as input.
    /// @param veSushiAmount veSUSHI sum to burn.
    /// @param receiver Account to receive SUSHI.
    /// @param owner Account that holds veSUSHI.
    /// @dev If `msg.sender` is not `owner` and approved, 
    /// can make call for `owner`.
    /// @return SUSHI withdrawn.
    function redeemVeSushi(
        uint256 veSushiAmount,
        address receiver,
        address owner
    ) external nonReentrant returns (uint256) {
        return redeem(
            veSushiAmount,
            receiver,
            owner
        );
    }  
}
