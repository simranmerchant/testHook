// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {FullMath} from "v4-core/src/libraries/FullMath.sol";
import {PoolKeys} from "./PoolKeyETHUSDC.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

contract RestakingHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    IPoolManager public immutable basePoolManager;

    // Hardcoded PoolKey
    PoolKey public ETH_USDC_POOL_KEY;
    PoolId public immutable ETH_USDC_POOL_ID;

    // Tick spacing
    int24 public constant GLOBAL_TICK_SPACING = 60;

    struct Position {
        int24 upperTick;
        int24 lowerTick;
        uint256 amount0; // ETH
        uint256 amount1; // USDC
        uint256 LPTokensMinted;
        bool isActive;
        uint256 accumulatedFees;
        uint256 accumulatedRewards;
    }

    mapping(PoolId => uint256) public beforeAddLiquidityCount;
    mapping(address => Position) public userPositions;

    mapping(PoolId => uint256) public poolLiquidity;
    mapping(PoolId => mapping(int24 => int256)) public liquidityAtTick;

    constructor(IPoolManager _basePoolManager) BaseHook(_basePoolManager) {
        basePoolManager = _basePoolManager;

        PoolKey memory ethUsdcKey = PoolKeys.getETHUSDCPoolKey();
        ETH_USDC_POOL_KEY = ethUsdcKey;

        // Compute the PoolId
        ETH_USDC_POOL_ID = ETH_USDC_POOL_KEY.toId();
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function _beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) internal override returns (bytes4) {
        PoolId poolId = key.toId();

        uint256 liquidityAmount = uint256(int256(params.liquidityDelta));
        poolLiquidity[poolId] += liquidityAmount; // Store manually

        return bytes4(keccak256("_beforeAddLiquidity(address,PoolKey,IPoolManager.ModifyLiquidityParams,bytes)"));
    }

    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();

        // Manually track liquidity at ticks
        liquidityAtTick[poolId][params.tickLower] += int256(params.liquidityDelta);
        liquidityAtTick[poolId][params.tickUpper] += int256(params.liquidityDelta);

        return (
            bytes4(
                keccak256(
                    "_afterAddLiquidity(address,PoolKey,IPoolManager.ModifyLiquidityParams,BalanceDelta,BalanceDelta,bytes)"
                )
            ),
            BalanceDeltaLibrary.ZERO_DELTA
        );
    }

    function calculateLPTokensMinted(IPoolManager.ModifyLiquidityParams calldata params, BalanceDelta delta)
        internal
        view
        returns (uint256)
    {
        uint256 totalLiquidityBefore = getTotalLiquidityInRange(
            ETH_USDC_POOL_ID,
            params.tickLower,
            params.tickUpper,
            GLOBAL_TICK_SPACING // Add the tickSpacing argument
        );
        uint256 userLiquidity = sqrt(uint256(int256(params.liquidityDelta)) * uint256(int256(params.liquidityDelta)));
        uint256 totalLiquidityAfter = totalLiquidityBefore + userLiquidity;
        return (userLiquidity * 1e18) / totalLiquidityAfter;
    }

    function getTotalLiquidityInRange(PoolId poolId, int24 lowerTick, int24 upperTick, int24 tickSpacing)
        internal
        view
        returns (uint256)
    {
        uint256 totalLiquidity;

        require(lowerTick % tickSpacing == 0, "Invalid lowerTick");
        require(upperTick % tickSpacing == 0, "Invalid upperTick");

        for (int24 tick = lowerTick; tick <= upperTick; tick += tickSpacing) {
            int256 liquidityNet = liquidityAtTick[poolId][tick];
            if (liquidityNet > 0) {
                totalLiquidity += uint256(liquidityNet);
            }
        }

        return totalLiquidity;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
