import React, { useState } from "react";
import Welcome from "./components/Welcome/Welcome";
import LiquidityStep1 from "./components/Onboarding/LiquidityStep1";
import LiquidityStep2 from "./components/Onboarding/LiquidityStep2";
import LiquidityStep3 from "./components/Onboarding/LiquidityStep3";
import Stats from "./components/UserStatistics/Stats";

function App() {
  const [currentPage, setCurrentPage] = useState("welcome");

  return (
    <div>
      {currentPage === "welcome" && <Welcome onNext={() => setCurrentPage("liquidity-step1")} />}
      {currentPage === "liquidity-step1" && <LiquidityStep1 onNext={() => setCurrentPage("liquidity-step2")} />}
      {currentPage === "liquidity-step2" && <LiquidityStep2 onBack={() => setCurrentPage("liquidity-step1")} onNext={() => setCurrentPage("liquidity-step3")} />}
      {currentPage === "liquidity-step3" && <LiquidityStep3 onBack={() => setCurrentPage("liquidity-step2")} onNext={() => setCurrentPage("stats-page")} />}
      {currentPage === "stats-page" && <Stats />}
    </div>
  );
}

export default App;
