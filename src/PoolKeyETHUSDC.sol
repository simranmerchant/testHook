// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

library PoolKeys {
    function getETHUSDCPoolKey() internal pure returns (PoolKey memory) {
        return PoolKey({
            currency0: Currency.wrap(address(0)), // Native ETH
            currency1: Currency.wrap(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48), // USDC
            fee: 3000, // 0.3% fee tier
            tickSpacing: 60,
            hooks: IHooks(address(0)) // No hooks
        });
    }
}
