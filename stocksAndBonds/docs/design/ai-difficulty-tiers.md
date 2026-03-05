# Stocks and Bonds — Computer Player Difficulty Tiers

---

## 1. Overview

This document defines three computer player difficulty tiers: Easy, Medium,
and Hard. Each tier is fully specified as a set of named parameters that
govern sell phase logic, buy phase logic, margin behavior, and endgame
behavior. All parameters trace directly to mechanics defined in the game
specification. No rules beyond the specification are introduced.

The baseline AI logic defined in `ai-player-logic.md` corresponds to
Medium difficulty. Easy and Hard are defined by deviation from that
baseline.

---

## 2. Design Principles

### Difficulty is expressed through parameter values, not separate procedures.

A single AI sell procedure and a single AI buy procedure implement all
three tiers. Tier-specific behavior is driven by a profile record passed
into each procedure as a parameter. This keeps the codebase maintainable
and ensures all tiers obey the same spec constraints.

### Easy AI makes identifiable strategic mistakes.

Easy does not cheat or ignore rules. It makes suboptimal but plausible
decisions: over-concentrating in one stock, buying bonds too eagerly,
holding distressed stocks too long, and ignoring endgame timing.

### Hard AI makes better use of every spec mechanic.

Hard uses margin, responds earlier to price deterioration, holds more
shares through splits, diversifies more aggressively, and shifts strategy
in the final years. It has no information advantage over human players.

### Integer representation for all fractional parameters.

Basic09 targets a 6809 processor. All fractional parameters are stored
as integer percentages (e.g., 40 represents 0.40). Procedures compute:

```
result := (value * paramPct) / 100
```

This avoids floating-point entirely, consistent with spec Section 15.

---

## 3. AIProfile TYPE Structure

The following TYPE is the canonical parameter record for all AI
procedures. One instance per computer-controlled player, initialized at
game start based on the selected tier.

```
TYPE AIProfile
    tier                : BYTE      ! 1=Easy  2=Medium  3=Hard
    concentrationCap    : BYTE      ! max pct of cash per stock purchase
    splitSellPct        : BYTE      ! pct of shares to sell at split threshold
    distressSellPrice   : BYTE      ! sell stock at or below this price
    zeroDivEligible     : BOOLEAN   ! allow zero-dividend stock purchases
    useYieldScoring     : BOOLEAN   ! apply yield scoring to buy candidates
                                    ! FALSE = all eligible stocks score equally
    useMargin           : BOOLEAN   ! allow margin purchases
    marginMaxExposure   : BYTE      ! max margin as pct of portfolio value
    marginBuffer        : BYTE      ! price points above MarginCallPrice required
    marginReservePct    : BYTE      ! interest burden pct that triggers repayment
    repayFraction       : BYTE      ! pct of cash applied to voluntary repayment
    marginClearYear     : BYTE      ! year at which proactive margin repayment begins
    bondIdleCash        : INTEGER   ! min cash before AI buys a bond
    bondPriority        : BOOLEAN   ! buy bonds even when stocks were purchased
    endgameYear         : BYTE      ! year at which late-game behavior activates
                                    ! 0 = no endgame mode
    splitSellPctEnd     : BYTE      ! endgame override for splitSellPct
    repayFractionEnd    : BYTE      ! endgame override for repayFraction
    bondIdleCashEnd     : INTEGER   ! endgame override for bondIdleCash
```

---

## 4. Tier Parameter Values

| Parameter            | Easy | Medium | Hard | Notes                                    |
|----------------------|------|--------|------|------------------------------------------|
| `tier`               | 1    | 2      | 3    |                                          |
| `concentrationCap`   | 70   | 40     | 25   | Percent of available cash per stock      |
| `splitSellPct`       | 20   | 50     | 30   | Percent of shares sold at price >= 150   |
| `distressSellPrice`  | 50   | 50     | 60   | Sell stock at or below this price        |
| `zeroDivEligible`    | TRUE | TRUE   | FALSE| Hard excludes zero-dividend stocks       |
| `useYieldScoring`    | FALSE| TRUE   | TRUE | Easy treats all stocks equally           |
| `useMargin`          | FALSE| FALSE  | TRUE | Hard may purchase on margin              |
| `marginMaxExposure`  | 0    | 0      | 30   | Percent; Hard caps margin at 30% of portfolio |
| `marginBuffer`       | 0    | 0      | 30   | Hard requires price >= $55 for margin buy|
| `marginReservePct`   | 20   | 10     | 5    | Interest threshold that triggers repayment|
| `repayFraction`      | 25   | 50     | 75   | Percent of cash used for margin repayment|
| `marginClearYear`    | 9    | 9      | 8    | Year at which proactive clearance begins |
| `bondIdleCash`       | 1000 | 5000   | 10000| Min cash before bond considered          |
| `bondPriority`       | TRUE | FALSE  | FALSE| Easy buys bonds even if stocks purchased |
| `endgameYear`        | 0    | 0      | 7    | Easy/Medium have no endgame mode         |
| `splitSellPctEnd`    | 20   | 50     | 70   | Easy/Medium match base; never activated |
| `repayFractionEnd`   | 25   | 50     | 90   | Easy/Medium match base; never activated |
| `bondIdleCashEnd`    | 1000 | 5000   | 5000 | Easy/Medium match base; never activated |

