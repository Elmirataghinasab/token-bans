// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Test,console} from "forge-std/Test.sol";
import {Bons} from "../src/sorceCode.sol";
import {Deploybons} from "../script/deployScrpt.s.sol";

interface MintableToken {
    function mint(address, uint256) external;
} 


contract bonsFuzzTest is Test{ 

    Bons public bons;
    Deploybons public deploy;
    address public owner;


     function setUp()public {
        deploy = new Deploybons();
        bons=deploy.run();
        owner = bons.owner();
     }
    function testFuzz_OnlyOwnerCanTransferOwnership_toEveryAddress(address newOwner) public {
        vm.assume(newOwner != address(0));
        
        if (msg.sender != owner) {
            vm.expectRevert("Ownable: caller is not the owner");
        }      
        vm.prank(owner);
        bons.transferOwnership(newOwner);
        assertEq(bons.owner(), newOwner);
    }
    function testFuzz_noOne_can_mint(address custmer)public{
        vm.expectRevert();
        MintableToken(address(bons)).mint(custmer, 1);
    }
    function testFuzz_Allowances(address spender, uint256 approveAmount, uint256 transferAmount) public {
        approveAmount=bound(approveAmount, 0, 1e18);
        transferAmount = bound(transferAmount, 0, approveAmount); 


        vm.assume(approveAmount > 0 && transferAmount <= approveAmount);
        vm.assume(spender != address(0) && spender != owner);

        vm.prank(owner);
        bons.approve(spender, approveAmount);

        uint256 initialAllowance = bons.allowance(owner, spender);
        assertEq(initialAllowance, approveAmount);
    
        vm.prank(spender);
        vm.deal(owner,initialAllowance);
    
        if (transferAmount > initialAllowance) {
            vm.expectRevert();
            bons.transferFrom(owner, spender, transferAmount);
        } else {
            
            bons.transferFrom(owner,spender, transferAmount);
            assertEq(bons.allowance(owner, spender), initialAllowance - transferAmount);
        }
    }
     function testFuzz_TransferBalanceCalculations(uint256 transferAmount) public {
        vm.assume(transferAmount > 0 && transferAmount <= bons.balanceOf(owner));
        
        address receiver = makeAddr("receiver");

        vm.prank(owner);
        bons.transfer(receiver, transferAmount);

        assertEq(bons.balanceOf(receiver), transferAmount);
        assertEq(bons.balanceOf(owner), bons.totalSupply() - transferAmount);
    }
    function testFuzz_TransferFailsOnInsufficientBalance(address from, address to, uint256 transferAmount) public {
        transferAmount=bound(transferAmount, 0, 1e18);

        vm.assume(transferAmount > 0);
        vm.assume(from != address(0) && to != address(0) && from != to && bons.balanceOf(from)<transferAmount);

        vm.prank(from);
        
        vm.expectRevert();
        bons.transfer(to, transferAmount); 
    }
    function testFuzz_ApproveAndTransferFrom(
        address spender,
        uint256 approveAmount,
        uint256 transferAmount
    ) public {

        approveAmount=bound(approveAmount, 0, 1e18);
        transferAmount = bound(transferAmount, 0, approveAmount); 

        vm.assume(approveAmount > 0 && transferAmount <= approveAmount);
        vm.assume(spender != address(0) && spender != owner);

        vm.prank(owner);
        bons.approve(spender, approveAmount);

        vm.prank(spender);
        if (transferAmount > bons.balanceOf(owner)) {
            vm.expectRevert();   
            bons.transferFrom(owner, spender, transferAmount);
        }else {
            vm.prank(spender);
            bons.transferFrom(owner, spender, transferAmount);
            assertEq(bons.balanceOf(spender), transferAmount); 
            assertEq(bons.allowance(owner, spender), approveAmount - transferAmount);   
        }
    }
    

}