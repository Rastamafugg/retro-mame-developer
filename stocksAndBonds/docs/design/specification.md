# Stocks and Bonds — Game Engine Specification

Status: Current  
Authority: Gameplay and rules behavior  
Depends on: `stocks-and-bonds-rules.md`  
Supersedes: Conflicting gameplay statements in `project-timeline.md`,
`forkio-plan.md`, and `module-phase-transition.md`

---

## 0. Project Interpretations

This document is the canonical source for project behavior when the original
Avalon Hill rules are ambiguous or when the project intentionally extends the
base game.

### 0.1 Base game and extensions

- The original game is a fixed 10-year game.
- This project keeps 10 years as the default and rules-faithful mode.
- The engine may support a configurable `maxYears` as a project extension.
  Any extension must preserve the 10-year rules behavior when `maxYears = 10`.

### 0.2 Locked interpretations of ambiguous rules

- Year 10 is treated like Years 2-9 for dividends, bond interest, and annual
  margin charges.
- No new margin purchases are permitted in Year 10.
- All outstanding margin must be cleared before the end of Year 10.
- In the optional per-security rolling mode, if a 2 or 12 is rolled, all stock
  prices for that year are recalculated from that single roll value.
- If multiple players tie for highest wealth, all tied players share the win.
- In multiplayer games, if only one non-bankrupt player remains, that player is
  prompted to either accept the win immediately or continue play through the
  configured final year.
- In a single-player game, play continues through the configured final year
  unless the player goes bankrupt.

---

## 1. Constants

| Constant              | Value  | Notes                                      |
|-----------------------|--------|--------------------------------------------|
| `StartingCash`        | 5000   | Each player begins with $5,000             |
| `TotalYears`          | 10     | Game runs for exactly 10 years             |
| `StockStartPrice`     | 100    | All stocks open at $100                    |
| `StockSplitThreshold` | 150    | Price at or above which a split triggers   |
| `StockSplitRatio`     | 2      | Split halves price, doubles shares         |
| `DividendCutoff`      | 50     | Price below which dividends are suspended  |
| `BankruptcyPrice`     | 0      | Price floor; holdings zeroed at this level |
| `MarginRate`          | 0.50   | Buyer pays 50%; 50% recorded as margin     |
| `MarginInterestRate`  | 0.05   | Annual charge on outstanding margin total  |
| `MarginCallPrice`     | 25     | Margin call triggered at or below $25      |
| `ValidDiceRolls`      | 2–12   | Inclusive range from 2d6                   |

---

## 2. Assets

### 2.1 Stocks

Nine (9) traded securities. All start at $100.

| ID | Name                | Dividend Per Share |
|----|---------------------|--------------------|
| 1  | Growth Corp         | $1                 |
| 2  | Metro Properties    | $0 (no yield)      |
| 3  | Pioneer Mutual      | $4                 |
| 4  | Shady Brooks        | $7                 |
| 5  | Stryker Drilling    | $0 (no yield)      |
| 6  | Tri-City Transport  | $0 (no yield)      |
| 7  | United Auto         | $2                 |
| 8  | Uranium Enterprises | $6                 |
| 9  | Valley Power        | $3                 |

Stock properties:

- `initialPrice` = 100
- `currentPrice` = INTEGER
- `dividendPerShare` = INTEGER (see table above; 0 for no-yield stocks)
- `dividendsSuspended` = BOOLEAN (default: false)
- Certificates issued in lots of 10, 50, or 100 shares
- All transactions must be in round lots (multiples of 10)

### 2.2 Bonds

Three fixed-denomination bond instruments.

| Denomination | Par Value | Annual Interest (5%) |
|--------------|-----------|----------------------|
| Small        | 1,000     | $50                  |
| Medium       | 5,000     | $250                 |
| Large        | 10,000    | $500                 |

Bond properties:

- Price never fluctuates
- Sold and redeemed at par
- Not affected by Situation Cards
- Not subject to splits, dividend suspension, or bankruptcy

---

## 3. Player State

