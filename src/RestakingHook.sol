// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/src/types/BalanceDelta.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {FullMath} from "v4-core/src/libraries/FullMath.sol";
import {PoolKeys} from "./PoolKeyETHUSDC.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import "forge-std/console.sol"; // Import the console library

contract RestakingHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    IPoolManager public immutable basePoolManager;
    IPositionManager public posm;
    address public posmAddress; // Store as regular address for ERC721 operations

    // Token variables
    Currency public currency0;
    Currency public currency1;
    uint256 public tokenId;

    // Hardcoded PoolKey
    PoolKey public ETH_USDC_POOL_KEY;
    PoolId public immutable ETH_USDC_POOL_ID;

    // Tick spacing
    int24 public constant GLOBAL_TICK_SPACING = 60;

    // Current price (fixed the undefined variable)
    uint160 public currentPrice;

    struct Position {
        int24 upperTick;
        int24 lowerTick;
        uint256 amount0; // ETH
        uint256 amount1; // USDC
        uint256 liquidity; // Liquidity in this specific position
        uint256 LPTokensMinted; // LP tokens for this specific position
        bool isActive; // Whether the position is currently active
        uint256 accumulatedFees;
        uint256 accumulatedRewards;
    }

    // Track total ETH staked for inactive positions
    uint256 public totalStakedETH;

    mapping(PoolId => uint256) public beforeAddLiquidityCount;
    mapping(address => Position) public userPositions;

    mapping(PoolId => uint256) public poolLiquidity;
    mapping(PoolId => mapping(int24 => int256)) public liquidityAtTick;

    // Users who have positions (to replace the incorrect for loop in the original code)
    address[] public userAddresses;
    mapping(address => bool) public isRegisteredUser;

    event PositionUpdated(address indexed user, bool isActive, uint256 liquidity);
    event LiquidityAdded(
        address indexed user, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1, uint256 liquidity
    );
    event ETHDiverted(address indexed user, uint256 amount);

    constructor(IPoolManager _basePoolManager) BaseHook(_basePoolManager) {
        // Ensure the PoolManager address is valid
        require(address(_basePoolManager) != address(0), "Invalid PoolManager address");

        // Ensure the hook address is valid
        require(address(this) != address(0), "Invalid hook address");

        // Assign the PoolManager
        basePoolManager = _basePoolManager;

        // Log the addresses for debugging
        console.log("PoolManager address:", address(_basePoolManager));
        console.log("Hook address:", address(this));

        // Initialize the ETH-USDC pool key and ID
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
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: false,
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
        uint160 sqrtPriceX96 = getCurrentPrice();

        (uint256 amount0, uint256 amount1) =
            calculateAmounts(sqrtPriceX96, params.tickLower, params.tickUpper, int128(params.liquidityDelta));

        bool isActive = isPriceInRange(sqrtPriceX96, params.tickLower, params.tickUpper);
        Position storage position = userPositions[sender];

        position.lowerTick = params.tickLower;
        position.upperTick = params.tickUpper;
        position.isActive = isActive;

        if (isActive) {
            position.liquidity += uint256(int256(params.liquidityDelta));
            position.amount0 += amount0;
            position.amount1 += amount1;
        } else {
            divertETHToRestaking(sender, amount0);
            position.amount1 += amount1;
        }

        return bytes4(keccak256("_beforeAddLiquidity(address,PoolKey,IPoolManager.ModifyLiquidityParams,bytes)"));
    }

    function calculateAmounts(uint160 sqrtPriceX96, int24 tickLower, int24 tickUpper, int128 liquidityDelta)
        internal
        pure
        returns (uint256 amount0, uint256 amount1)
    {
        uint160 sqrtRatioAX96 = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtPriceAtTick(tickUpper);
        (amount0, amount1) =
            LiquidityAmounts.getAmountsForLiquidity(sqrtPriceX96, sqrtRatioAX96, sqrtRatioBX96, uint128(liquidityDelta));
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

    // Change the parameter name to avoid shadowing
    function onERC721Received(address operator, address from, uint256 _tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    // Get the current price
    function getCurrentPrice() internal view returns (uint160) {
        return currentPrice; // Now this variable is defined
    }
    // Helper function to check if the current price is within a position's range

    function isPriceInRange(uint160 price, int24 tickLower, int24 tickUpper) internal pure returns (bool) {
        uint160 priceLower = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 priceUpper = TickMath.getSqrtPriceAtTick(tickUpper);
        return price >= priceLower && price <= priceUpper;
    }

    // Divert ETH to restaking
    function divertETHToRestaking(address sender, uint256 ethAmount) internal {
        // Transfer ETH to the restaking contract
        IERC20(Currency.unwrap(ETH_USDC_POOL_KEY.currency0)).transferFrom(sender, address(this), ethAmount);

        // Add to user's staked amount
        userPositions[sender].amount0 += ethAmount;

        // Add to total staked ETH
        totalStakedETH += ethAmount;

        emit ETHDiverted(sender, ethAmount);

        // Add to restaking pool (replace with actual restaking logic)
        // restakingContract.stake(ethAmount);
    }
}
