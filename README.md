# ERC20/WETH Swap Execution vs Fair Value Model

Analyzes real swap execution prices for ERC20/WETH Uniswap V2 pools and compares them against fair-value pricing to quantify true market impact and trader pressure.

**Overview**  
This project reconstructs actual execution prices directly from raw Uniswap V2 swap events and compares them against external fair-value pricing.

The goal is to understand whether trades are moving the market efficiently or creating persistent price deviations driven by buy or sell pressure.

**Dashboard**  
Platform: Dune Analytics  
Scope: Uniswap V2 (Ethereum)  
Pair type: ERC20/WETH  
Example pair: TOO/WETH  

🔗 Dune dashboard link:  
https://dune.com/jayqxr/real-swap-impact-erc20-weth-memecoin-microstructure?utm_source=share&utm_medium=copy&utm_campaign=dashboard

**What this model shows**
- Real swap execution price derived from on-chain events
- Fair-value price reference from Dexscreener
- Execution vs fair-value price deviation
- Buy vs sell pressure classification
- Hourly aggregated execution metrics

**Data sources**
- On-chain Uniswap V2 swap events (raw decoded)
- Dexscreener fair-value pricing
- WETH USD pricing via prices.usd

**Notes & limitations**
- Analysis focuses on executed swaps only
- Fair value is treated as an external reference, not ground truth
- Designed for volatile ERC20/WETH pools (memecoins and microcaps)

**SQL query**  
The full SQL query used for this analysis is available in this repository:

`sql/price_impact_uniswap.sql`

This query:
- decodes raw swap events
- reconstructs execution prices
- classifies directional pressure
- aggregates metrics on an hourly basis


