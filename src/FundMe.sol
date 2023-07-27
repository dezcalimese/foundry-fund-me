// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title A simple contract transferring funds to and from an owner to a contract
/// @custom:experimental This is an experimental contract

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// Custom errors can help save gas
error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint;

    address[] private s_funders;
    mapping(address funder => uint amountFunded)
        private s_addressToAmountFunded;

    address private immutable i_owner;
    uint public constant MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // msg.value.getConversionRate(); -> This gets passed as a uint256 into getConversionRate
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Not enough ETH sent :("
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint) {
        return s_priceFeed.version();
    }

    function withdraw() public onlyOwner {
        // When withdrawing, we want to reset all the mappings back to 0 in order to show
        // all the $$ is withdrawn to all parties
        // Can do this by using a for loop
        for (
            uint funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Resetting the array
        s_funders = new address[](0);

        // Withdrawing the funds

        /*
        transfer -> wrap address in payable, .transfer and point out exactly how much to transfer
        - if fails, tx reverted

        Code:
        payable(msg.sender).transfer(address(this).balance);
        */

        /*
        send
        - if this fails, boolean is shown, contract doesn't fail and user would just lose $$

        Code:   
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
        */

        // call -> recommended way to transfer tokens
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // In `withdraw`, we are loading from storage quite a bit in the for loop. Better to read from memory
    function cheaperWithdraw() public onlyOwner {
        uint fundersLength = s_funders.length; // This only reads from storage one time, now a memory variable
        for (uint funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // instead of require(msg.sender == i_owner, "Sender is not the owner!"); do this:
        // Because we don't have to store & emit the string message, this saves a lot of gas
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    fallback() external payable {
        fund();
    }

    // If someone accidently sends funds to this contract w/o calling fund(), the receive function can come in handy
    receive() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
