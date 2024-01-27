// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


/// @title A contract to get the Eth/USD price
/// @author Alvan
/// @notice This is an enviroment sensitive deployment.
/// @dev All env must be properly set before deployment 
library PriceConverter {
    
    function getPrice(AggregatorV3Interface priceFeed) internal  view returns (uint256) {
        // Adress: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI 
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 1e10);
    }

    function getVersion() internal view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return  ethAmountInUsd;
    }
}