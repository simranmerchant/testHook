import React, { useState } from "react";
import "./LiquidityStep2.css";
import priceRangeChart from "./price-range-img.png"; // Import your time series chart

const LiquidityStep2 = ({ onBack, onNext }) => {
    const [minPrice, setMinPrice] = useState("0");
    const [maxPrice, setMaxPrice] = useState("∞");

    return (
        <div className="liquidity-container">
            {/* Sidebar with Steps */}
            <div className="sidebar">
                <div className="step-box">Step 1</div>
                <div className="step-box active">Step 2</div>
                <div className="step-box">Step 3</div>
            </div>

            {/* Main Box */}
            <div className="main-box">
                <h2 className="title">Set Price Range</h2>

                {/* Chart (ETH Time Series) */}
                <div className="chart-container">
                    <img src={priceRangeChart} alt="ETH Price Chart" className="chart-img" />
                </div>

                {/* Price Input Boxes */}
                <div className="price-range">
                    <div className="price-box">
                        <p className="price-label">Min Price</p>
                        <input
                            type="text"
                            value={minPrice}
                            onChange={(e) => setMinPrice(e.target.value)}
                            className="price-input"
                        />
                        <p className="price-desc">USDC per ETH</p>
                    </div>
                    <div className="price-box">
                        <p className="price-label">Max Price</p>
                        <input
                            type="text"
                            value={maxPrice}
                            onChange={(e) => setMaxPrice(e.target.value)}
                            className="price-input"
                        />
                        <p className="price-desc">USDC per ETH</p>
                    </div>
                </div>

                {/* Continue Button */}
                <div className="button-container">
                    <button className="back-button" onClick={onBack}>Back</button>
                    <button className="continue-button" onClick={onNext}>Continue</button>
                </div>
            </div>
        </div>
    );
};

export default LiquidityStep2;
