require("dotenv").config();
const { ethers } = require("ethers");
const axios = require("axios");

// Load environment variables
const RPC_URL = process.env.RPC_URL;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const API_URL = process.env.API_URL;
const API_TOKEN = process.env.API_TOKEN;
const STAKER_ADDRESS = process.env.STAKER_ADDRESS;

// Connect to the blockchain
const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const contract = new ethers.Contract(
    CONTRACT_ADDRESS,
    ["event ReadyForStaking(uint256 totalStakedETH)"],
    provider
);

// Function to call the P2P Staking API
async function callP2PStakingAPI(totalStakedETH) {
    try {
        const response = await axios.post(
            API_URL,
            {
                chain: "eth_ssv",
                network: "testnet",
                stakerAddress: STAKER_ADDRESS,
                amount: totalStakedETH.toString(),
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${API_TOKEN}`,
                },
            }
        );
        console.log("API Response:", response.data);
    } catch (error) {
        console.error("Error calling P2P Staking API:", error.response?.data || error.message);
    }
}

// Listen for the ReadyForStaking event
contract.on("ReadyForStaking", async (totalStakedETH) => {
    console.log(`Total staked ETH reached: ${ethers.utils.formatEther(totalStakedETH)}`);

    // Call the P2P Staking API
    await callP2PStakingAPI(totalStakedETH);
});

console.log("Listening for ReadyForStaking events...");