# Stocks and Bonds — Game Engine Specification

> **Consolidation note:** This document merges two prior drafts. Where the
> drafts conflicted, the resolution is documented inline. Unresolved gaps
> (per-security dividend rates; bond interest amounts) are flagged with
> **[DATA REQUIRED]** markers.

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

| ID | Name                |
|----|---------------------|
| 1  | Growth Corp         |
| 2  | Metro Properties    |
| 3  | Pioneer Mutual      |
| 4  | Shady Brooks        |
| 5  | Stryker Drilling    |
| 6  | Tri-City Transport  |
| 7  | United Auto         |
| 8  | Uranium Enterprises |
| 9  | Valley Power        |

Stock properties:

- `initialPrice` = 100
- `currentPrice` = INTEGER
- `dividendPerShare` = **[DATA REQUIRED]** per security
- `dividendsSuspended` = BOOLEAN (default: false)
- Certificates issued in lots of 10, 50, or 100 shares
- All transactions must be in round lots (multiples of 10)

### 2.2 Bonds

Three fixed-denomination bond instruments.

| Denomination | Par Value | Annual Interest |
|--------------|-----------|-----------------|
| Small        | 1,000     | **[DATA REQUIRED]** |
| Medium       | 5,000     | **[DATA REQUIRED]** |
| Large        | 10,000    | **[DATA REQUIRED]** |

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

- Net-positive effect cards → Bull
- Net-negative effect cards → Bear
- Explicit exception: Growth -8 / Metro -5 / United Auto -7 → Bear

### 4.3 Single-Stock Card Effects

| Stock           | Effects (priceDelta, or priceDelta & dividendBonus) |
|-----------------|-----------------------------------------------------|
| Growth Corp     | -10 / +10 / +8 / -8 / +10 & $2/share / -10         |
| Metro Properties| +5 / +10 / -5 / -10                                 |
| Pioneer Mutual  | none (appears in multi-stock cards only)             |
| Shady Brooks    | +5 / -5                                             |
| Stryker Drilling| +17 / -15 / -10                                     |
| Tri-City Transport | +15 / +10 / +5 / -5 / -25                       |
| United Auto     | +10 / +15 / +10 / -5 / -15 / -15                   |
| Uranium Enterprises | +10 / +10 / -25                                 |
| Valley Power    | -14 / +5 / +5                                       |

### 4.4 Multi-Stock Card Effects

| Stocks Affected                                     | Market |
|-----------------------------------------------------|--------|
| Pioneer +3, Valley +4                               | Bull   |
| Growth +8, Metro +5, Pioneer +5, United Auto +7     | Bull   |
| Pioneer -8, Stryker +8, Uranium +5                  | Bull   |
| Growth -8, Metro -5, United Auto -7                 | Bear   |

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

For each year in 1..10, execute the following phases in order:

```
1.  DrawSituationCard
2.  DetermineMarketType         (Bull or Bear from card)
3.  Roll2d6
4.  ApplyMarketTableDeltas      (per stock, from table)
5.  ApplyCardPriceDeltas        (per stock, from card effects)
6.  ResolvePerStockThresholds   (clamp, dividend flag, splits)
7.  ApplyDividendsAndInterest   (skip in Year 10)
8.  ApplyMarginInterest
9.  SellPhase
10. BuyPhase
11. CheckBankruptcy
```

Final year (Year 10) differences:

- Steps 7 (dividends and interest) are skipped.
- No new margin purchases may be made (Step 10 restricted).
- After Step 11: compute final wealth for all players.

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
    currentPrice = currentPrice / 2
    sharesOwned  = sharesOwned * 2
```

> **Resolution conflict note:** Draft 1 placed split resolution after the
> buy phase. Draft 2 placed it during per-stock price resolution (before
> dividends). Draft 2 ordering is used here because it is internally
> consistent with the engine execution order in both drafts and reflects
> standard board game rules (splits resolved before income is paid).

---

## 8. Dividends and Bond Interest (Step 7)

### 8.1 Stock Dividends

```
if NOT dividendsSuspended AND year < TotalYears:
    dividend = dividendPerShare * sharesOwned
    cashBalance += dividend

if cardHasDividendBonus:
    cashBalance += dividendBonusPerShare * sharesOwned
```

Bonus dividends from cards are applied regardless of `dividendsSuspended`
(the card explicitly grants them).

### 8.2 Bond Interest

```
if year < TotalYears:
    for each bondHolding:
        cashBalance += fixedInterestPerUnit * bondUnits
```

---

## 9. Margin System

### 9.1 Eligibility

- A player may not use margin until they have made at least one cash
  purchase in a prior year.
- No margin purchases are permitted in Year 10.

### 9.2 Margin Purchase

```
purchasePrice = shares * currentPrice
cashPayment   = purchasePrice * MarginRate       (50%)
marginPortion = purchasePrice * MarginRate       (50%)

cashBalance  -= cashPayment
marginTotal  += marginPortion
```

### 9.3 Annual Margin Interest (Step 8)

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

### 9.5 Repaying Margin

```
cashBalance  -= amountPaid
marginTotal  -= amountPaid
```

All outstanding margin must be cleared before Year 10 begins.

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

## 12. Bankruptcy

A player is eliminated when either condition below is true and cannot
be resolved through asset liquidation:

```
CONDITION A: cashBalance < 0 after margin interest charge
CONDITION B: cannot meet a margin call
```

Elimination procedure:

```
liquidate all remaining holdings (stocks at currentPrice, bonds at par)
if cashBalance still < 0:
    isBankrupt = true
    player removed from game
```

---

## 13. End of Game (Year 10)

After final prices are posted (no dividends or interest paid):

```
totalWealth =
    cashBalance
    + sum(sharesOwned[i] * currentPrice[i]  for each stock i)
    + sum(bondUnits[j]   * parValue[j]       for each bond j)
```

Player with highest `totalWealth` wins. Ties share the win.

---

## 14. Optional Rule Variants

### 14.1 Market Roll Mode

Three mutually exclusive options. Select one before game start.

| Option | Description |
|--------|-------------|
| A (Default) | Roll once per year; result applies to all stocks |
| B | Roll separately for each stock in Year 1 only; single roll thereafter |
| C | Roll separately for each stock every year |

> **Conflict note:** Draft 1 defined two variants (A and B), with B
> described as per-security rolling with a special 2/12 override rule.
> Draft 2 defined three variants (A, B, C) without the override rule.
> Both variant sets are preserved above. The 2/12 override from Draft 1
> is captured below.

### 14.2 Extreme Roll Override (Draft 1 Variant B)

When rolling per security:

```
if roll == 2 OR roll == 12:
    override all stock prices using the calculator value for that roll
```

This rule applies only if the per-security rolling variant is in use.

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

---

## 16. Open Items — DATA REQUIRED

The following values are not present in either source draft. They must
be sourced from the physical game components before implementation.

| Item | Used In |
|------|---------|
| `dividendPerShare` for each of the 9 stocks | Section 8.1 |
| `fixedInterestPerUnit` for each bond denomination | Section 8.2 |
| Whether dividend bonus cards are Bull or Bear classified | Section 4.2 |
| Total card count per single-stock effect (verify 36 total) | Section 4.1 |