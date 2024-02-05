// SPDX-License-Identifier: MIT

/** 
*   @dev
*   This file is meant to implement the tests for 
*   OpenZeppelin's ERC20 token standard implementation
*   in order to show that it satisfies the properties
*   defined for our research. 
*   Those properties will be listed out in a PROPERTIES.md
*   file of this repository, please notice that it's not possible 
*   yet to have many properties tested because of time limit of my part.
*/

pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OpenZeppelinERC20} from "src/contracts/ERC-20/OpenZeppelinERC20.sol";
import {WrappedTON} from "src/contracts/ERC-20/WrappedTON.sol";

contract ERC20PropertiesTest is Test {
    OpenZeppelinERC20 token;
    //WrappedTON token;

    function setUp() public {
        token = new OpenZeppelinERC20();
        //token = new WrappedTON("Wrapped TON", "WTON");
    }

    /**********************************************************************************************/
    /*                                                                                            */
    /*                            TRANSFER FUNCTION PROPERTIES                                    */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-01 implementation
    *
    *  transfer succeeds if the following conditions are met:
    *  - the 'receiver' address is not the zero address
    *  - amount does not exceed the balance of msg.sender  
    *  - transfering amount to 'receiver' address does not results in a overflow  
    */  
    function prove_transfer(address sender, address receiver, uint256 amount) public {
        require(receiver != address(0));
        token.mint(sender, amount);
        require(amount <= token.balanceOf(sender));
        require(token.balanceOf(receiver) + amount >= token.balanceOf(receiver)); //no overflow on receiver
        
        uint256 prebal = token.balanceOf(receiver);
        vm.prank(sender);
        token.transfer(receiver, amount);
        uint256 postbal = token.balanceOf(receiver);

        uint256 expected = receiver == sender
                        ? 0        // no self transfer allowed here
                        : amount;  // otherwise amount has been transfered to to
        assertTrue(expected == postbal - prebal, "Incorrect expected value returned");
    } 

    /** 
    *  @dev
    *  property ERC20-STDPROP-02 implementation
    *
    *  transfer can succeed in self transfers if the following is met:
    *  - amount does not exceeds the balance of sender
    */
    function prove_transferToSelf(address sender, uint256 amount) public {
        require(amount > 0);
        token.mint(sender, amount);
        uint256 prebal = token.balanceOf(sender);
        require(prebal >= amount);

        vm.prank(sender);
        token.transfer(sender, amount);

        uint256 postbal = token.balanceOf(sender);
        assertEq(prebal, postbal, "Value of prebal and postbal doesn't match");
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-03 implementation
    *
    *  transfer should send the correct amount in non-self transfers:
    *  - if a transfer call doesn't revert, it must correctly subtract the 'amount'
    *  - from the sender and add that same value to the 'receiver'
    */ 
    function prove_transferCorrectAmount(address sender, address receiver, uint256 amount) public {
        require(amount > 0);
        require(receiver != sender);
        require(receiver != address(this));
        require(receiver != address(0));

        token.mint(sender, amount);
        uint256 prebalSender = token.balanceOf(sender);
        uint256 prebalReceiver = token.balanceOf(receiver);
        require(prebalSender > 0);

        vm.prank(sender);
        token.transfer(receiver, amount);
        uint256 postbalSender = token.balanceOf(sender);
        uint256 postbalReceiver = token.balanceOf(receiver);

        assertTrue(postbalSender == prebalSender - amount);
        assertTrue(postbalReceiver == prebalReceiver + amount);
     }

    /** 
    *  @dev
    *  property ERC20-STDPROP-04 implementation
    *
    *  transfer should send correct amount in self-transfers:
    *  - if a self-transfer call doesn't revert, it must subtract the value 'amount'
    *  - from the 'sender' and add that same value to the 'sender' address
    */ 
    function prove_transferSelfCorrectAmount(address sender, uint256 amount) public {
        require(amount > 1);
        require(amount != UINT256_MAX);
        token.mint(sender, amount);
        uint256 prebalSender = token.balanceOf(sender);
        require(prebalSender > 0);

        vm.prank(sender);
        token.transfer(sender, amount);
        uint256 postbalSender = token.balanceOf(sender);

        assertTrue(postbalSender == prebalSender);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-05 implementation
    *
    *  transfer should not have any unexpected state changes on non-revert calls as follows:
    *  - must only modify the balance of 'sender' and 'receiver'
    *  - any other state e.g. allowance, totalSupply, balances of an address not involved in the transfer call
    *  - should not change 
    */ 
    function prove_transferChangeState(address sender, address receiver, uint256 amount) public {
        require(amount > 0);
        require(receiver != address(0));
        require(receiver != sender);
        require(sender != address(0));
        token.mint(sender, amount);
        require(token.balanceOf(sender) > 0);

        //Create an address that is not involved in the transfer call
        address addr = address(bytes20(keccak256(abi.encode(block.timestamp))));
        require(addr != address(0));
        require(addr != sender);
        require(addr != receiver);
        token.mint(addr, amount);

        uint256 initialSupply = token.totalSupply();
        uint256 senderInitialBalance = token.balanceOf(sender);
        uint256 receiverInitialBalance = token.balanceOf(receiver);

        uint256 addrInitialBalance = token.balanceOf(addr);
        uint256 allowanceForAddr = 100;
        token.approve(addr, allowanceForAddr);
        uint256 addrInitialAllowance = token.allowance(address(this), addr);
        
        vm.prank(sender);
        token.transfer(receiver, amount);

        assertTrue(token.balanceOf(sender) == senderInitialBalance - amount);
        assertTrue(token.balanceOf(receiver) == receiverInitialBalance + amount);

        assertTrue(token.totalSupply() == initialSupply);
        assertTrue(token.balanceOf(addr) == addrInitialBalance);
        assertTrue(token.allowance(address(this), addr) == addrInitialAllowance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-06 implementation
    *
    *  zero amount transfer should not break accounting
    */ 
    function prove_transferZeroAmount(address sender, address receiver) public {
        token.mint(sender, 1);
        token.mint(receiver, 2);
        uint256 balanceSender = token.balanceOf(sender);
        uint256 balanceReceiver = token.balanceOf(receiver);
        require(balanceSender > 0);

        vm.prank(sender);
        token.transfer(receiver, 0);

        assertTrue(token.balanceOf(sender) == balanceSender);
        assertTrue(token.balanceOf(receiver) == balanceReceiver);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-07 implementation
    *
    *  any transfer call to address 0 should fail and revert.
    */ 
    function prove_transferToZeroAddressReverts(address sender, uint256 amount) public {   
        require(amount > 0);
        token.mint(sender, amount);
        uint256 prebal = token.balanceOf(sender);

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", address(0), amount);
        vm.prank(sender);
        (bool success, ) = address(token).call(payload);
        assertTrue(!success); //call reverts

        uint256 postbal = token.balanceOf(sender);
        assert(prebal == postbal);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-08 implementation
    *
    *  transfer should fail and revert if account balance is lower than the total amount
    *  trying to be sent.
    */ 
    function prove_transferNotEnoughBalanceReverts(address sender, address receiver, uint256 amount) public {
        require(amount > 1);
        require(amount <= UINT256_MAX);
        token.mint(sender, amount - 1);
        uint256 prebal = token.balanceOf(sender);
        require(prebal < amount);

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
        vm.prank(sender);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assertTrue(!success); //call reverts

        bool transferReturn = abi.decode(returnData, (bool));
        uint256 postbal = token.balanceOf(sender);
        assert(prebal == postbal);
        assert(!transferReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-09 implementation
    *
    *  transfer should prevent overflow on the receiver
    */ 
    function prove_transferOverflowReceiverReverts(address sender, address receiver, uint256 amount) public {
        require(sender != receiver);
        require(receiver != address(0));
        require(amount > 0);
        token.mint(sender, amount);
        token.mint(receiver, amount);
        uint256 oldReceiverBalance = token.balanceOf(receiver);
        uint256 oldSenderBalance = token.balanceOf(sender);
        require(amount <= oldSenderBalance);
        require(oldReceiverBalance >= 0);
        require(oldReceiverBalance <= UINT256_MAX);
        require(oldSenderBalance <= UINT256_MAX);
        require((oldReceiverBalance + amount) < oldReceiverBalance); //overflow

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
        vm.prank(sender);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assertTrue(!success); //call reverts

        bool transferReturn = abi.decode(returnData, (bool));
        uint256 receiverBalance = token.balanceOf(receiver);
        uint256 senderBalance = token.balanceOf(sender);
        assert(oldSenderBalance == senderBalance);
        assert(oldReceiverBalance == receiverBalance);
        assert(!transferReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-10 implementation
    *  transfer should not return false on failure, instead it should revert
    *
    *  in the implementation below, we supose that the token implementation doesn't allow
    *  transfer with amount higher than the (balanceOf(address(this)) will be equal to supply)
    *   
    *  NOTE: this might not be the best way to handle this property since we can't be
    *        sure which requirement will cause the call to fail, open to suggestions
    */ 
    function prove_transferNeverReturnsFalse(address sender, address receiver, uint256 amount) public {
        token.mint(sender, amount - 1);
        require(amount > token.balanceOf(sender));

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);
        vm.prank(sender);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assert(!success); // call should revert on failure

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn); 
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-11 implementation
    *  
    *  transfer calls returns true to indicate it succeeded
    */
    function prove_transferSuccessReturnsTrue(address sender, address receiver, uint256 amount) public {
        token.mint(sender, amount);
        require(amount <= token.balanceOf(sender));
        require(sender != receiver);

        bytes memory payload = abi.encodeWithSignature("transfer(address,uint256)", receiver, amount);  
        vm.prank(sender);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        assert(returnData.length > 0); // assures transfer returns something
        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);
    }


    /**********************************************************************************************/
    /*                                                                                            */
    /*                        TRANSFERFROM FUNCTION PROPERTIES                                    */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-12 implementation
    *
    *  transferFrom should update accounting accordingly when succeeding
    *
    *  Non-self transfers transferFrom calls must succeed if
    *  - amount does not exceed the balance of address from
    *  - amount does not exceed allowance of msg.sender for address from
    */ 
    function prove_transferFrom(address from, address to, uint256 amount) public {
        require(from != address(0));
        require(to != address(0));
        require(from != to);
        require(amount > 0);
        require(amount != type(uint256).max);
        token.mint(from, amount);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance >= amount);

        vm.prank(from);
        token.approve(msg.sender, amount);
        uint256 initialAllowance = token.allowance(from, msg.sender);
        require(initialAllowance >= amount);

        uint256 initialToBalance = token.balanceOf(to);
        require(initialToBalance + amount >= initialToBalance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        assertTrue(success);

        assert(token.balanceOf(from) == initialFromBalance - amount);
        assert(token.balanceOf(to) == initialToBalance + amount);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-13 implementation
    *
    *  Self transfers should not break accounting
    *
    *  All self transferFrom calls must succeed if:
    *  - amount does not exceed the balance of address from
    *  - amount does not exceed the allowance of msg.sender for address from
    */ 
    function prove_transferFromToSelf(address from, address to, uint256 amount) public {
        require(from != address(0));
        require(from == to);
        require(amount > 0);
        require(amount != type(uint256).max);

        token.mint(from, amount);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance > 0);

        uint256 initialToBalance = token.balanceOf(to);

        vm.prank(from);
        token.approve(msg.sender, amount);
        uint256 fromAllowance = token.allowance(from, msg.sender);
        require(fromAllowance >= amount);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        require(success);

        uint256 newFromBalance = token.balanceOf(from);
        uint256 newToBalance = token.balanceOf(to);

        assert(newFromBalance == initialFromBalance);
        assert(newToBalance == initialToBalance);
        assert(newFromBalance == newToBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-14 implementation
    *
    *  Non-self transferFrom calls transfers the correct amount
    *
    *  All non-self transferFrom calls that succeed do the following:
    *  - reduces exactly 'amount' from the balance of address from
    *  - adds exactly 'amount' to the balance of address to
    */ 
    function prove_transferFromCorrectAmount(address from, address to, uint256 amount) public {
        require(from != to);
        require(amount >= 0);
        token.mint(from, amount);

        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance >= 0);
        require(initialFromBalance != type(uint256).max);

        uint256 initialToBalance = token.balanceOf(to);
        require(initialToBalance >= 0);
        require(initialToBalance + amount > initialToBalance);

        vm.prank(from);
        token.approve(msg.sender, amount);
        uint256 initialFromAllowance = token.allowance(from, msg.sender);
        require(initialFromAllowance > 0); 

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        require(success);

        assert(token.balanceOf(from) == initialFromBalance - amount);
        assert(token.balanceOf(to) == initialToBalance + amount); 
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-15 implementation
    *
    *  self transferFrom calls transfers the correct amount
    *
    *  All self transferFrom calls that succeed do not change the balance
    *  of the 'from' address which is the same at the 'to' address
    */ 
    function prove_transferFromToSelfCorrectAmount(address from, address to, uint256 amount) public {
        require(from == to);
        require(amount >= 0);
        require(amount != type(uint256).max);

        token.mint(from, amount);
        uint256 fromInitialBalance = token.balanceOf(from);
        require(fromInitialBalance >= 0);
        require(fromInitialBalance < type(uint256).max);
        require(fromInitialBalance + amount >= fromInitialBalance);

        vm.prank(from);
        token.approve(msg.sender, amount);
        require(token.allowance(from, msg.sender) > 0);
        require(token.allowance(from, msg.sender) >= amount);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        require(success);

        assert(token.balanceOf(from) == fromInitialBalance);
        assert(token.balanceOf(to) == token.balanceOf(from));
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-16 implementation
    *
    *  transferFrom calls doesn't change state unexpectedly.
    *
    *  All non-reverting calls of transferFrom(from, to, amount) that succeeds
    *  should only modify the following:
    *  - balance of address 'to'
    *  - balance of address 'from'
    *  - allowance from 'msg.sender' for the address 'from'
    */ 
    function prove_transferFromChangeState(address to, uint256 amount) public {
        address unrelatedAddress = address(0x1);
        require(to != msg.sender);
        require(to != address(this));
        require(to != address(0));
        require(to != unrelatedAddress);
        require(msg.sender != unrelatedAddress);
        require(msg.sender != address(0));
        require(amount > 0);
        require(amount != UINT256_MAX);

        token.mint(msg.sender, amount);
        token.approve(msg.sender, amount);
        
        uint256 initialSenderBalance = token.balanceOf(msg.sender);
        uint256 initialToBalance = token.balanceOf(to);
        uint256 initialUnrelatedBalance = token.balanceOf(unrelatedAddress);
        uint256 initialSupply = token.totalSupply();
        uint256 initialAllowance = token.allowance(msg.sender, address(this));
        
        require(initialSenderBalance > 0 && initialAllowance >= initialSenderBalance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        require(success);

        // Assert expected state changes
        assert(token.balanceOf(msg.sender) == initialSenderBalance - amount);
        assert(token.balanceOf(to) == initialToBalance + amount);
        assert(token.allowance(msg.sender, address(this)) == initialAllowance - amount);

        // Assert no unexpected state changes
        assert(token.balanceOf(unrelatedAddress) == initialUnrelatedBalance);
        assert(token.totalSupply() == initialSupply);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-17 implementation
    *
    *  zero amount transferFrom calls should not break accounting
    */ 
    function prove_transferFromZeroAmount(address from, address to) public {
        require(from != address(0));
        require(to != address(0));
        require(from != to);

        token.mint(from, 100);
        uint256 initialFromBalance = token.balanceOf(from);
        require(initialFromBalance > 0);

        uint256 initialToBalance = token.balanceOf(to);

        vm.prank(from);
        token.approve(msg.sender, 100);
        uint256 fromAllowance = token.allowance(from, msg.sender);
        require(fromAllowance >= 0);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, 0);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        require(success);

        assert(token.balanceOf(from) == initialFromBalance);
        assert(token.balanceOf(to) == initialToBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-18 implementation
    *
    *  All non-reverting transferFrom calls updates allowance correctly
    */ 
    function prove_transferFromCorrectAllowance(address from, address to, uint256 amount) public {
        require(amount >= 0);
        require(amount != UINT256_MAX);

        token.mint(from, amount);
        uint256 fromBalance = token.balanceOf(from);
        require(fromBalance >= 0);
        require(fromBalance < UINT256_MAX);
        uint256 toBalance = token.balanceOf(to);
        require(toBalance >= 0);
        require(toBalance < UINT256_MAX);

        vm.prank(from);
        token.approve(msg.sender, amount);
        uint256 allowance = token.allowance(from, msg.sender);
        require(allowance >= amount);
        require(allowance < UINT256_MAX);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        require(success);

        assert(token.allowance(from, msg.sender) == allowance - amount);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-19 implementation
    *
    *  All transferFrom calls to zero address should revert
    */ 
    function prove_transferFromToZeroAddressReverts(address from, uint256 amount) public {
        require(amount > 1);
        require(from != msg.sender);
        require(from != address(0));

        token.mint(from, amount);
        vm.prank(from);
        token.approve(msg.sender, amount);
        uint256 initialSenderBalance = token.balanceOf(from);
        uint256 initialSenderAllowance = token.allowance(from, msg.sender);
        
        require(initialSenderBalance > 0 && initialSenderAllowance >= amount);
        uint256 maxValue = initialSenderBalance >= initialSenderAllowance
                        ? initialSenderAllowance
                        : initialSenderBalance;

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, address(0), maxValue);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        assertTrue(!success); //call reverts
 
        assert(token.balanceOf(from) == initialSenderBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-20 implementation
    *
    *  All transferFrom calls where amount is higher than the available balance should revert
    */ 
    function prove_transferFromNotEnoughBalanceReverts(address from, address to, uint256 amount) public {
        require(amount > 0);
        require(from != to);
        require(from != msg.sender);
        require(from != address(0));
        require(to != msg.sender);
        require(to != address(this));
        require(to != address(0));

        token.mint(from, amount);
        vm.prank(from);
        token.approve(msg.sender, amount + 1);

        uint256 senderBalance = token.balanceOf(from);
        uint256 senderAllowance = token.allowance(from, msg.sender);
        uint256 toBalance = token.balanceOf(to);

        require(senderBalance > 0 && senderAllowance > senderBalance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, senderBalance + 1);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        assertTrue(!success); //call reverts

        assert(token.balanceOf(from) == senderBalance);
        assert(token.balanceOf(to) == toBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-21 implementation
    *
    *  All transferFrom calls where amount is higher than the allowance available should revert
    */ 
    function prove_transferFromNotEnoughAllowanceReverts(address from, address to, uint256 amount) public {
        require(amount > 0);
        require(amount != UINT256_MAX);
        require(from != to);
        require(from != msg.sender);
        require(from != address(0));
        require(to != msg.sender);
        require(to != address(this));
        require(to != address(0));

        token.mint(from, amount);
        vm.prank(from);
        token.approve(msg.sender, amount - 1);

        uint256 senderBalance = token.balanceOf(from);
        uint256 senderAllowance = token.allowance(from, msg.sender);
        uint256 toBalance = token.balanceOf(to);

        require(senderBalance > 0 && amount > senderAllowance);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        assertTrue(!success); //call reverts

        assert(token.balanceOf(from) == senderBalance);
        assert(token.balanceOf(to) == toBalance);
        assert(token.allowance(from, msg.sender) == senderAllowance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-22 implementation
    *
    *  transfer should prevent overflow on the receiver
    */ 
    function prove_transferFromOverflowReceiverReverts(address from, address to, uint256 amount) public {
        require(from != to);
        require(from != address(0));
        require(from != msg.sender);
        require(to != msg.sender);
        require(to != address(0));
        require(to != address(this));
        require(amount > 0);

        token.mint(from, amount);
        vm.prank(from);
        token.approve(msg.sender, amount);
        token.mint(to, amount);
        uint256 initialToBalance = token.balanceOf(to);
        uint256 initialSenderBalance = token.balanceOf(from);

        require(amount <= initialSenderBalance);
        require(initialToBalance >= 0);
        require(initialToBalance <= UINT256_MAX);
        require(initialSenderBalance <= UINT256_MAX);
        require((initialToBalance + amount) < initialToBalance); //overflow

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, ) = address(token).call(payload);
        assertTrue(!success); //call reverts

        uint256 toBalance = token.balanceOf(to);
        uint256 senderBalance = token.balanceOf(from);
        assert(initialSenderBalance == senderBalance);
        assert(initialToBalance == toBalance);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-23 implementation
    *
    *  transferFrom should not return false on failure, instead it should revert
    *
    *  in the implementation below, we suppose that the token implementation doesn't allow
    *  transferFrom with amount higher than the balance of msg.sender
    *
    *  NOTE: this might not be the best way to handle this property since we can't be
    *        sure which requirement will cause the call to fail, open to suggestions
    */ 
    function prove_transferFromNeverReturnsFalse(address from, address to, uint256 amount) public {
        require(amount > 1);
        token.mint(from, amount);
        vm.prank(from);
        token.approve(msg.sender, amount);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount + 1);
        vm.prank(msg.sender);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assertTrue(!success);

        bool transferReturn = abi.decode(returnData, (bool));
        assert(transferReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-24 implementation
    *  
    *  transferFrom calls returns true to indicate it succeeded
    */
    function prove_transferFromSuccessReturnsTrue(address from, address to, uint256 amount) public {
        token.mint(from, amount);
        vm.prank(from);
        token.approve(msg.sender, amount);

        bytes memory payload = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount);
        vm.prank(msg.sender);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        assert(returnData.length > 0); // assures transfer returns something
        bool transferFromReturn = abi.decode(returnData, (bool));
        assert(transferFromReturn);
    }


    /**********************************************************************************************/
    /*                                                                                            */
    /*                              APPROVE FUNCTION PROPERTIES                                   */
    /*                                                                                            */
    /**********************************************************************************************/

    /** 
    *  @dev
    *  property ERC20-STDPROP-25 implementation
    *
    *  approve calls should succeed if
    *  - the address in the spender parameter for approve(spender, amount) is not the zero address
    *  - amount approved is higher than 0
    */
    function prove_approve(address account, uint256 amount) public {
        require(msg.sender != address(0));
        require(account != address(0));
        require(amount > 0);
        token.mint(account, amount);
        
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", msg.sender, amount);
        vm.prank(account);
        (bool success, bytes memory returnData) = address(token).call(payload);
        assert(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-26 implementation
    *
    *  non-reverting approve calls should update allowance correctly
    */
    function prove_approveCorrectAmount(address account, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", msg.sender, amount);
        vm.prank(account);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
        assert(token.allowance(account, msg.sender) == amount);   
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-27 implementation
    *
    *  any number of non-reverting approve calls should update allowance correctly
    */
    function prove_approveCorrectAmountTwice(address account, uint256 amount) public {
        require(amount > 0);
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", msg.sender, amount);
        vm.prank(account);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
        assert(token.allowance(account, msg.sender) == amount);  

        payload = abi.encodeWithSignature("approve(address,uint256)", msg.sender, amount / 2);
        vm.prank(account);
        (success, returnData) = address(token).call(payload);
        require(success);

        approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
        assert(token.allowance(account, msg.sender) == amount / 2);  
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-28 implementation
    *
    *  any non-reverting approve call should not change states of other variables
    */
    function prove_approveDoesNotChangeState(address account, uint256 amount) public {
        address account2 = address(0x10000);
        address account3 = address(0x20000);
        require(account != account2);
        require(account != account3);
        require(account != msg.sender);
        require(account2 != account3);
        require(account2 != msg.sender);
        require(account3 != msg.sender);

        uint256 supply = token.totalSupply();
        uint256 account2Balance = token.balanceOf(account2);
        uint256 account3Balance = token.balanceOf(account3);
        uint256 allowances = token.allowance(account2, account3);

        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        bool approveReturn = abi.decode(returnData, (bool)); 
        assert(approveReturn);

        assert(token.totalSupply() == supply);
        assert(token.balanceOf(account2) == account2Balance);
        assert(token.balanceOf(account3) == account3Balance);
        assert(token.allowance(account2, account3) == allowances);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-29 implementation
    *
    *  any call to approve where spender is the zero address should revert
    */
    function prove_approveRevertZeroAddress(address account, uint256 amount) public {
        require(account != address(0));
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", address(0), amount);
        vm.prank(account);
        (bool success, ) = address(token).call(payload);
        assertTrue(!success);

        assert(token.allowance(address(0), account) == 0);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-30 implementation
    *
    *  approve should never return false on a fail call
    */
    function prove_approveNeverReturnFalse(address account, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", account, amount);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);
        
        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn);
    }

    /** 
    *  @dev
    *  property ERC20-STDPROP-31 implementation
    *
    *  approve returns true on successful calls
    */
    function prove_approveSuccessReturnsTrue(address account, uint256 amount) public {
        bytes memory payload = abi.encodeWithSignature("approve(address,uint256)", msg.sender, amount);
        vm.prank(account);
        (bool success, bytes memory returnData) = address(token).call(payload);
        require(success);

        assert(returnData.length > 0); //asserts approve returns something
        bool approveReturn = abi.decode(returnData, (bool));
        assert(approveReturn); 
    }
}