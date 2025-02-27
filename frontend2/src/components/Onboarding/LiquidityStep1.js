import React from "react";
import "./LiquidityStep1.css";

const LiquidityStep1 = ({ onNext }) => {
    return (
        <div className="liquidity-container">
            {/* Sidebar with Steps */}
            <div className="sidebar">
                <div className="step-box active">Step 1</div>
                <div className="step-box">Step 2</div>
                <div className="step-box">Step 3</div>
            </div>

            {/* Main Box (ETH ⇄ USDC + Fees) */}
            <div className="main-box">
                {/* Token Pair */}
                <div className="pair-box">ETH ⇄ USDC</div>

                {/* Fee Tier */}
                <div className="fee-section">
                    <p className="fee-label">Fee Tier</p>
                    <div className="fee-box">0.5% Fee Tier</div>
                </div>

                {/* Restaking APY */}
                <div className="restake-section">
                    <p className="restake-text">Restaking Fees (Using Our Hook)</p>
                    <div className="restake-box">4-5% APY</div>
                </div>

                {/* Next Button */}
                <button className="next-button" onClick={onNext}>Continue</button>
            </div>
        </div>
    );
};

export default LiquidityStep1;
