// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceRangeChecker {
    AggregatorV3Interface internal priceFeed;

    // Ethereum/USD price feed address on Ethereum Mainnet
    address public constant ETH_USD_PRICE_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    constructor() {
        priceFeed = AggregatorV3Interface(ETH_USD_PRICE_FEED);
    }

    /**
     * @dev Checks if the current ETH price is within the specified range.
     * @param lowerTick The lower bound of the price range.
     * @param upperTick The upper bound of the price range.
     * @return A boolean indicating whether the price is within the range.
     */
    function isPriceInRange(int256 lowerTick, int256 upperTick) public view returns (bool) {
        require(lowerTick < upperTick, "Lower tick must be less than upper tick");

        // Fetch the latest ETH price from Chainlink
        (, int256 price,,,) = priceFeed.latestRoundData();

        // Check if the price is within the range
        return price >= lowerTick && price <= upperTick;
    }
}