---

## 5. Tier Behavioral Profiles

### 5.1 Easy

Easy AI plays passively and conservatively. It commits too much capital
to its first good candidate (70% concentration cap), treats all stocks
equally regardless of yield, buys bonds even when better stock
opportunities exist, and does not adapt its strategy as Year 10
approaches. It will not go bankrupt under normal play, but it will
consistently underperform due to poor capital allocation.

Key mistakes:
- Puts up to 70% of available cash into the first eligible stock,
  leaving little for diversification.
- Does not apply yield scoring (`useYieldScoring = FALSE`). All eligible
  stocks are treated as equal candidates, processed in ascending stock
  ID order.
- Buys bonds after every turn regardless of stock availability
  (`bondPriority = TRUE`, `bondIdleCash = 1000`).
- Holds distressed stocks until price reaches the dividend cutoff ($50),
  the same threshold that suspends dividends — no anticipatory selling.
- Sells only 20% of shares at the split threshold, capturing minimal
  pre-split gains.
- Never uses margin.
- No endgame strategy shift.

### 5.2 Medium

Medium AI is the baseline defined in `ai-player-logic.md`. It uses
yield scoring to prefer high-dividend stocks, manages concentration at
40%, sells half its position before a split, holds bonds only when
idle, and performs voluntary margin repayment when the interest burden
exceeds 10% of available cash. It does not use margin and does not
adapt to late-game conditions.

### 5.3 Hard

Hard AI uses every spec mechanic competently. It diversifies more
aggressively (25% concentration cap), avoids zero-dividend stocks
entirely during normal play, and uses margin with defined risk controls.
It enters an endgame mode in Year 7 that shifts priorities toward
wealth preservation and gain capture.

Key advantages:
- Sells distressed stocks at $60 — above the dividend suspension
  threshold of $50 — anticipating deterioration before yield is lost.
- Sells only 30% before a split (holds more shares for post-split gains),
  versus Medium's 50%.
- Uses margin, but only for stocks priced at least $30 above the margin
  call threshold ($55 minimum), and only up to 30% of portfolio value.
- Repays margin aggressively (75% of available cash when the burden
  threshold is crossed).
- Begins proactive margin clearance in Year 8, avoiding forced
  liquidation at unfavorable prices in Year 10.
- Activates endgame mode in Year 7.

---

## 6. Endgame Mode (Hard Only, Year >= 7)

When `currentYear >= endgameYear (7)`, Hard AI applies the following
overrides. These replace the corresponding standard parameters for the
remainder of the game.

```
! Endgame overrides applied when currentYear >= aiProfile.endgameYear
! and aiProfile.tier = 3

splitSellPctW    := aiProfile.splitSellPctEnd  ! Sell aggressively before split; lock in gains
zeroDivEligibleW := FALSE                      ! Stop all speculative zero-dividend purchases
repayFractionW   := aiProfile.repayFractionEnd ! Clear margin as fast as possible
bondIdleCashW    := aiProfile.bondIdleCashEnd  ! Resume normal bond threshold (endgame cash matters)
```

Rationale per override:

- `splitSellPct = 70`: In final years, time to recover from a post-split
  drop is limited. Capturing gains before the split is more valuable late.
- `zeroDivEligible = FALSE`: Zero-dividend stocks provide no income and
  their price volatility is a liability with few years left. Hard AI
  exits speculative positions.
- `repayFraction = 90`: Outstanding margin in Year 9 is a risk. Hard AI
  clears it rapidly from Year 7 onward to enter Year 10 debt-free.
- `bondIdleCash = 5000`: Hard AI maintains the standard bond threshold
  in endgame rather than tightening further. Bond income in Years 7–9
  (three remaining dividend years) still contributes meaningfully.

---

## 7. Margin Risk Controls (Hard Only)

Margin purchases are permitted only when all of the following conditions
are true simultaneously:

