// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Need address and ABI
        // Address 0x694AA1769357215DE4FAC081bf1f309aDC325306 (Sepolia ETH/USD Price Feed from Chainlink docs)
        // https://docs.chain.link/data-feeds/price-feeds/addresses
        // ABI - import the contract
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // Price of ETH in terms of USD, e.g. 2000.000
        return uint256(answer * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // Always multiply, THEN divide
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // ethPrice & ethAmount both have 18 decimal places
        return ethAmountInUsd;
    }
}
