import React from "react";
import "./Stats.css";

const positions = [
    { range: "100-150 USDC per ETH", amount: "100 ETH", status: "Active", fees: "0.5% Fees", restaked: "-" },
    { range: "1,000-1,200 USDC per ETH", amount: "200 USDC", status: "Inactive", fees: "-", restaked: "$300 Rewards" },
    { range: "500-700 USDC per ETH", amount: "50 ETH", status: "Inactive", fees: "0.3% Fees", restaked: "$150 Rewards" },
];

const Stats = () => {
    return (
        <div className="final-container">
            <div className="final-box">
                <h2 className="congrats-title">🎉 Congratulations! 🎉</h2>
                <p className="congrats-subtitle">Your liquidity positions are now live.</p>

                {/* Positions Table */}
                <table className="positions-table">
                    <thead>
                        <tr>
                            <th>Range</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Fees Earned</th>
                            <th>Restaked Rewards</th>
                        </tr>
                    </thead>
                    <tbody>
                        {positions.map((pos, index) => (
                            <tr key={index} className={pos.status === "Active" ? "active-row" : "inactive-row"}>
                                <td>{pos.range}</td>
                                <td>{pos.amount}</td>
                                <td>{pos.status}</td>
                                <td>{pos.fees}</td>
                                <td>{pos.restaked}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default Stats;
