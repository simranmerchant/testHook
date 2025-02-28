import React, { useState } from "react";
import "./LiquidityStep3.css";
//import ethIcon from "./eth-icon.png"; // Replace with actual ETH icon
//import usdcIcon from "./usdc-icon.png"; // Replace with actual USDC icon

const LiquidityStep3 = ({ onBack, onNext }) => {
    const [ethAmount, setEthAmount] = useState("");
    const [usdcAmount, setUsdcAmount] = useState("");

    return (
        <div className="liquidity-container">
            {/* Sidebar with Steps */}
            <div className="sidebar">
                <div className="step-box">Step 1</div>
                <div className="step-box">Step 2</div>
                <div className="step-box active">Step 3</div>
            </div>

            {/* Main Box */}
            <div className="main-box">
                <h2 className="title">Deposit Tokens</h2>
                <p className="subtitle">Specify the token amounts for your liquidity contribution.</p>

                {/* Token Input Boxes */}
                <div className="token-inputs">
                    {/* ETH Input */}
                    <div className="token-box">
                        <input
                            type="number"
                            placeholder="0"
                            value={ethAmount}
                            onChange={(e) => setEthAmount(e.target.value)}
                            className="token-input"
                        />
                        <p className="usd-value">$0</p>
                        <div className="token-label">
                            {/* <img src={ethIcon} alt="ETH" className="token-icon" /> */}
                            <span>ETH</span>
                        </div>
                    </div>

                    {/* USDC Input */}
                    <div className="token-box">
                        <input
                            type="number"
                            placeholder="0"
                            value={usdcAmount}
                            onChange={(e) => setUsdcAmount(e.target.value)}
                            className="token-input"
                        />
                        <p className="usd-value">$0</p>
                        <div className="token-label">
                            {/* <img src={usdcIcon} alt="USDC" className="token-icon" /> */}
                            <span>USDC</span>
                        </div>
                    </div>
                </div>

                {/* Connect Wallet Button */}
                <button className="connect-wallet-button">Connect Wallet</button>

                {/* Back & Continue Buttons */}
                <div className="button-container">
                    <button className="back-button" onClick={onBack}>Back</button>
                    <button className="continue-button" onClick={onNext}>Continue</button>
                </div>
            </div>
        </div>
    );
};

export default LiquidityStep3;