```
Player {
    cashBalance      : INTEGER   (init: 5000)
    holdings {
        stockId      → sharesOwned : INTEGER
        bondId       → bondUnits   : INTEGER
    }
    marginTotal      : INTEGER   (init: 0)
    marginChargesDue : INTEGER
    isBankrupt       : BOOLEAN   (init: false)
}
```

---

## 4. Situation Cards

### 4.1 Deck Structure

- Total cards: 36 (18 Bull, 18 Bear)
- Each card specifies:
  - `marketType`: BULL or BEAR
  - `effects`: list of `{ stockId, priceDelta }` pairs
  - `dividendBonusPerShare` (optional; applies immediately)
- City Bonds are not affected by any card.

### 4.2 Card Classification Rule

Physical card classification is authoritative. Sign of price delta does not reliably
predict market type; four confirmed cards deviate from the sign-based heuristic:

| Card | Effects | Confirmed Type | Note |
|------|---------|----------------|------|
| 1  | Growth Corp +10 & $2/share | Bear | Positive delta, Bear card |
| 5  | Growth Corp -10            | Bull | Negative delta, Bull card |
| 8  | Metro Properties +10       | Bear | Positive delta, Bear card |
| 18 | Tri-City Transport +5      | Bear | Positive delta, Bear card |

The only reliable classification rule: use the physical card's market type field directly.
The deck contains exactly 18 Bull cards and 18 Bear cards.

### 4.3 Complete Card Reference

One card (Card 1) carries a `dividendBonusPerShare` of $2. It is the only such card.

| #  | Type | Stocks Affected                                              | Flavour Text |
|----|------|--------------------------------------------------------------|--------------|
|  1 | Bear | Growth Corp +10 & $2/share dividend bonus                    | Extra year-end dividend of $2 per share declared by the Board of Directors. |
|  2 | Bull | Growth Corp +10                                              | Corporation announces new metal forming process which it claims will revolutionize all metal-working industries covered by U.S. and foreign patents. |
|  3 | Bull | Growth Corp +8                                               | Corporation releases high profit and sales financial report and announces plans to invest an additional $2 million on special research projects next year. |
|  4 | Bear | Growth Corp -8                                               | Two founders and major stockholders of the Corporation disagree on policy. One sells out his entire stockholdings. |
|  5 | Bull | Growth Corp -10                                              | Corporation unexpectedly relinquishes its monopoly on its major product after a lengthy anti-trust suit. |
|  6 | Bear | Growth Corp -10                                              | President, Vice-President, and Chief Counsel of Growth Corporation of America reach retirement age. |
|  7 | Bull | Metro Properties +5                                          | National firm leases Company's largest office building. |
|  8 | Bear | Metro Properties +10                                         | City Council considers the Company's choicest property for large industrial fair. |
|  9 | Bear | Metro Properties -5                                          | Company's Annual Report shows net earnings off during fourth quarter. |
| 10 | Bear | Metro Properties -10                                         | Urban Renewal Program delayed by indecision of City Planning Commission. |
| 11 | Bull | Shady Brooks +5                                              | Influx of personnel of new company in nearby town creates a severe housing shortage. |
| 12 | Bear | Shady Brooks -5                                              | Community steadily deteriorates. The management is forced to lower rental rates to attract tenants. |
| 13 | Bull | Stryker Drilling +17                                         | Large petroleum corporation offers to buy all assets for cash. Offer is well above book value. Directors approve and will submit recommendation to stockholders. |
| 14 | Bear | Stryker Drilling -15                                         | Internal Revenue depletion allowance reduced 50%. |
| 15 | Bear | Stryker Drilling -10                                         | Land rights litigation holds up progress. |
| 16 | Bull | Tri-City Transport +15                                       | Company lands ten-year contract with large industrial equipment corporation. |
| 17 | Bull | Tri-City Transport +10                                       | Intensive advertising campaign gains Company three major, long-term contracts. |
| 18 | Bear | Tri-City Transport +5                                        | Company moves to a new excellent location. |
| 19 | Bear | Tri-City Transport -5                                        | President hospitalized in sanitorium for an indefinite period. |
| 20 | Bear | Tri-City Transport -25                                       | Large terminal destroyed by fire; insufficient insurance on building due to Company's delayed move to new location. |
| 21 | Bull | United Auto +10                                              | Three-for-one split rumoured. |
| 22 | Bull | United Auto +15                                              | President announces expansion plans to increase productive capacity 30%. |
| 23 | Bull | United Auto +10                                              | United Auto announces new advanced-design auto entry in the mini-car field. |
| 24 | Bear | United Auto -5                                               | Competitor invents a new economical automatic transmission. |
| 25 | Bear | United Auto -15                                              | Foreign car rage hits the buying public. Big cars in slow demand. |
| 26 | Bear | United Auto -15                                              | Strikes halt production in all eight United Auto plants as UAW and Company officials fail to reach agreement on labour contract. |
| 27 | Bull | Uranium Enterprises +10                                      | Company prospectors find huge, new high-grade ore deposits. |
| 28 | Bull | Uranium Enterprises +10                                      | Experimental nuclear power station proves more economical than anticipated. Three electrical power companies announce plans to build large-scale nuclear power plants. |
| 29 | Bear | Uranium Enterprises -25                                      | Government suddenly announces it will no longer support ore prices, since it has large stockpiles. |
| 30 | Bull | Valley Power +5                                              | Major coal company announces reduced coal prices to electric power utilities. |
| 31 | Bull | Valley Power +5                                              | Commission grants permission to construct a new nuclear generating plant of great capacity and efficiency. |
| 32 | Bear | Valley Power -14                                             | Public Utility Commission rejects Company's request for rate hike. |
| 33 | Bull | Pioneer Mutual +3, Valley Power +4                           | Buying wave raises market. |
| 34 | Bull | Growth Corp +8, Metro Properties +5, Pioneer Mutual +5, United Auto +7 | General market rise over the last two months. |
| 35 | Bull | Pioneer Mutual -8, Stryker Drilling +8, Uranium Enterprises +5 | War scare promotes mixed activity on Wall Street. |
| 36 | Bear | Growth Corp -8, Metro Properties -5, United Auto -7          | Surge of profit taking drops stock market. |