```
CONDITION 1 — Eligibility (spec Section 9.1):
    hadPriorCashPurchase = TRUE
    AND currentYear < TotalYears

CONDITION 2 — Year proximity:
    currentYear < aiProfile.marginClearYear (8)
    ! No new margin purchases once clearance phase begins.

CONDITION 3 — Price buffer above margin call:
    currentPrice[i] >= (MarginCallPrice + aiProfile.marginBuffer)
    currentPrice[i] >= (25 + 30)
    currentPrice[i] >= 55

CONDITION 4 — Portfolio exposure cap:
    currentMarginTotal < (portfolioValue * aiProfile.marginMaxExposure / 100)
    ! portfolioValue = cashBalance
    !   + sum(sharesOwned[j] * currentPrice[j])
    !   + sum(bondUnits[k]   * parValue[k])
```

If any condition fails, Hard AI does not use margin for that purchase.
It falls back to a cash purchase if cash is available, or skips.

### Margin Purchase Sizing

When margin is used, Hard AI applies the same concentration cap as for
cash purchases, but calculates the lot size against the full purchase
cost (not just the 50% cash portion):

```
fullCost        := shares * currentPrice[i]
cashRequired    := fullCost / 2           ! MarginRate = 0.50
marginPortion   := fullCost / 2

maxFullCost     := availableCash * 2      ! leverage: cash covers 50%
capLimit        := portfolioValue * aiProfile.concentrationCap / 100
effectiveCap    := MIN(maxFullCost, capLimit)

maxLots := INT(effectiveCap / (currentPrice[i] * 10)) * 10
```

The concentration cap is applied against portfolio value (not just cash)
to prevent margin from creating runaway single-stock exposure.

---

## 8. Sell Rule Comparison by Tier

| Rule | Condition                                        | Easy         | Medium       | Hard              |
|------|--------------------------------------------------|--------------|--------------|-------------------|
| 1    | `currentPrice = 0`                               | Sell all     | Sell all     | Sell all          |
| 2    | `price <= 25` AND `marginHeld`                   | Sell all     | Sell all     | Sell all          |
| 3    | `price >= 150` (split threshold)                 | Sell 20%     | Sell 50%     | Sell 30% (70% endgame) |
| 4    | `dividendsSuspended AND price < distressSellPrice`| Price < 50  | Price < 50   | Price < 60        |
| 5    | Default                                          | Pass         | Pass         | Pass              |

Rule 4 differs: Hard AI's `distressSellPrice = 60` means it sells a
stock whose price has fallen below $60 AND whose dividends are suspended.
Since dividends suspend at $50 (`DividendCutoff`), this rule activates
only in the band $50–$59 for Hard, versus never in that band for Easy
and Medium (who require price below $50 AND suspended — a condition that
is only true at exactly $49 or lower, since suspension triggers when
price falls below $50).

---

## 9. Buy Rule Comparison by Tier

| Decision                         | Easy             | Medium           | Hard                  |
|----------------------------------|------------------|------------------|-----------------------|
| Concentration cap                | 70% per stock    | 40% per stock    | 25% per stock         |
| Zero-dividend stocks             | Eligible         | Eligible         | Ineligible (endgame+) |
| Yield scoring (`useYieldScoring`)| No (all equal)   | Yes              | Yes                   |
| Margin purchases                 | Never            | Never            | Yes (with controls)   |
| Margin repayment threshold       | 20% burden       | 10% burden       | 5% burden             |
| Cash applied to repayment        | 25%              | 50%              | 75%                   |
| Bond buy trigger                 | $1,000 idle      | $5,000 idle      | $10,000 idle          |
| Buys bonds if stocks also bought | Yes              | No               | No                    |
| Endgame behavior                 | None             | None             | Year 7+ overrides     |

---

## 10. Implementation Notes

### AIProfile Initialization

At game start, when a player slot is assigned the COMP type, the
procedure that initializes the player record also calls an AI profile
initialization procedure with the selected tier as input. The AIProfile
record is stored alongside the player record for the duration of the game.

### Endgame Check

The endgame check is performed once at the start of each AI player's
sell and buy phase:

```
IF aiProfile.endgameYear > 0 THEN
    IF currentYear >= aiProfile.endgameYear THEN
        ! Apply endgame overrides to local copies of parameters
        ! before executing sell/buy logic.
    ENDIF
ENDIF
```

Overrides are applied to local variables within the procedure, not to
the stored AIProfile record. The stored record retains the original
tier values throughout the game.

### Memory Budget

One AIProfile record per computer-controlled player. With up to 6
players and a TYPE of approximately 19 bytes, total AIProfile storage
is under 90 bytes. This is negligible within the 32KB variable memory
budget (spec Section 15).