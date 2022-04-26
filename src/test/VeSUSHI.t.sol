// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {VeSUSHI} from "../VeSUSHI.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
// import {MockBentoBoxV1} from "./utils/mocks/MockBentoBoxV1.sol";
import {ERC20, MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import "@std/Test.sol";

contract VeSUSHItest is Test {
    using stdStorage for StdStorage;

    /// @dev Storage

    WETH wETH;
    MockERC20 sushi;
    VeSUSHI veSUSHI;
    // MockBentoBoxV1 bento;

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
        wETH = new WETH();
        sushi = new MockERC20("SushiToken", "SUSHI", 18);
        veSUSHI = new VeSUSHI(sushi);
        // bento = new MockBentoBoxV1(address(wETH));
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
        // Setup
        MockERC20 umai = new MockERC20("SushiToken", "SUSHI", 18);
        VeSUSHI vlt = new VeSUSHI(umai);
        // Checks
        assertEq(vlt.name(), "Vote-escrowed SushiToken");
        assertEq(vlt.symbol(), "veSUSHI");
        assertEq(address(vlt.asset()), address(umai));
        assertEq(vlt.decimals(), 18);
    }

    /// @dev Deposits

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
    }

    function testDepositOverBalance() public {
        // Expect the depositSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
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
    }

    function testMintOverBalance() public {
        // Expect the mintVeSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
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
        // ** WITHDRAW ** //
        veSUSHI.withdrawSushi(bag, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), bag);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
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
        // ** REDEEM ** //
        veSUSHI.redeemVeSushi(bag, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), bag);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
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
}
