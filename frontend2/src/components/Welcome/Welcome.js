import React from "react";
import "./Welcome.css";

const Welcome = ({ onNext }) => {
  return (
    <div className="welcome-container">
      <header className="welcome-header">
        <h1 className="welcome-title">Aegis</h1>
        <p className="welcome-subtitle">Restake. Rebalance. Optimize.</p>
        <p className="welcome-description">
          Aegis is a powerful Uniswap Hook that automatically restakes your liquidity
          when it falls out of range, ensuring your crypto stays productive.
          No manual monitoring—just seamless rebalancing.
        </p>
        <button className="next-button" onClick={onNext}>
          Get Started →
        </button>
      </header>
    </div>
  );
};

export default Welcome;