---

## 5. Market Price Tables

After the Situation Card sets `marketType`, roll 2d6 and look up each
stock's price delta in the table for that market type.

### 5.1 Bull Market

| Stock               |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  | 10  | 11  | 12  |
|---------------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Growth Corp         |  -2 |  26 |  18 |  23 |  20 |  17 |  19 |  11 |  13 |  14 |  24 |
| Metro Properties    | -10 |  16 |  23 |  28 |  15 |  21 |  24 |  18 |  31 |  -8 |  24 |
| Pioneer Mutual      |  -7 |  25 |  11 |  -2 |  15 |  13 |  17 |  14 |   1 |  19 |  23 |
| Shady Brooks        |  -9 |   8 |  12 |  11 |   7 |  -2 |   9 |  11 |  14 |  -1 |  20 |
| Stryker Drilling    |  -2 | -14 |  46 |  56 | -20 |  37 |  -5 |  67 | -11 |  -9 |  51 |
| Tri-City Transport  |  -9 |  21 |  18 |  19 |  15 |  23 |  26 |  15 |  18 |  25 |  27 |
| United Auto         |  -7 |  14 |  -5 |  30 |  13 |  23 |  13 |  22 |  18 | -10 |  38 |
| Uranium Enterprises | -16 |  -4 |  34 |  29 | -10 |  19 |  -7 |  18 | -14 |  13 |  33 |
| Valley Power        |  -4 |  17 |  15 |  14 |  12 |  14 |  15 |  13 |  10 |  19 |  18 |

### 5.2 Bear Market

