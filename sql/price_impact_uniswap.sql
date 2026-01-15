WITH swap_event AS ( 
    SELECT
        DATE_TRUNC('minute', block_time) AS time_swap,
        contract_address,
        bytearray_to_uint256(bytearray_substring(data, 1, 32)) / 1e18 AS amount0_in,
        bytearray_to_uint256(bytearray_substring(data, 33, 32)) / 1e18 AS amount1_in,
        bytearray_to_uint256(bytearray_substring(data, 65, 32)) / 1e18 AS amount0_out,
        bytearray_to_uint256(bytearray_substring(data, 97, 32)) / 1e18 AS amount1_out
    FROM 
        ethereum.logs
    WHERE
        topic0 = 0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822
    AND 
        contract_address = 0x9608a52E0b9BC05BFF33BE175D9769C40E5EF600
    AND
        block_time > CURRENT_DATE - INTERVAL '7' day
),

price AS ( 
    SELECT
        "minute",
        price AS quote_token_price_usd
    FROM
        prices.usd
    WHERE 
        blockchain = 'ethereum'
    AND 
        contract_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    AND 
        "minute" > CURRENT_DATE - INTERVAL '7' day 
),

pool_metadata AS ( 
    SELECT 
        CAST(json_extract_scalar(response,'$.pairs[0].priceUsd') AS DOUBLE) AS base_token_price_usd,
        json_extract_scalar(response,'$.pairs[0].pairAddress') AS pool_address
    FROM (
        SELECT json_parse(
            http_get('https://api.dexscreener.com/latest/dex/pairs/ethereum/0x9608a52E0b9BC05BFF33BE175D9769C40E5EF600')
        ) AS response
    )
),

pre_agg AS (
    SELECT
        DATE_TRUNC('hour', s.time_swap) AS hours,
        s.amount0_in,
        s.amount0_out,
        s.amount1_in,
        s.amount1_out,
        a.quote_token_price_usd,
        p.base_token_price_usd,

        CASE 
            WHEN s.amount0_in > s.amount0_out THEN 'sold_token0'
            WHEN s.amount0_out > s.amount0_in THEN 'bought_token0'
        END AS trade_direction,

        CASE
            WHEN s.amount0_out > 0 THEN (s.amount1_in * a.quote_token_price_usd) / NULLIF(s.amount0_out, 0)
            WHEN s.amount0_in > 0 THEN (s.amount1_out * a.quote_token_price_usd) / NULLIF(s.amount0_in, 0)
        END AS implied_token0_price_usd
    FROM 
        swap_event s
    LEFT JOIN price a 
        ON a.minute = s.time_swap   
    CROSS JOIN pool_metadata p       
),

final_cte AS (
    SELECT
        hours,
        SUM(amount0_out) AS memecoin_quantity_bought_token0,
        SUM(amount0_in) AS memecoin_quantity_sold_token0,
        SUM(amount1_in * quote_token_price_usd) AS WETH_price_bought_token1_usd,
        SUM(amount1_out * quote_token_price_usd) AS WETH_price_sold_token1_usd,
        AVG(base_token_price_usd) AS base_token_price_usd,
        AVG(implied_token0_price_usd) AS implied_token0_price_usd
    FROM 
        pre_agg
    GROUP BY 1   
)
SELECT
     *,
     ((implied_token0_price_usd - base_token_price_usd) / base_token_price_usd) * 100 AS price_deviation_pct,
    CASE WHEN ((implied_token0_price_usd - base_token_price_usd) / base_token_price_usd) * 100 > 0
         THEN ((implied_token0_price_usd - base_token_price_usd) / base_token_price_usd) * 100 END AS positive_deviation,
    CASE WHEN ((implied_token0_price_usd - base_token_price_usd) / base_token_price_usd) * 100 <= 0
         THEN ((implied_token0_price_usd - base_token_price_usd) / base_token_price_usd) * 100 END AS negative_deviation
FROM final_cte;
