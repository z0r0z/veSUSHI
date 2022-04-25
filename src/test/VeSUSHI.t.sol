// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {VeSUSHI} from "../VeSUSHI.sol";
import {WETH} from "@solmate/tokens/WETH.sol";
// import {MockBentoBoxV1} from "./utils/mocks/MockBentoBoxV1.sol";
import {ERC20, MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import "@std/Test.sol";

contract VeSUSHItest is Test {
    using stdStorage for StdStorage;

    WETH wETH;
    MockERC20 sushi;
    VeSUSHI veSUSHI;
    // MockBentoBoxV1 bento;

    event VeSushiDeployed(ERC20 indexed sushi, address veSUSHI);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function setUp() public {
        console.log(unicode"🧪 Testing veSUSHI...");
        wETH = new WETH();
        sushi = new MockERC20("SushiToken", "SUSHI", 18);
        veSUSHI = new VeSUSHI(sushi);
        // bento = new MockBentoBoxV1(address(wETH));
        // Mint 1 million SUSHI
        sushi.mint(address(this), 1_000_000 ether);
        // Approve deposit of 1 billion SUSHI
        sushi.approve(address(veSUSHI), 1_000_000_000 ether);
    }

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

    function testDeposit() public {
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), 1_000_000 ether, 1_000_000 ether);
        // Deposit SUSHI
        veSUSHI.depositSushi(1_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
    }

    function testDepositOverBalance() public {
        // Expect the depositSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
        veSUSHI.depositSushi(1_000_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 1_000_000 ether);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
    }

    function testMint() public {
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), 1_000_000 ether, 1_000_000 ether);
        // Mint veSUSHI
        veSUSHI.mintVeSushi(1_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
    }

    function testMintOverBalance() public {
        // Expect the mintVeSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
        veSUSHI.mintVeSushi(1_000_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 1_000_000 ether);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
    }

    function testWithdraw() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), 1_000_000 ether, 1_000_000 ether);
        // Deposit SUSHI
        veSUSHI.depositSushi(1_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
        // ** WITHDRAW ** //
        veSUSHI.withdrawSushi(1_000_000 ether, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 1_000_000 ether);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
    }

    function testWithdrawOverBalance() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), 1_000_000 ether, 1_000_000 ether);
        // Deposit SUSHI
        veSUSHI.depositSushi(1_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
        // ** WITHDRAW ** //
        // Expect the withdrawSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
        veSUSHI.withdrawSushi(1_000_000_000 ether, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
    }

    function testRedeem() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), 1_000_000 ether, 1_000_000 ether);
        // Deposit SUSHI
        veSUSHI.depositSushi(1_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
        // ** REDEEM ** //
        veSUSHI.redeemVeSushi(1_000_000 ether, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 1_000_000 ether);
        assertEq(sushi.balanceOf(address(veSUSHI)), 0);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 0);
    }

    function testRedeemOverBalance() public {
        // ** DEPOSIT ** //
        // Expect the Deposit event to be fired
        vm.expectEmit(true, true, true, true);
        emit Deposit(address(this), address(this), 1_000_000 ether, 1_000_000 ether);
        // Deposit SUSHI
        veSUSHI.depositSushi(1_000_000 ether, address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
        // ** WITHDRAW ** //
        // Expect the redeemVeSushi() call to revert from underflow
        vm.expectRevert(stdError.arithmeticError);
        veSUSHI.redeemVeSushi(1_000_000_000 ether, address(this), address(this));
        // Check SUSHI balances
        assertEq(sushi.balanceOf(address(this)), 0);
        assertEq(sushi.balanceOf(address(veSUSHI)), 1_000_000 ether);
        // Check veSUSHI balance
        assertEq(veSUSHI.balanceOf(address(this)), 1_000_000 ether);
    }
}