| Stock               |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  | 10  | 11  | 12  |
|---------------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Growth Corp         |  12 |   7 |   9 |   7 |   8 |   6 |   5 |  -2 |  11 |  -5 |  -8 |
| Metro Properties    |  14 |  -6 |  10 |   8 |   6 |   4 |   7 |   6 |  11 |  13 | -10 |
| Pioneer Mutual      |  13 |  10 |   7 |   5 |   4 |   3 |  -1 |  -3 |  -5 |  -8 | -10 |
| Shady Brooks        |  10 | -10 |  -5 |  -6 |  -4 |   3 |  -3 |  -8 |  -7 |   6 | -15 |
| Stryker Drilling    |  10 |  30 | -20 | -40 |  40 | -15 |  45 | -20 |  30 |  25 | -20 |
| Tri-City Transport  |  20 |   6 |  12 |   3 |   8 |   5 |   6 |   7 |  10 |   4 | -20 |
| United Auto         |  21 | -19 |  21 |  16 |   4 |   8 | -10 |  10 | -11 |  18 | -23 |
| Uranium Enterprises |  25 |  22 |  18 | -14 | -12 |  -8 |  10 |  14 | -18 | -22 | -25 |
| Valley Power        |   8 |  -2 |   7 |   4 |   3 |   5 |   4 |   6 |  -4 |  -4 |  -7 |

---

## 6. Annual Year Loop

For each year in `1..maxYears`, execute the following phases in order:

```
1.  ApplyDividendsAndInterest   (skip in Year 1 only)
2.  ApplyMarginInterest
3.  DrawSituationCard
4.  DetermineMarketType         (Bull or Bear from card)
5.  Roll2d6
6.  ApplyMarketTableDeltas      (per stock, from table)
7.  ApplyCardPriceDeltas        (per stock, from card effects)
8.  ResolvePerStockThresholds   (clamp, dividend flag, splits)
9.  SellPhase
10. BuyPhase
11. CheckBankruptcyAndSurvivorState
```

First year (Year 1) differences:

- Steps 1 & 2 (dividends and interest) are skipped.
- Step 9 (sell phase) is skipped.

Final year (`year = maxYears`) differences:

- Step 1 and Step 2 still execute.
- No new margin purchases may be made (Step 10 restricted).
- All outstanding margin must be cleared before the end-of-game wealth
  calculation.
- After Step 11: perform one closing market draw using a new Situation Card
  and dice roll(s), resolved the same way as a normal market step, to post
  final prices.
- After that closing-price draw: compute final wealth for all players.

---

## 7. Per-Stock Price Resolution (Step 6)

Applied to each stock after market table and card deltas are summed:

```
newPrice = currentPrice + marketTableDelta + cardDelta

if newPrice < 0:
    newPrice = 0

currentPrice = newPrice

if currentPrice < DividendCutoff:
    dividendsSuspended = true
else:
    dividendsSuspended = false

if currentPrice >= StockSplitThreshold:
    currentPrice = currentPrice / 2 (round fractions up)
    sharesOwned  = sharesOwned * 2
```

---

## 8. Dividends and Bond Interest (Step 1)

### 8.1 Stock Dividends

```
if NOT dividendsSuspended AND year > 1:
    dividend = dividendPerShare * sharesOwned
    cashBalance += dividend

if cardHasDividendBonus:
    cashBalance += dividendBonusPerShare * sharesOwned
```

Bonus dividends from cards are applied regardless of `dividendsSuspended`
(the card explicitly grants them).

### 8.2 Bond Interest

```
if year > 1:
    for each bondHolding:
        cashBalance += fixedInterestPerUnit * bondUnits
```

---

## 9. Margin System

### 9.1 Eligibility

- A player may not use margin until they have made at least one cash
  purchase in a prior year.
- No margin purchases are permitted in the final year.

### 9.2 Margin Purchase

```
purchasePrice = shares * currentPrice
cashPayment   = purchasePrice * MarginRate       (50%)
marginPortion = purchasePrice * MarginRate       (50%)

cashBalance  -= cashPayment
marginTotal  += marginPortion
```

### 9.3 Annual Margin Interest (Step 2)

```
marginCharge  = marginTotal * MarginInterestRate
cashBalance  -= marginCharge
```

If `cashBalance` becomes negative after deducting margin interest:

