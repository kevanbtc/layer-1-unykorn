# 🌍 GLOBAL ENERGY & CARBON MARKETS - COMPLETE SYSTEM

**Status**: Production Blueprint  
**Scope**: Tax Equity, RECs, SRECs, Carbon Credits, ESG, T-REX, Global Arbitrage  
**Coverage**: All jurisdictions (regulated + deregulated), all standards, all exploits documented

---

## 📋 TABLE OF CONTENTS

1. [Tax Equity Structures](#1-tax-equity-structures)
2. [REC/SREC Trading Platforms](#2-recsrec-trading-platforms)
3. [Global Jurisdictions & Markets](#3-global-jurisdictions--markets)
4. [T-REX (ERC-3643) Integration](#4-t-rex-erc-3643-integration)
5. [Carbon Credit Standards](#5-carbon-credit-standards)
6. [ESG Disclosure Standards](#6-esg-disclosure-standards)
7. [Trading Formulas & Arbitrage](#7-trading-formulas--arbitrage)
8. [Known Flaws & Exploits](#8-known-flaws--exploits)
9. [Smart Contract Architecture](#9-smart-contract-architecture)
10. [Deployment Procedures](#10-deployment-procedures)

---

## 1) TAX EQUITY STRUCTURES

### Investment Tax Credit (ITC) Partnerships

**Formula: ITC Value**
```
ITC_Value = Project_Cost × ITC_Rate
ITC_Rate (Solar) = 30% (2022-2032), 26% (2033), 22% (2034), 10% permanent
ITC_Rate (Wind) = Phased out (use PTC)
ITC_Rate (Energy Storage) = 30% (standalone, post-IRA)
ITC_Rate (Geothermal/Fuel Cells/Microturbines) = 30%

Recapture Period = 5 years
Recapture_Amount = ITC_Value × (1 - Years_In_Service/5)
```

**Partnership Flip Structure**
```
Pre-Flip Allocation:
  Tax Equity Investor: 99% of tax benefits (ITC + depreciation)
  Sponsor: 1% of tax benefits
  Cash: 95% investor / 5% sponsor

Post-Flip Trigger:
  Typically: IRR Target Met (e.g., 8-10%) OR Year 6-8
  Post-Flip: 5% investor / 95% sponsor

Fair Market Value (FMV) Test:
  Investor_Equity ≥ 20% of Project_Cost (safe harbor)
```

**Smart Contract Implementation**
```solidity
struct TaxEquityDeal {
    uint256 projectCost;
    uint16 itcBps;              // 3000 = 30%
    uint64 flipDate;            // unix timestamp OR
    uint16 targetIrrBps;        // 800 = 8%
    address taxInvestor;
    address sponsor;
    uint16 preFlipTaxBps;       // 9900 = 99%
    uint16 postFlipTaxBps;      // 500 = 5%
    bool flipped;
}
```

### Production Tax Credit (PTC) - Wind Primary

**Formula: PTC Value**
```
PTC_Annual = Generation_kWh × PTC_Rate × Inflation_Adjustment
PTC_Rate (Wind) = $27.50/MWh (2024, indexed)
PTC_Duration = 10 years from Commercial Operation Date (COD)
Phase-Out: 60% if construction starts 2022+

Total_PTC_Value = Σ(Year_1 to Year_10) [Generation × Rate × Adjustment]
```

**Leveraged Lease Structure**
```
Equity Contribution: 20-30%
Debt Financing: 70-80% (non-recourse)
PTC Monetization: Discount factor 80-85% of face value
```

---

## 2) REC/SREC TRADING PLATFORMS

### Renewable Energy Certificates (RECs) - North America

**Generation Formula**
```
RECs_Issued = MWh_Generated × Eligibility_Factor
Eligibility_Factor = 1.0 (full renewable)
Vintage = Year-Month of generation (YYYY-MM)
Expiry = 3 years from vintage (varies by RPS)
```

**Market Pricing (spot)**
```
REC_Price = Base_REC + Regional_Premium + Vintage_Discount + Technology_Premium

Base_REC (voluntary): $0.50 - $5.00/MWh
Regional_Premium:
  - ERCOT: +$1-3 (high demand)
  - PJM-GATS: +$0.50-2
  - NEPOOL-GIS: +$2-5
  - WREGIS: +$0.30-1.50

Vintage_Discount:
  Current year: 0%
  1 year old: -10%
  2 years old: -25%
  3 years old: -40%

Technology_Premium:
  Solar: +$5-15/MWh (vs wind)
  Offshore Wind: +$10-20/MWh
  Hydro: -$2-5/MWh (less desirable)
```

### Solar Renewable Energy Certificates (SRECs) - Compliance Markets

**Jurisdictions with SREC Markets**
1. **New Jersey** (highest value historically)
2. **Massachusetts** (SREC-II program)
3. **Pennsylvania**
4. **Ohio** (suspended 2021)
5. **Maryland**
6. **District of Columbia**
7. **Delaware** (defunct)

**SREC Pricing Formula**
```
SREC_Price = min(
    (ACP - Market_Supply_Curve),
    Alternative_Compliance_Payment
)

Alternative_Compliance Payment (ACP) by State (2024):
  NJ: $91/MWh (declining to $0 by 2033)
  MA: $285/MWh (SREC-II)
  PA: $45/MWh
  MD: $30/MWh
  DC: $500/MWh (highest in US!)

Supply_Curve:
  Oversupply → price → SACP (minimum floor)
  Undersupply → price → ACP (ceiling)
```

**Arbitrage: DC SRECs**
```
DC_SREC_Arb_Opportunity:
  Buy: Adjacent state SRECs at $30-90
  Sell: DC market at $400-500
  Constraint: Must be DC-registered facility OR reciprocity agreement
  
Profit_Per_MWh = DC_ACP - Acquisition_Cost - Registration_Fee - Broker_Fee
Typical_Spread = $350-450/MWh (if eligible)
```

### Global REC Systems

**EU Guarantees of Origin (GOs)**
```
Price: €0.20 - €2.00/MWh (voluntary market)
Issuing Bodies: AIB (Association of Issuing Bodies)
Standards: EECS (European Energy Certificate System)
Tracking: 1 GO = 1 MWh

Arbitrage:
  Nordic Hydro GOs: €0.20-0.40/MWh
  Southern EU Solar GOs: €1.50-2.00/MWh
  Spread: Technology + Geography premium
```

**I-REC (International REC Standard)**
```
Coverage: 60+ countries (Asia, Africa, Latin America)
Price Range: $0.10 - $10/MWh (varies wildly by country)
High-Value Markets:
  - Singapore: $5-8/MWh
  - Japan: $3-6/MWh
  - South Korea: $4-7/MWh
Low-Value Markets:
  - India: $0.10-0.50/MWh
  - China: $0.20-1.00/MWh

Arbitrage Play:
  Issue in low-cost jurisdiction → sell to high-demand market
  Barrier: Corporate PPA geography restrictions
```

---

## 3) GLOBAL JURISDICTIONS & MARKETS

### Deregulated Markets (Wholesale Trading)

**United States - ISOs/RTOs**

1. **ERCOT (Texas)** - Island grid, no federal oversight
   ```
   Participants: 52 GW wind, 20 GW solar (2024)
   REC Price: $1-4/MWh (voluntary)
   Ancillary Services: 4-Second Reserve, Load Resource
   Arb Opportunity: Real-Time vs Day-Ahead spread (up to $500/MWh during scarcity)
   ```

2. **PJM Interconnection** (Mid-Atlantic + Midwest)
   ```
   Coverage: 13 states + DC
   Capacity Market: Base Residual Auction (BRA) 3 years ahead
   REC Tracking: PJM-GATS
   Tier I REC Price: $5-15/MWh
   SREC States: PA, MD, NJ, DE, OH (within PJM)
   ```

3. **CAISO (California)**
   ```
   RPS: 60% by 2030, 100% by 2045
   REC Prices: $10-30/MWh (compliance-driven)
   Hourly Net Load Duck Curve: Creates intra-day arb ($0-200/MWh swing)
   Storage Mandate: Creates price arbitrage for battery systems
   ```

4. **ISO-NE (New England)**
   ```
   States: CT, ME, MA, NH, RI, VT
   RPS Targets: MA 40% (2030), CT 44% (2030)
   REC Prices: $15-35/MWh (high compliance demand)
   Forward Capacity Market: 3-year ahead auctions
   ```

5. **MISO (Midwest)**
   ```
   Coverage: 15 states (Great Lakes to Gulf)
   Wind Heavy: 30 GW+ installed
   REC Prices: $0.50-3/MWh (oversupply)
   Congestion: North→South constraints create basis differentials
   ```

6. **NYISO (New York)**
   ```
   CES: 70% renewable by 2030, 100% clean by 2040
   Zone J (NYC): Locational premium $20-50/MWh vs upstate
   Offshore Wind: 9 GW pipeline (creates OREC market)
   ```

7. **SPP (Southwest Power Pool)**
   ```
   Coverage: Great Plains wind corridor
   Wind Penetration: >50% during spring nights
   Negative Prices: Frequent due to wind curtailment
   Arb: Export to MISO/ERCOT during scarcity
   ```

**Europe - Market Coupling**

1. **Nord Pool** (Scandinavia)
   ```
   Hydro-Dominated: >50% generation
   Day-Ahead: EUPHEMIA algorithm
   Intraday: Continuous trading
   Price: Often €0-30/MWh (hydro surplus)
   GO Price: €0.20-0.50/MWh (cheapest in EU)
   ```

2. **EPEX SPOT** (Central Europe)
   ```
   Germany Price Leadership: Sets regional benchmarks
   Negative Prices: Solar midday in summer
   Interconnectors: France, Netherlands, Austria, Switzerland
   Arb: Germany→France nuclear-solar arb
   ```

3. **OMIE** (Iberian Peninsula - Spain/Portugal)
   ```
   Isolated Until 2024: Limited France interconnection
   Solar Boom: 20 GW pipeline
   Price Volatility: €20-150/MWh daily range
   ```

**Asia-Pacific**

1. **Japan - JEPX (Japan Electric Power Exchange)**
   ```
   Post-Fukushima: Deregulation since 2016
   High Prices: ¥10-20/kWh (vs $0.10-0.20 US)
   Feed-in Tariff: ¥10-40/kWh (legacy solar)
   J-Credit: Domestic carbon offset (¥1,000-5,000/tCO2)
   ```

2. **Australia - NEM (National Electricity Market)**
   ```
   States: NSW, VIC, QLD, SA, TAS
   Renewable Penetration: 35%+ (2024)
   LGC (Large-Scale): A$30-50/MWh
   STC (Small-Scale): A$38/MWh (legislated)
   Price Spikes: A$0-15,000/MWh (cap)
   ```

3. **Singapore - SWEM (Singapore Wholesale Electricity Market)**
   ```
   Gas-Dominated: 95%+ CCGT
   Solar Niche: Rooftop + floating
   I-REC Price: S$8-12/MWh (corporate demand)
   Regional Interconnect: Planned ASEAN grid
   ```

4. **South Korea - KPX**
   ```
   RPS: 25% by 2034
   REC Multipliers: 0.7 (solar utility) to 5.0 (building-integrated)
   REC Price: ₩50,000-90,000/MWh (~$40-70)
   ```

### Regulated Markets (Vertically Integrated Utilities)

**United States**
- **Southeast**: GA, AL, MS, SC, NC, FL (Duke, Southern Co, NextEra)
  - RPS: Voluntary or weak mandates
  - Solar ITC: Primary driver
  - Wholesale Trading: Minimal
  
- **Mountain West**: UT, ID, WY, MT (PacifiCorp, Rocky Mountain Power)
  - Coal→Gas→Renewables transition
  - REC Markets: Limited

**China**
- **Renewable Portfolio Standard (RPS)**: Implemented 2019
- **Green Certificate (TGC)**: ¥50-300/MWh (~$7-45)
- **Provincial Quotas**: Guangdong, Jiangsu, Zhejiang (high demand)
- **Curtailment**: Xinjiang, Gansu wind (30%+ historical curtailment)

**India**
- **REC Mechanism**: Introduced 2011
- **Solar REC**: ₹1,000-3,000/MWh (~$12-36)
- **Wind REC**: ₹1,000-1,500/MWh
- **State Obligations**: Vary 5-20% renewable

---

## 4) T-REX (ERC-3643) INTEGRATION

### Token for Regulated Exchanges (T-REX)

**Standard**: ERC-3643 (formerly ERC-3643, successor to ERC-1400)

**Core Components**
```solidity
interface IERC3643 {
    // Identity Registry
    function isVerified(address user) external view returns (bool);
    
    // Compliance Rules
    function canTransfer(address from, address to, uint256 amount) 
        external view returns (bool, string memory);
    
    // Forced Transfers (regulator/court order)
    function forcedTransfer(address from, address to, uint256 amount, bytes calldata data) 
        external;
    
    // Token Pause
    function pause() external;
    function unpause() external;
}
```

**Integration with UNY-ID System**
```solidity
contract TREXAdapter {
    IIdentityNFT public identityNFT;
    IAttestationRegistry public attestationRegistry;
    IRuleEngine public ruleEngine;
    
    function isVerified(address user) external view returns (bool) {
        // Check if user has valid IdentityNFT
        uint256 tokenId = identityNFT.tokenOfOwner(user);
        if (tokenId == 0) return false;
        
        // Check KYC attestations
        bytes32 kycSchema = keccak256("KYC_ORG_v1");
        return attestationRegistry.isValid(user, kycSchema, 365 days);
    }
    
    function canTransfer(address from, address to, uint256 amount) 
        external view returns (bool, string memory) 
    {
        // Delegate to RuleEngine
        try ruleEngine.preTransferCheck(from, to, tokenClass, amount) {
            return (true, "");
        } catch Error(string memory reason) {
            return (false, reason);
        }
    }
}
```

**Use Cases for T-REX in Energy Markets**
1. **Tokenized Energy Project Bonds**
   - Reg D/Reg S compliance
   - Accredited investor gating
   - Lock-up periods

2. **Fractional Ownership of Solar/Wind Farms**
   - Security token (not utility)
   - Dividend distributions (energy revenue)
   - Secondary market trading

3. **Green Bonds (Blockchain-Native)**
   - €/$ denominated
   - Quarterly coupon payments
   - ESG reporting requirements

---

## 5) CARBON CREDIT STANDARDS

### Voluntary Carbon Markets

**1. Verra (VCS - Verified Carbon Standard)**
```
Market Share: ~60% of voluntary market
Price Range: $5-50/tCO2e (varies by project type)
Vintage: Year of issuance
Registry: Verra Registry (web portal)

Project Types & Pricing:
  - REDD+ (Forest Conservation): $8-15/tCO2e
  - Afforestation/Reforestation: $12-25/tCO2e
  - Renewable Energy (cookstoves): $3-8/tCO2e
  - Renewable Energy (grid): $1-5/tCO2e
  - Methane Capture: $6-12/tCO2e
  - Direct Air Capture (DAC): $200-600/tCO2e

Methodology IDs: VM0042 (REDD+), VM0007 (REDD), ACM0002 (grid-connected)

Flaws & Exploits:
  ❌ Additionality Issues: Projects would happen anyway
  ❌ Leakage: Deforestation moves to adjacent area
  ❌ Permanence: Forests burn/die (reversal risk)
  ❌ Double-Counting: Same forest credited in multiple registries
  ❌ Baseline Inflation: Exaggerated "business as usual" scenarios
```

**2. Gold Standard**
```
Market Share: ~15% voluntary market
Price Premium: +20-50% vs Verra (higher quality)
Focus: Sustainable Development Goals (SDGs)
Price Range: $10-80/tCO2e

Project Types:
  - Renewable Energy: $12-25/tCO2e
  - Energy Efficiency: $15-30/tCO2e
  - Water Purification: $20-40/tCO2e
  - Community Projects: $25-60/tCO2e

Flaws:
  ❌ Still Subject to Additionality Debates
  ✅ Better Co-Benefits Documentation (health, education)
  ✅ Stricter Monitoring & Verification
```

**3. American Carbon Registry (ACR)**
```
Focus: North American projects
Price Range: $8-30/tCO2e
Methodologies: Forest carbon, improved forest management
Market: Smaller, regional

Flaws:
  ❌ Limited Geographic Scope
  ❌ Lower Liquidity (harder to trade)
```

**4. Puro.earth (Engineered Carbon Removal)**
```
Focus: Durable removals (biochar, mineralization, BECCS)
Price Range: $50-200/tCO2e
Certification: CO2 Removal Certificate (CORC)

Project Types:
  - Biochar: $80-150/tCO2e
  - Bio-Oil Sequestration: $60-120/tCO2e
  - Mineralization: $100-200/tCO2e

Advantages:
  ✅ Permanent Removal (>100 years)
  ✅ Verifiable Mass Balance
  ❌ High Cost (limits demand)
```

**5. Climate Action Reserve (CAR)**
```
Focus: US-based offsets
Price Range: $10-25/tCO2e
Protocols: Forest, livestock, ozone-depleting substances

Flaws:
  ❌ US-Only Limits Market Size
  ✅ High-Quality Protocols (conservative baselines)
```

### Compliance Carbon Markets

**1. EU ETS (European Union Emissions Trading System)**
```
Type: Cap-and-trade (mandatory for large emitters)
Price: €80-100/tCO2 (2024)
Sectors: Power, industry, aviation (intra-EU)
Allowances: EUA (EU Allowance)

Formula:
  Annual_Cap = Previous_Cap × (1 - Linear_Reduction_Factor)
  Linear_Reduction_Factor = 2.2% (2021-2030)

Trading:
  - ICE Futures Europe (primary exchange)
  - EEX (European Energy Exchange)
  - OTC bilateral contracts

Flaws & Exploits:
  ❌ Over-Allocation (Phase I 2005-2007): Price crashed to €0
  ❌ Industrial Lobbying: Free allowances to "trade-exposed" sectors
  ❌ Fraud: VAT carousel fraud (€5B stolen 2008-2009)
  ✅ Price Floor: Market Stability Reserve (MSR) introduced 2019
```

**2. California Cap-and-Trade (CA CaT)**
```
Type: Cap-and-trade (AB 32)
Price: $30-35/tCO2e (2024, near price floor)
Price Floor: $20.76/tCO2e (2024, inflation-adjusted)
Price Ceiling: $87.81/tCO2e (2024)
Allowances: CCA (California Carbon Allowance)

Linked Markets: Québec (since 2014)

Offsets Allowed: 4-6% of compliance obligation
  - US Forest Projects
  - Urban Forest Projects
  - Ozone Depleting Substances
  - Livestock Methane

Arb Opportunity:
  Buy: VCS/Gold Standard offsets at $10-20
  Convert: CA ARB-approved offset protocols
  Sell: $30-35 in compliance market
  Spread: $10-20/tCO2e (if protocol-eligible)
```

**3. RGGI (Regional Greenhouse Gas Initiative) - Northeast US**
```
States: CT, DE, ME, MD, MA, NH, NJ, NY, RI, VT, VA
Sectors: Power plants only
Price: $13-15/tCO2 (2024)
Auction: Quarterly

Flaws:
  ❌ Leaking: Emissions move to non-RGGI states
  ❌ Low Price: Doesn't drive coal retirements
```

**4. UK ETS (Post-Brexit)**
```
Launched: 2021 (replaced EU ETS)
Price: £40-50/tCO2 (~$50-60)
More Stringent: Faster reduction trajectory than EU
```

**5. China National ETS**
```
Launched: 2021
Sectors: Power only (so far)
Price: ¥60-80/tCO2 (~$8-11) - very low
Coverage: 40% of national emissions
Flaws:
  ❌ Lack of Transparency
  ❌ Weak Enforcement
  ❌ Grandfathered Allowances (no scarcity yet)
```

**6. New Zealand ETS**
```
Price: NZ$60-75/tCO2 (~$35-45 USD)
Allowances: NZU (New Zealand Unit)
Unique: Includes forestry & agriculture sectors
```

---

## 6) ESG DISCLOSURE STANDARDS

### Reporting Frameworks

**1. ISSB (International Sustainability Standards Board)**
```
Standards:
  - IFRS S1: General Sustainability Disclosures
  - IFRS S2: Climate-Related Disclosures
  
Adoption: Mandatory in UK, EU, Canada, Australia (phasing in 2024-2026)

Required Metrics:
  - Scope 1, 2, 3 GHG Emissions (tCO2e)
  - Climate Risks & Opportunities
  - Transition Plans
  - Scenario Analysis (1.5°C, 2°C, 4°C)
```

**2. SASB (Sustainability Accounting Standards Board)**
```
Sector-Specific: 77 industries
Focus: Financially Material ESG Issues

Energy Sector Metrics (EM-EP - Oil & Gas E&P):
  - GHG Emissions (Scope 1)
  - Air Quality (NOx, SOx, PM)
  - Water Management (withdrawals, discharge quality)
  - Biodiversity Impacts
  - Reserves Valuation & Capital Expenditures
```

**3. GRI (Global Reporting Initiative)**
```
Most Widely Used: 10,000+ organizations
Standards:
  - GRI 302: Energy
  - GRI 305: Emissions
  - GRI 306: Waste

Advantage: Comprehensive, multi-stakeholder
Disadvantage: Not financially focused (criticized by investors)
```

**4. TCFD (Task Force on Climate-related Financial Disclosures)**
```
Four Pillars:
  1. Governance: Board oversight of climate risks
  2. Strategy: Climate risks & opportunities
  3. Risk Management: Identification & mitigation
  4. Metrics & Targets: Scope 1/2/3, internal carbon price

Adoption: Mandatory in UK, New Zealand, Hong Kong, Singapore
```

**5. CDP (formerly Carbon Disclosure Project)**
```
Focus: Corporate climate questionnaires
Ratings: A to D- (A = Leadership)
Data Users: Investors, customers, regulators

Questionnaires:
  - Climate Change
  - Water Security
  - Forests
```

### On-Chain ESG Attestations

**Schema IDs (UNY-ID System)**
```solidity
bytes32 constant SCHEMA_ESG_SCOPE1_v1 = keccak256("SCHEMA/ESG_SCOPE1_v1");
bytes32 constant SCHEMA_ESG_SCOPE2_v1 = keccak256("SCHEMA/ESG_SCOPE2_v1");
bytes32 constant SCHEMA_ESG_SCOPE3_v1 = keccak256("SCHEMA/ESG_SCOPE3_v1");
bytes32 constant SCHEMA_ESG_TCFD_v1 = keccak256("SCHEMA/ESG_TCFD_v1");
bytes32 constant SCHEMA_ESG_ISSB_S2_v1 = keccak256("SCHEMA/ESG_ISSB_S2_v1");

struct ESG_Attestation {
    uint256 reportingYear;
    uint256 scope1_tCO2e;      // Direct emissions
    uint256 scope2_tCO2e;      // Purchased electricity
    uint256 scope3_tCO2e;      // Value chain
    uint256 renewableEnergy_MWh;
    uint16 renewablePercent_bps; // 0-10000
    string tcfdReportCid;      // IPFS hash of full TCFD report
    string assuranceProviderDid; // Third-party verifier DID
    bytes assuranceSignature;  // ECDSA signature from verifier
}
```

---

## 7) TRADING FORMULAS & ARBITRAGE

### Spot Market Pricing

**Electricity Price Formation**
```
LMP (Locational Marginal Price) = Energy + Congestion + Losses

Energy Component:
  = Marginal_Cost_of_Generation (highest-cost unit dispatched)

Congestion Component:
  = Shadow_Price_of_Transmission_Constraint
  (when a line is at capacity)

Loss Component:
  = Incremental_Loss_Factor × Energy_Price
  (transmission losses ~5-7% on average)

Arbitrage:
  Buy: Off-peak (low LMP, often negative with wind)
  Store: Battery or pump-hydro
  Sell: Peak (high LMP)
  Spread: $50-200/MWh in ERCOT, CAISO
```

**REC Basis Trading**
```
Basis = Local_REC_Price - National_REC_Price

Example:
  MA SREC: $285/MWh
  National REC: $2/MWh
  Basis: $283/MWh

Trade:
  Short: MA SRECs (if you have local generation)
  Long: National RECs (hedge renewable exposure)
  Spread: Captures local premium
```

### Forward Market Hedging

**PPA (Power Purchase Agreement) Valuation**
```
PPA_Value = Σ(Year 1 to Year N) [
    (PPA_Price - Forward_Price_t) × Expected_MWh_t
  ] / (1 + Discount_Rate)^t

Where:
  PPA_Price = Fixed $/MWh (e.g., $40/MWh)
  Forward_Price_t = Market expectation for year t
  Expected_MWh_t = P50 generation forecast
  Discount_Rate = WACC (6-8% for renewables)

Hedge Value:
  If Forward_Price < PPA_Price → Value to buyer
  If Forward_Price > PPA_Price → Value to seller
```

**Shape Risk (Duck Curve)**
```
Revenue_Annual = Σ(Hour 1 to 8760) [
    Generation_h × Price_h
  ]

California Solar Shape:
  - Morning Ramp: 7-9 AM (high price)
  - Midday: 10 AM-2 PM (low/negative price due to oversupply)
  - Evening Ramp: 5-8 PM (highest price, solar offline)

Arbitrage with Storage:
  Charge: Hours 10 AM-2 PM (when solar is cheap/negative)
  Discharge: Hours 5-9 PM (when prices spike)
  Round-Trip Efficiency: 85-90%
  Spread Required: >15-20% to cover degradation + capex
```

### Cross-Commodity Arbitrage

**Natural Gas vs Electricity (Spark Spread)**
```
Spark_Spread = (Power_Price - Gas_Price × Heat_Rate) - Variable_O&M

Where:
  Heat_Rate = BTU_gas / kWh_electricity (e.g., 7,000-10,000 BTU/kWh for CCGT)
  Gas_Price = $/MMBtu
  Power_Price = $/MWh
  Variable_O&M = $2-5/MWh

Profitable if:
  Spark_Spread > 0 (covers fixed costs if sustained)

Arbitrage:
  Long: Gas futures
  Short: Power futures
  When: Expect gas-fired generation to be marginal
```

**Carbon Compliance Arbitrage**
```
EU vs UK ETS Spread:
  EU EUA: €85/tCO2
  UK UKA: £45/tCO2 (~€52)
  Spread: €33/tCO2

Trade (if allowed):
  Buy: UK UKA
  Sell: EU EUA
  Constraint: No direct trading (separate registries)
  Workaround: Physical delivery via interconnectors + surrender
```

### REC Vintage Arbitrage

**Time Decay Strategy**
```
Current_Vintage_Price = $10/MWh
1-Year_Old_Price = $9/MWh (-10%)
2-Year_Old_Price = $7.50/MWh (-25%)
3-Year_Old_Price = $6/MWh (-40%)

Strategy:
  Buy: 2-year-old vintage at $7.50
  Hold: Until compliance deadline (last minute buying)
  Sell: $9-9.50 (current vintage discount narrows as deadline approaches)
  Spread: $1.50-2/MWh
```

### Tax Credit Monetization

**ITC Sale to Tax Equity**
```
ITC_Value_Gross = $100M × 30% = $30M
Discount_Rate = 15-20% (buyer's hurdle rate)
ITC_Sale_Proceeds = $30M × 0.80 = $24M

Developer Capture: 80% of face value
Tax Equity Capture: 20% spread + partnership upside
```

**PTC Forward Sale**
```
PTC_Stream_10_Years = 500 GWh/yr × $27.50/MWh × 10 = $137.5M
NPV_at_8% = $92.3M
Sale_Price_at_12%_IRR_to_Buyer = $75-80M

Developer: Upfront capital for construction
Buyer: Locked-in tax credits at discount
```

---

## 8) KNOWN FLAWS & EXPLOITS

### Carbon Credit Market Flaws

**1. Phantom Credits (Additionality Fraud)**
```
Exploit: Claim credits for projects that would have happened anyway
Example: Hydroelectric dam built for power sales, not carbon credits
Detection: Additionality tests often rely on developer self-reporting
Impact: ~20-40% of forestry credits may not be additional (research estimates)

Smart Contract Mitigation:
  - Require oracle validation of "but-for" test
  - Compare project IRR with/without carbon revenue
  - Flag projects where carbon revenue < 10% of total revenue
```

**2. Double-Counting (Registry Arbitrage)**
```
Exploit: Retire same credit in multiple registries
Example:
  1. Issue credit in Verra Registry
  2. Corresponding adjustment not made in national inventory
  3. Same emission reduction claimed by country under Paris Agreement
  
Mitigation (Blockchain):
  - Universal serial hash: keccak256(projectId, vintage, serial)
  - Cross-registry lookup before issuance
  - RetirementLocker prevents re-issuance of retired serials
```

**3. Leakage (Displacement)**
```
Exploit: Protect forest A, but deforestation moves to forest B
Example: REDD+ project in Amazon; logging shifts 50km away
Detection: Satellite imagery + buffer zone monitoring
Impact: Reduces net climate benefit by 10-90% (varies by project)

Smart Contract Mitigation:
  - Require buffer zone attestations
  - Discount credits by leakage risk factor (e.g., 0.7× for high-risk areas)
```

**4. Permanence Risk (Reversals)**
```
Exploit: Forest burns/dies, releasing stored carbon
Example: Australian bushfires (2019-2020) released >400M tCO2
Insurance: Buffer pools (15-30% of credits held as insurance)

Smart Contract:
  - EscrowBuffer: Lock 20% of issued credits
  - On reversal event (oracle-triggered): Burn escrowed credits
  - Remaining credits remain valid
```

**5. Baseline Inflation**
```
Exploit: Exaggerate "business as usual" scenario to generate more credits
Example: Claim forest would have been 100% cleared (actually 20% risk)
Verification: Third-party validation (VVB - Validation & Verification Body)
Reality: VVBs paid by project developer (conflict of interest)

Mitigation:
  - DAO-governed baseline approval
  - Slashing for VVBs with high reversal rates
  - Public comment periods with whistleblower rewards
```

### REC Market Flaws

**1. Unbundled REC Greenwashing**
```
Exploit: Buy cheap RECs from distant location, claim "100% renewable"
Example:
  - Company in Texas buys hydro RECs from Oregon at $0.50/MWh
  - Claims "green power" but Texas grid still burns gas
  
Reality: No actual impact on local grid emissions

Mitigation:
  - Require time + location matching (hourly RECs)
  - Blockchain: Timestamp REC generation + consumption within same hour
  - Geographic constraint: RECs must be within same grid region
```

**2. Vintage Stacking (Compliance Arbitrage)**
```
Exploit: Hoard old-vintage RECs, dump before expiry
Example:
  - Buy 2020 RECs in 2020 at $5/MWh
  - Hold until 2023 (last year of validity)
  - Sell at $8/MWh to compliance entities rushing to meet deadline

Mitigation:
  - Expiry enforcement in smart contract
  - Automatic price decay function
```

**3. SREC Over-Supply Crashes**
```
Historical: New Jersey 2011-2013
  - SREC price: $650/MWh (2011) → $150/MWh (2013)
  - Cause: Faster-than-expected solar deployment
  - Result: Bankruptcies, policy revisions

Mitigation:
  - Dynamic supply caps in smart contracts
  - Price floors (SACP) enforced on-chain
```

### Tax Credit Fraud

**1. ITC Basis Inflation**
```
Exploit: Inflate project cost to claim higher ITC
Example:
  - Actual cost: $100M
  - Reported cost: $130M (30% markup via inflated equipment invoices)
  - ITC claimed: $39M (should be $30M)
  - Excess: $9M fraudulent claim

Detection: IRS audits, third-party appraisals
Penalty: Recapture + 20% penalty + interest

Smart Contract:
  - Oracle: Pull actual equipment costs from manufacturers
  - Public audit trail of invoices (IPFS hashes)
  - Compare claimed cost to industry benchmarks ($/W)
```

**2. PTC Deemed Generation Fraud**
```
Exploit: Claim PTC for electricity not actually generated
Example:
  - Wind farm claims 500 GWh/yr
  - Actually generated: 450 GWh/yr
  - False claim: 50 GWh × $27.50 = $1.375M

Detection: SCADA data vs claimed generation
Mitigation:
  - DeviceOracle with signed meter readings
  - Cross-check with grid operator settlement data
```

---

## 9) SMART CONTRACT ARCHITECTURE

### Full System Contracts (28 Total)

```
contracts/
  /identity
    IdentityNFT.sol              # Soulbound DID-linked identity
    AttestationRegistry.sol      # Verifiable credentials
    IdentityFactory.sol          # Batch onboarding
  
  /compliance
    ComplianceRegistry.sol       # Legacy (basic rules)
    RuleEngine.sol               # NEW: Advanced policy engine
    PolicyLibrary.sol            # Reusable policy templates
    JurisdictionMapper.sol       # ISO country → rules
  
  /licensing
    LicenseNFT.sol               # IP rights + royalty enforcement
    FeeRouter.sol                # Royalty collection & distribution
    RoyaltySplitter.sol          # Multi-beneficiary splits
  
  /oracles
    DeviceOracle.sol             # MRV data ingress (EIP-712 signed)
    PriceOracle.sol              # REC/carbon price feeds
    ComplianceOracle.sol         # Breach detection & suspension
    WeatherOracle.sol            # Solar irradiance, wind speed
  
  /tokens
    ERC1155REC.sol               # RECs/SRECs/GOs (multi-vintage)
    ERC1155Carbon.sol            # VCS/GS/ACR carbon credits
    ERC1400TaxEquity.sol         # Tax equity partnership tokens
    ERC3643_TREXAdapter.sol      # Securities compliance
    UNYToken.sol                 # Utility/settlement token
  
  /retirement
    RetirementLocker.sol         # Anti-double-count + registry bridge
    BufferPool.sol               # Permanence insurance (20% escrow)
    RetirementAttestation.sol    # Issues on-chain retirement VCs
  
  /markets
    RECMarketplace.sol           # Order book for REC trading
    CarbonMarketplace.sol        # Carbon credit trading
    AuctionHouse.sol             # Batch auctions (daily/weekly)
    OTCSettlement.sol            # Bilateral trade settlement
  
  /governance
    TimelockController.sol       # 24-48h delay on policy changes
    PolicyDAO.sol                # DAO governance for rule updates
    EmergencyPause.sol           # Circuit breaker
```

### Key Interactions

```
User Flow: REC Issuance
1. DeviceOracle.postReading(signedData) → validates ECDSA signature
2. AttestationRegistry.record(ENERGY_OUTPUT_v1, dataHash) → creates VC
3. RuleEngine.preMintCheck(issuer, REC_CLASS) → validates issuer VCs + license
4. ERC1155REC.mint(issuer, serialHash, amount) → issues tokens
5. FeeRouter.takeCut(ISSUANCE) → collects royalty → RoyaltySplitter

User Flow: Compliant Transfer
1. Buyer: Has valid KYC_v1, SANCTIONS_v1 VCs
2. ERC1155REC.safeTransferFrom(seller, buyer, tokenId, amount)
3. _beforeTokenTransfer hook → RuleEngine.preTransferCheck()
4. RuleEngine validates: buyer VCs, seller VCs, geo rules, license active
5. If valid: Transfer succeeds; if not: Revert with reason

User Flow: Retirement
1. Holder calls RetirementLocker.retire(tokenId, amount, evidenceCid, registryRef)
2. Locker locks tokens (burns or transfers to dead address)
3. Locker marks serialHash as retired (prevents re-issuance)
4. Off-chain bridge service posts registryRef confirmation
5. RetirementAttestation.issue(holder, RETIREMENT_v1, dataHash)
```

---

## 10) DEPLOYMENT PROCEDURES

### Phase 1: Core Infrastructure (Tonight)

```bash
# 1. Deploy identity layer
npm run deploy:identity      # IdentityNFT, AttestationRegistry

# 2. Deploy licensing layer
npm run deploy:licensing     # LicenseNFT, FeeRouter, RoyaltySplitter

# 3. Deploy compliance layer
npm run deploy:compliance    # RuleEngine, PolicyLibrary

# 4. Deploy oracles
npm run deploy:oracles       # DeviceOracle, PriceOracle, ComplianceOracle

# 5. Deploy tokens
npm run deploy:tokens        # ERC1155REC, ERC1155Carbon, ERC1400TaxEquity

# 6. Deploy retirement
npm run deploy:retirement    # RetirementLocker, BufferPool

# 7. Deploy markets
npm run deploy:markets       # RECMarketplace, CarbonMarketplace

# 8. Load policy packs
npm run set:policies         # Reads config/policy-packs/*.json

# 9. Issue licenses
LICENSE_TO=$ISSUER_ADDRESS npm run issue:license

# 10. Transfer ownerships
npm run transfer:multisig    # Timelock + Gnosis Safe
```

### Phase 2: Policy Configuration (Week 1)

```bash
# Load jurisdiction-specific rules
npm run load:policy:us       # US RPS, SREC markets
npm run load:policy:eu       # EU EECS, GO system
npm run load:policy:asia     # I-REC, J-Credit, etc.

# Configure tax equity structures
npm run config:tax:itc       # ITC partnership templates
npm run config:tax:ptc       # PTC monetization

# Set price oracles
npm run oracle:set:rec       # REC price feeds (S&P Global Platts)
npm run oracle:set:carbon    # Carbon price feeds (ICE, EEX)
```

### Phase 3: Integration & Testing (Week 2-3)

```bash
# Device onboarding
npm run onboard:facility     # Register facilities
npm run onboard:devices      # Register meters/inverters

# Test workflows
npm run test:rec:issuance    # End-to-end REC minting
npm run test:carbon:retire   # Retirement + registry bridge
npm run test:tax:equity      # Partnership flip mechanics

# Security audits
npm run audit:slither        # Static analysis
npm run audit:mythril        # Symbolic execution
npm run test:invariants      # Formal verification
```

---

## 11) ECONOMICS & PRICING MODELS

### REC Pricing Algorithm (On-Chain)

```solidity
function getRECPrice(
    bytes32 region,      // ERCOT, PJM, CAISO, etc.
    uint16 vintage,      // YYYYMM
    bytes32 technology   // SOLAR, WIND, HYDRO
) public view returns (uint256 pricePerMWh) {
    uint256 basePrice = priceOracle.getBaseREC();
    
    // Regional premium
    uint256 regionalMultiplier = regionMultipliers[region]; // bps
    uint256 regionalPrice = basePrice * regionalMultiplier / 10000;
    
    // Vintage discount (age-based decay)
    uint256 monthsOld = currentVintage() - vintage;
    uint256 vintageDiscount = monthsOld * 100; // -1% per month
    if (vintageDiscount > 4000) vintageDiscount = 4000; // Cap at -40%
    uint256 vintagePrice = regionalPrice * (10000 - vintageDiscount) / 10000;
    
    // Technology premium
    uint256 techMultiplier = technologyMultipliers[technology];
    pricePerMWh = vintagePrice * techMultiplier / 10000;
    
    return pricePerMWh;
}
```

### Carbon Credit Risk-Adjusted Pricing

```solidity
struct CarbonProject {
    bytes32 methodology;     // VM0042, ACM0002, etc.
    uint16 addionalityScore; // 0-10000 (DAO-voted)
    uint16 permanenceRisk;   // 0-10000 (higher = riskier)
    uint16 leakageRisk;      // 0-10000
    bool bufferRequired;     // true for forestry
    uint16 bufferPercent;    // 2000 = 20%
}

function getCarbonPrice(bytes32 projectId) public view returns (uint256) {
    CarbonProject memory proj = projects[projectId];
    uint256 basePrice = priceOracle.getBaseTCO2(); // e.g., $15/tCO2e
    
    // Additionality discount
    uint256 addPrice = basePrice * proj.addionalityScore / 10000;
    
    // Permanence discount
    uint256 permDiscount = proj.permanenceRisk * 50 / 10000; // -50% max
    uint256 permPrice = addPrice * (10000 - permDiscount) / 10000;
    
    // Leakage discount
    uint256 leakDiscount = proj.leakageRisk * 30 / 10000; // -30% max
    uint256 finalPrice = permPrice * (10000 - leakDiscount) / 10000;
    
    return finalPrice;
}
```

---

## NEXT STEPS FOR KEVAN

**Immediate (Tonight)**:
1. Fix hardhat cache: `npx hardhat clean`
2. Run preflight: `npm run preflight`
3. Choose deployment path:
   - Option A: Basic system (4 contracts) → `npm run deploy:polygon`
   - Option B: Full UNY-ID (7 contracts) → `npm run deploy:unyid:polygon`
   - **Option C: Complete Energy/Tax/Carbon (28 contracts)** → I'll create `deploy-full-energy-system.ts`

**Week 1**:
- Deploy full 28-contract system
- Load policy packs (US, EU, Asia)
- Issue pilot licenses
- Onboard 2-3 test facilities

**Week 2-3**:
- Integration testing
- Security audits
- Documentation
- Testnet → Mainnet migration

**Legal/IP** (Parallel Track):
- File US provisional patent (identity-bound MRV + anti-double-count)
- File trademarks (Unykorn, UNY-ID)
- Draft license terms v1.0 (upload to IPFS)

---

**Want me to create the master deployment script for all 28 contracts?** 🚀
