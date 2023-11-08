//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol"; // Import standard test framework from Foundry
import {FundMe} from "../../src/FundMe.sol"; // Import our source code
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; // Import our deployment for modular approach

contract FundMeTest is Test {
    FundMe fundMe; // Declare global variable?

    address USER = makeAddr("user"); // USeing prank cheat code to have a fake user for test?
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // Set-up for the test?
        ///  fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarsisFive() public {
        // Testing the requirement for minimum fund. ALWAYS WRITE ROBUST TESTING TO MAKE IT CLEAR!!!
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    // Conclusion: This first test is to demostrate the minimum amount required to fund in the contract.
    // Based on the contract the amount should be 5, therefore when testing with other number like e.g. 7 USD, the test fails, meaning the code is correct and is only allowing the fix amount of 5 USD

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // heym the next line, should revert!
        // assert(This tx fails/revert)
        fundMe.fund(); // Send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The n ext TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayofFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public {
        // Test to check that only the owner can withdraw
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Test that money can be withdrawn by owner
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        /*
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE); // To add gas costs to our local anvil chain transactions and asssume is a real chain. */
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Example of how to add and check the gas used on this test
        // https://youtu.be/sas02qSFZ74?t=5918
        /*
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        */

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            // address ()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            // Act
            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();
            vm.stopPrank();

            // Assert
            assert(address(fundMe).balance == 0);
            assert(
                startingFundMeBalance + startingOwnerBalance ==
                    fundMe.getOwner().balance
            );
        }
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberofFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            // address ()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

            uint256 startingOwnerBalance = fundMe.getOwner().balance;
            uint256 startingFundMeBalance = address(fundMe).balance;

            // Act
            vm.startPrank(fundMe.getOwner());
            fundMe.cheaperWithdraw();
            vm.stopPrank();

            // Assert
            assert(address(fundMe).balance == 0);
            assert(
                startingFundMeBalance + startingOwnerBalance ==
                    fundMe.getOwner().balance
            );
        }
    }
}
