// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {VeSUSHI} from "../VeSUSHI.sol";
import {ERC20, MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import "@std/Test.sol";

contract VeSUSHItest is Test {
    using stdStorage for StdStorage;

    /// @dev Storage

    MockERC20 sushi;
    VeSUSHI veSUSHI;

    uint256 constant bag = 1_000_000 ether;

    /// @dev Users

    uint256 immutable alicesPk =
        0x60b919c82f0b4791a5b7c6a7275970ace1748759ebdaa4076d7eeed9dbcff3c3;
    address public immutable alice = 0x503408564C50b43208529faEf9bdf9794c015d52;

    uint256 immutable bobsPk =
        0xf8f8a2f43c8376ccb0871305060d7b27b0554d2cc72bccf41b2705608452f315;
    address public immutable bob = 0x001d3F1ef827552Ae1114027BD3ECF1f086bA0F9;

    uint256 immutable charliesPk =
        0xb9dee2522aae4d21136ba441f976950520adf9479a3c0bda0a88ffc81495ded3;
    address public immutable charlie = 0xccc4A5CeAe4D88Caf822B355C02F9769Fb6fd4fd;

    uint256 immutable nullPk =
        0x8b2ed20f3cc3dd482830910365cfa157e7568b9c3fa53d9edd3febd61086b9be;
    address public immutable nully = 0x0ACDf2aC839B7ff4cd5F16e884B2153E902253f2;

    /// @dev Events

    event VeSushiDeployed(ERC20 indexed sushi, address veSUSHI);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /// @dev Create testing suite

    function setUp() public {
        console.log(unicode"🧪 Testing veSUSHI...");
        sushi = new MockERC20("SushiToken", "SUSHI", 18);
        veSUSHI = new VeSUSHI(sushi);
        // Mint 1 million SUSHI
        sushi.mint(address(this), bag);
        // Approve deposit of 1 billion SUSHI
        sushi.approve(address(veSUSHI), bag * 1000);
    }

    /// @dev Deployment

    function testSetUp() public {
        MockERC20 umai = new MockERC20("SushiToken", "SUSHI", 18);
        // Expect the VeSushiDeployed event to be fired
        vm.expectEmit(true, true, true, true);
        veSUSHI = new VeSUSHI(umai);
        emit VeSushiDeployed(umai, address(veSUSHI));
    }

    function testMetadata() public {
        assertEq(address(sushi), address(veSUSHI.asset()));
        assertEq(veSUSHI.name(), "Vote-escrowed SushiToken");
        assertEq(veSUSHI.symbol(), "veSUSHI");
        assertEq(veSUSHI.decimals(), 18);
    }

    /// @dev Deposits

    function testTotalSupply() public {
        // Check veSUSHI Supply
        assertEq(veSUSHI.totalSupply(), 0);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check veSUSHI Supply (confirm update)
        assertEq(veSUSHI.totalSupply(), bag);
        // Withdraw SUSHI
        veSUSHI.withdrawSushi(bag, address(this), address(this));
        // Check veSUSHI Supply (confirm update)
        assertEq(veSUSHI.totalSupply(), 0);
    }

    function testDeposit() public {
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), bag, bag);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
    }

    function testDepositOverBalance() public {
        // Expect the depositSushi() call to revert from underflow
        vm.expectRevert(bytes("TRANSFER_FROM_FAILED"));
        veSUSHI.depositSushi(1_000_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), bag);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
    }

    function testMint() public {
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), bag, bag);
        // Mint veSUSHI
        veSUSHI.mintVeSushi(bag, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
    }

    function testMintOverBalance() public {
        // Expect the mintVeSushi() call to revert from underflow
        vm.expectRevert(bytes("TRANSFER_FROM_FAILED"));
        veSUSHI.mintVeSushi(1_000_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), bag);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
    }

    /// @dev Withdrawals

    function testWithdraw() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), bag, bag);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
        // ** WITHDRAW ** //
        veSUSHI.withdrawSushi(bag, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), bag);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
    }

    function testWithdrawOverBalance() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), bag, bag);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        // ** WITHDRAW ** //
        // Expect the withdrawSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
        veSUSHI.withdrawSushi(1_000_000_000 ether, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
    }

    function testRedeem() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), bag, bag);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
        // ** REDEEM ** //
        veSUSHI.redeemVeSushi(bag, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), bag);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
    }

    function testRedeemOverBalance() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), bag, bag);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        // ** WITHDRAW ** //
        // Expect the redeemVeSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
        veSUSHI.redeemVeSushi(1_000_000_000 ether, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), bag);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), bag);
    }

    /// @dev DAO vote tracking

    // Delegation

    function testGetCurrentVotes() public {
        // Check current votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check updated votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
    }

    function testGetPriorVotes() public {
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check current (prior) votes
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), 0);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check updated (prior) votes
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), bag);
    }

    function testDelegation() public {
        // Check current delegation
        assertEq(veSUSHI.delegates(address(this)), address(this));
        assertEq(veSUSHI.delegates(alice), alice);
        // Check current votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
        assertEq(veSUSHI.getCurrentVotes(alice), 0);
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check current (prior) votes
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), 0);
        assertEq(veSUSHI.getPriorVotes(alice, block.timestamp - 1 days), 0);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag / 2, address(this));
        veSUSHI.depositSushi(bag / 2, alice);
        // Check current votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag / 2);
        assertEq(veSUSHI.getCurrentVotes(alice), bag / 2);
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check updated (prior) votes
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), bag / 2);
        assertEq(veSUSHI.getPriorVotes(alice, block.timestamp - 1 days), bag / 2);
        // Delegate
        veSUSHI.delegate(alice);
        // Check updated votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
        assertEq(veSUSHI.getCurrentVotes(alice), bag);
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check updated (prior) votes
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), 0);
        assertEq(veSUSHI.getPriorVotes(alice, block.timestamp - 1 days), bag);
    }

    // Transfers

    function testTransfer() public {
        // Check veSUSHI balances
        assertEq(veSUSHI.balanceOf(address(this)), 0);
        assertEq(veSUSHI.balanceOf(alice), 0);
        // Check veSUSHI Supply
        assertEq(veSUSHI.totalSupply(), 0);
        // Check current votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
        assertEq(veSUSHI.getCurrentVotes(alice), 0);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check veSUSHI balances (confirm update)
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        assertEq(veSUSHI.balanceOf(alice), 0);
        // Check veSUSHI Supply (confirm update)
        assertEq(veSUSHI.totalSupply(), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
        assertEq(veSUSHI.getCurrentVotes(alice), 0);
        // Transfer veSUSHI
        assertTrue(veSUSHI.transfer(alice, bag / 2));
        // Check veSUSHI balances (confirm update)
        assertEq(veSUSHI.balanceOf(address(this)), bag / 2);
        assertEq(veSUSHI.balanceOf(alice), bag / 2);
        // Check veSUSHI Supply (confirm no change)
        assertEq(veSUSHI.totalSupply(), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag / 2);
        assertEq(veSUSHI.getCurrentVotes(alice), bag / 2);
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check prior votes (confirm update)
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), bag / 2);
        assertEq(veSUSHI.getPriorVotes(alice, block.timestamp - 1 days), bag / 2);
        // Test underflow
        vm.expectRevert(stdError.arithmeticError);
        assertFalse(veSUSHI.transfer(alice, bag));
        // Check veSUSHI Supply (confirm no change)
        assertEq(veSUSHI.totalSupply(), bag);
    }

    function testTransferFrom() public {
        // Check veSUSHI balances
        assertEq(veSUSHI.balanceOf(address(this)), 0);
        assertEq(veSUSHI.balanceOf(alice), 0);
        // Check veSUSHI Supply
        assertEq(veSUSHI.totalSupply(), 0);
        // Check current votes
        assertEq(veSUSHI.getCurrentVotes(address(this)), 0);
        assertEq(veSUSHI.getCurrentVotes(alice), 0);
        // Deposit SUSHI
        veSUSHI.depositSushi(bag, address(this));
        // Check veSUSHI balances (confirm update)
        assertEq(veSUSHI.balanceOf(address(this)), bag);
        assertEq(veSUSHI.balanceOf(alice), 0);
        // Check veSUSHI Supply (confirm update)
        assertEq(veSUSHI.totalSupply(), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag);
        assertEq(veSUSHI.getCurrentVotes(alice), 0);
        // Approve veSUSHI spend
        assertTrue(veSUSHI.approve(bob, bag / 2));
        // Check approval
        assertEq(veSUSHI.allowance(address(this), bob), bag / 2);
        // Store 'this' in memory
        address owner = address(this);
        // TransferFrom veSUSHI
        startHoax(bob, bob, type(uint256).max);
        assertTrue(veSUSHI.transferFrom(owner, alice, bag / 2));
        vm.stopPrank();
        // Check approval (confirm update)
        assertEq(veSUSHI.allowance(address(this), bob), 0);
        // Check veSUSHI balances (confirm update)
        assertEq(veSUSHI.balanceOf(address(this)), bag / 2);
        assertEq(veSUSHI.balanceOf(alice), bag / 2);
        // Check veSUSHI Supply (confirm no change)
        assertEq(veSUSHI.totalSupply(), bag);
        // Check current votes (confirm update)
        assertEq(veSUSHI.getCurrentVotes(address(this)), bag / 2);
        assertEq(veSUSHI.getCurrentVotes(alice), bag / 2);
        // Move timeline up
        vm.warp(block.timestamp + 2 days);
        // Check prior votes (confirm update)
        assertEq(veSUSHI.getPriorVotes(address(this), block.timestamp - 1 days), bag / 2);
        assertEq(veSUSHI.getPriorVotes(alice, block.timestamp - 1 days), bag / 2);
        // Test underflow
        vm.expectRevert(stdError.arithmeticError);
        assertFalse(veSUSHI.transfer(alice, bag));
        // Check veSUSHI Supply (confirm no change)
        assertEq(veSUSHI.totalSupply(), bag);
    }
}