```
force_sell_assets_until_cash_sufficient()
if cashBalance still < 0:
    isBankrupt = true
```

### 9.4 Margin Call

Triggered if `currentPrice <= MarginCallPrice` (i.e., price falls to $25
or below):

```
margin_balance_due_immediately()
```

If `currentPrice <= BankruptcyPrice` (price reaches $0):

```
sharesOwned = 0          (stock surrendered)
marginBalance still due  (debt does not forgive)
```

On the next year's market resolution pass, any stock whose carried price is $0
is re-established at $100 before applying that year's market-table and card
effects.

### 9.5 Repaying Margin

```
cashBalance  -= amountPaid
marginTotal  -= amountPaid
```

All outstanding margin must be cleared before end-of-game wealth is computed in
the final year. No new margin purchases may be made during that year.

---

## 10. Buying Rules

### 10.1 Cash Purchase — Stock

```
cost = shares * currentPrice
if cashBalance >= cost:
    cashBalance      -= cost
    holdings[stock]  += shares
```

`shares` must be a positive multiple of 10.

### 10.2 Margin Purchase — Stock

See Section 9.2. Same share-lot rule applies.

### 10.3 Bond Purchase

```
cashBalance      -= parValue
holdings[bond]   += 1
```

Bond price is always par; no partial bond units.

---

## 11. Selling Rules

### 11.1 Stock

```
proceeds             = sharesSold * currentPrice
cashBalance         += proceeds
holdings[stock]     -= sharesSold
```

`sharesSold` must be a positive multiple of 10 and
`<= holdings[stock]`.

### 11.2 Bond

```
proceeds             = parValue
cashBalance         += proceeds
holdings[bond]      -= 1
```

### 11.3 Margin-Held Stock

When selling stock purchased on margin, the associated margin balance
must be repaid immediately from the sale proceeds.

---

## 12. Bankruptcy and Survivor State

A player is eliminated when either condition below is true and cannot
be resolved through asset liquidation:

```
CONDITION A: cashBalance < 0 after margin interest charge
CONDITION B: cannot meet a margin call
```

Elimination procedure:

```
allow player to liquidate some or all remaining holdings (stocks at currentPrice, bonds at par) until market call is paid.

once all remaining holdings are sold, if cashBalance still < 0:
    isBankrupt = true
    player removed from game
```

If a multiplayer game reaches a state where only one non-bankrupt player
remains:

```
prompt remaining player:
    ACCEPT_WIN_NOW or CONTINUE_PLAY
```

If the remaining player accepts the win, the game ends immediately.
If the remaining player continues, the game proceeds through the configured
final year. Single-player games do not use this prompt.

---

## 13. End of Game (Final Year)

After the configured final year ends, one closing-price draw is resolved and
those closing prices are posted:

```
totalWealth =
    cashBalance
    + sum(sharesOwned[i] * currentPrice[i]  for each stock i)
    + sum(bondUnits[j]   * parValue[j]       for each bond j)
```

Player with highest `totalWealth` wins. If two or more players tie for highest
wealth, all tied players share the win.

---

## 14. Optional Rule Variants

### 14.1 Market Roll Mode

Three mutually exclusive options. Select one before game start.

| Option | Description |
|--------|-------------|
| A (Default) | Roll once per year; result applies to all stocks |
| B | Roll separately for each stock in Year 1 only; single roll thereafter |
| C | Roll separately for each stock every year |

### 14.2 Market Roll Mode Option C Additional Rule

When rolling per security:

```
if roll == 2 OR roll == 12:
    discard all prior per-security results for that year
    override all stock prices using the market-table value for that roll
```

This rule applies only if the per-security rolling variant (C) is in use.

---

## 15. Implementation Constraints

- All price changes are additive integers; no floating-point required
  for price tracking.
- Share counts are always integer multiples of 10.
- Bond holdings are discrete integer units.
- Variable memory budget: 32KB hard limit on Basic09 target platform.
  Array sizes must be sized accordingly.
- Order of operations within each year must be deterministic and
  consistent across all players before advancing to the next phase.

