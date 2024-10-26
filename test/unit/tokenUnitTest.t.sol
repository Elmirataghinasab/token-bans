// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Bons} from "../../src/sorceCode.sol";
import {Deploybons} from "../../script/deployScrpt.s.sol";


interface MintableToken {
    function mint(address, uint256) external;
} 

contract bonsTest is Test{
   
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000* (10 ** uint256(decimals));


    uint256 strt_amnt= 100 ether;
    Bons public bons;
    Deploybons public deployer;
    address public deployerAdd;
    address custmer1;
    address custmer2;
    address owner;
    

    function setUp()public {
        deployer = new Deploybons();
        bons=deployer.run();

        custmer1 = makeAddr("custmer1");
        custmer2 = makeAddr("custmer2");
        owner = bons.owner();
         
        vm.prank(msg.sender);
        bons.transfer(custmer1,strt_amnt);
    
    }
            ////unit tests//// 

    function testOwner()public view{
        vm.assertEq(owner, bons.owner());
    }

    function testWhenFrozen()public{
        vm.prank(owner);
        bons.Antiwhale(custmer2);

        vm.prank(custmer2);

        vm.expectRevert("Sender account is locked.");
        bons.transfer(custmer1,1);
    }
    //need fuzz
    function testTransferOwnerShipCrurrectly()public{
        vm.prank(owner);
        bons.transferOwnership(custmer1);

        assertEq(bons.owner(),custmer1);
    }

    function testBurn ()public{
        vm.prank(owner);
        MintableToken(address(bons)).mint(custmer2, 100);


        vm.prank(custmer2);
        bons.burn(100);

        assertEq(bons.balanceOf(custmer2),0);
    }
    function testAntiwhale()public{
        vm.prank(owner);
        bons.Antiwhale(custmer2);
        assertEq(bons.FreezersShow(custmer2),true);

        vm.prank(owner);
        bons.uAntiwhale(custmer2);
        assertEq(bons.FreezersShow(custmer2),false);
    }
    function testAntibot()public {
        vm.prank(owner);
        bons.Antibot();

        assertEq(bons.ShowPausedMode(),true);

        vm.prank(owner);
        bons.uAntibot();

        assertEq(bons.ShowPausedMode(),false);

    }

    //does not need any other test
    function testRenounceOwnership()public {
        vm.prank(owner);
        bons.renounceOwnership();

        assertEq(bons.owner(),address(0));
    }
    function testwhenPaused()public {
        vm.prank(owner);
        bons.Antibot();

        vm.prank(custmer1);

        vm.expectRevert("Paused by owner");
        bons.transfer(custmer2,10);
       
    }
     function testInitialSupply() public view {
        assertEq(bons.totalSupply(), INITIAL_SUPPLY);
    }
    //need fuzz
    function testUsersCantMint() public {
        vm.prank(custmer1);
        vm.expectRevert();
        MintableToken(address(bons)).mint(custmer1, 1);
    }

    //need fuzz
    function testAllowances() public {
        uint256 initialAllowance = 1000;

        vm.prank(custmer1);
        bons.approve(custmer2, initialAllowance);
        uint256 transferAmount = 500;

        vm.prank(custmer2);
        bons.transferFrom(custmer1, custmer2, transferAmount);
        assertEq(bons.balanceOf(custmer2), transferAmount);
        assertEq(bons.balanceOf(custmer1), strt_amnt - transferAmount);
    }
    //need fuzz
    function testTransfer() public {
        uint256 transferAmount = 3 ether;

        vm.prank(custmer1);
        bons.transfer(custmer2, transferAmount);

        assertEq(bons.balanceOf(custmer1), strt_amnt - transferAmount);
        assertEq(bons.balanceOf(custmer2), transferAmount);
    }    
    function testTransferFailInsufficientBalance() public {
       uint256 transferAmount = strt_amnt+ 1 ether;
       vm.prank(custmer1);  
       vm.expectRevert();
       bons.transfer(custmer2, transferAmount);     
    }
    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 5 ether;
        uint256 transferAmount = 3 ether;

        vm.prank(custmer1);
        bons.approve(custmer2, approveAmount);

        vm.prank(custmer2);
        bons.transferFrom(custmer1, custmer2, transferAmount);

        assertEq(bons.balanceOf(custmer2), transferAmount);
        assertEq(bons.allowance(custmer1, custmer2), approveAmount - transferAmount);
    }
    function testFailTransferFromWithoutApproval() public {
        uint256 transferAmount = 3 ether;

        vm.prank(custmer2);
        vm.expectRevert("transfer amount exceeds allowance");
        bons.transferFrom(custmer1, custmer2, transferAmount); 
    }
    function testFailTransferFromInsufficientBalance() public {
        uint256 approveAmount = 5 ether;
        uint256 transferAmount = strt_amnt + 5 ether; 

        vm.prank(custmer1);
        bons.approve(custmer2, approveAmount);

        vm.prank(custmer2);
        vm.expectRevert("transfer amount exceeds balance");
        bons.transferFrom(custmer1, custmer2, transferAmount);
        
    }

}