# Stocks and Bonds — Computer Player Decision Logic

---

## 1. Scope and Constraints

This document specifies the decision logic for computer-controlled players
in the Stocks and Bonds game. It is the authoritative reference for authors
writing the AI sell and buy phase procedures.

All tier-specific parameter values are defined in `ai-difficulty-tiers.md`.
That document defines the `AIProfile` TYPE structure, per-tier values, and
endgame override values. This document defines how those parameters are
applied within the sell and buy phase logic.

### What the AI Knows

The computer player has access to the same information a human player can
see at the time of their turn:

- Current price of all 9 stocks
- Current bond par values and interest rates (fixed; never change)
- Their own cash balance, margin total, and portfolio holdings
- Whether dividends are suspended per stock
- The current year number

### What the AI Does Not Know

- Future dice rolls or situation card draws
- Other players' portfolios or cash balances
- Which cards remain in the deck

### Hard Constraints from Specification

All AI decisions must comply with the same rules that govern human players:

- Share quantities must be positive multiples of 10 (spec Section 10–11)
- No margin purchases until at least one prior cash purchase (spec Section 9.1)
- No margin purchases in Year 10 (spec Section 9.1)
- All margin must be cleared before Year 10 buy phase (spec Section 9.1)
- Cannot sell more shares than owned (spec Section 11.1)
- Cannot sell more bond units than held (spec Section 11.2)
- Cash balance cannot go below zero from a voluntary purchase

---

## 2. AIProfile Reference

All behavioral parameters are sourced from an `AIProfile` record passed
into each AI procedure. The TYPE definition and per-tier values are
specified in `ai-difficulty-tiers.md` Sections 3 and 4.

Parameters used in this document:

| AIProfile Field      | Type    | Used In     | Purpose                                         |
|----------------------|---------|-------------|-------------------------------------------------|
| `concentrationCap`   | BYTE    | Buy Step 4a | Max percent of available cash per stock         |
| `splitSellPct`       | BYTE    | Sell Rule 3 | Percent of shares to sell at split threshold    |
| `distressSellPrice`  | BYTE    | Sell Rule 4 | Price at or below which distressed stock is sold|
| `zeroDivEligible`    | BOOLEAN | Buy Step 3  | Whether zero-dividend stocks are buy candidates |
| `useMargin`          | BOOLEAN | Buy Step 2  | Whether margin purchases are permitted          |
| `marginMaxExposure`  | BYTE    | Buy Step 4b | Max margin as percent of portfolio value        |
| `marginBuffer`       | BYTE    | Buy Step 4b | Required price points above MarginCallPrice     |
| `marginReservePct`   | BYTE    | Buy Step 1  | Interest burden percent that triggers repayment |
| `repayFraction`      | BYTE    | Buy Step 1  | Percent of cash applied to voluntary repayment  |
| `marginClearYear`    | BYTE    | Sell 4.4    | Year at which proactive margin clearance begins |
| `bondIdleCash`       | INTEGER | Buy Step 5  | Minimum cash before bond purchase considered    |
| `bondPriority`       | BOOLEAN | Buy Step 5  | Buy bonds even when stocks were purchased       |
| `endgameYear`        | BYTE    | Sections 3–5| Year at which endgame overrides activate        |
| `useYieldScoring`    | BOOLEAN | Buy Step 3  | Whether yield scoring is applied to candidates  |

All fractional parameters (`concentrationCap`, `splitSellPct`,
`marginReservePct`, `repayFraction`, `marginMaxExposure`) are stored as
integer percentages. Procedures apply them as:

```
result := (value * paramPct) / 100
```

No floating-point arithmetic is used, consistent with spec Section 15.

---

## 3. Endgame Override Application

When `aiProfile.endgameYear > 0` and `currentYear >= aiProfile.endgameYear`,
the AI applies override values to local working copies of the affected
parameters before executing sell or buy logic. The stored `AIProfile`
record is never modified; overrides apply only within the current
procedure call.

```
! Applied once at the start of each AI sell or buy procedure call.
! Copy AIProfile fields to local working variables, then override.

splitSellPctW    := aiProfile.splitSellPct
zeroDivEligibleW := aiProfile.zeroDivEligible
repayFractionW   := aiProfile.repayFraction
bondIdleCashW    := aiProfile.bondIdleCash

IF aiProfile.endgameYear > 0 THEN
    IF currentYear >= aiProfile.endgameYear THEN
        ! Override values are defined in ai-difficulty-tiers.md Section 6.
        splitSellPctW    := aiProfile.splitSellPct    ! endgame value from tiers
        zeroDivEligibleW := FALSE
        repayFractionW   := aiProfile.repayFraction   ! endgame value from tiers
        bondIdleCashW    := aiProfile.bondIdleCash    ! endgame value from tiers
    ENDIF
ENDIF

! All subsequent sell and buy logic references the W (working)
! variables, not the aiProfile fields directly.
! Parameters not overridden in endgame are referenced from
! aiProfile throughout: concentrationCap, distressSellPrice,
! marginBuffer, marginMaxExposure, marginReservePct,
! bondPriority, marginClearYear.
```

Endgame override values are defined in `ai-difficulty-tiers.md` Section 6.
Easy and Medium have `endgameYear = 0` (see Section 4), so the override
block is never entered.

---

## 4. Sell Phase Logic

The AI evaluates each holding independently in a fixed priority order.
Rules are applied top-down; the first matching rule governs the decision
for that holding. Endgame overrides (Section 3) are applied before this
logic executes.

### 4.1 Priority Order — Stock Holdings

```
FOR each stock i where sharesOwned[i] > 0:

    RULE 1 — Bankrupt stock (price = 0):
        IF currentPrice[i] = BankruptcyPrice THEN
            SELL all shares[i]
            ! Spec zeros holdings at this price anyway.
            ! Selling explicitly clears the position cleanly.

    RULE 2 — Margin call imminent (price at or below call threshold):
        ELSE IF currentPrice[i] <= MarginCallPrice AND marginHeld[i] THEN
            SELL all shares[i]
            ! Preempt the forced margin call. Selling now recovers
            ! proceeds; waiting risks forced liquidation at the same
            ! or lower price.
            ! marginHeld[i] maps to plyr.mgnHeld(i) in PlyrRec.
            ! See save-load-design.md Section 5.2.

    RULE 3 — Split threshold reached:
        ELSE IF currentPrice[i] >= StockSplitThreshold THEN
            sellLots := sharesOwned[i] * splitSellPctW / 100
            sellLots := INT(sellLots / 10) * 10
            IF sellLots >= 10 THEN
                SELL sellLots shares[i]
            ENDIF
            ! splitSellPctW is the working copy of aiProfile.splitSellPct
            ! with endgame override applied if applicable.
            ! See ai-difficulty-tiers.md Sections 4 and 6.

    RULE 4 — Suspended dividend, price at or below distress threshold:
        ELSE IF dividendsSuspended[i] AND
                currentPrice[i] <= aiProfile.distressSellPrice THEN
            SELL all shares[i]
            ! See ai-difficulty-tiers.md Section 4.

    RULE 5 — Default:
        ELSE
            PASS
        ENDIF

NEXT i
```

### 4.2 Stock Sell Rule Reference

| Rule | Condition                                                  | Action                           |
|------|------------------------------------------------------------|----------------------------------|
| 1    | `currentPrice = 0`                                         | Sell all shares                  |
| 2    | `currentPrice <= MarginCallPrice` AND `marginHeld`         | Sell all shares                  |
| 3    | `currentPrice >= StockSplitThreshold`                      | Sell `splitSellPctW`% of shares  |
| 4    | `dividendsSuspended` AND `price <= distressSellPrice`      | Sell all shares                  |
| 5    | None of the above                                          | Pass                             |

### 4.3 Bond Holdings

```
FOR each bond j where bondUnits[j] > 0:

    IF cashBalance < 0 THEN
        SELL 1 unit of bond j
        ! Emergency cash only. Bonds earn steady fixed income;
        ! the AI liquidates the minimum unit needed.
        ! Reassess after each unit sold.
    ELSE
        PASS
    ENDIF

NEXT j
```

Bond sales are the last resort. The AI does not sell bonds unless cash
is negative after all stock sell decisions have been applied.

### 4.4 Proactive Margin Clearance (Sell Phase)

Runs after Sections 4.1–4.3. Sells held assets in ascending yield-score order until `marginTotal` is covered. Stocks are liquidated before bonds. Bond denomination order is ascending (smallest first) to preserve larger income sources. If total assets are insufficient, the Year 10 forced clearance (S23) handles the residual — no special case is needed here.

Score for clearance ordering reuses the buy yield formula from Section 5.3. Stocks with suspended dividends score -1 (sell first); zero-dividend stocks score 0 (sell second); yielding stocks score by dividend/price ratio (sell last, weakest first). Tie-break is ascending `stockId` per Section 5.3 convention.

Lot rounding in partial sells rounds UP to the nearest 10 to ensure proceeds meet or exceed the remaining `needed` amount. `MIN` clamps the result to shares actually owned.

`marginClearYear`: Easy=9, Medium=9, Hard=8. This logic is enforced again at the Year 10 boundary (screen S23).

```
IF marginTotal > 0 AND currentYear >= aiProfile.marginClearYear THEN
    needed := marginTotal

    ! Score held stocks for clearance ordering (ascending = weakest first).
    FOR each stock i where sharesOwned[i] > 0
        IF dividendsSuspended[i] THEN
            clrScore[i] := -1
        ELSE IF dividendPerShare[i] = 0 THEN
            clrScore[i] := 0
        ELSE
            clrScore[i] := dividendPerShare[i] * 1000 / currentPrice[i]
        ENDIF
    NEXT i

    Sort held stocks by clrScore[i] ascending.
    Tie-break: ascending stockId.

    ! Pass 1 — Sell stocks, weakest first, until needed is met.
    FOR each held stock i in ascending clrScore order
        IF needed <= 0 THEN
            CONTINUE
        ENDIF

        IF sharesOwned[i] * currentPrice[i] <= needed THEN
            ! Full position: proceeds do not exceed needed amount.
            SELL all shares[i]
            needed := needed - (sharesOwned[i] * currentPrice[i])
        ELSE
            ! Partial sell: compute minimum lots to cover remainder.
            sellLots := (needed + currentPrice[i] - 1) / currentPrice[i]
            sellLots := ((sellLots + 9) / 10) * 10
            sellLots := MIN(sellLots, sharesOwned[i])
            SELL sellLots shares[i]
            needed := needed - (sellLots * currentPrice[i])
            ! needed may go negative; that is correct and expected.
        ENDIF
    NEXT i

    ! Pass 2 — Supplement with bonds if stock proceeds were insufficient.
    ! Sell smallest denomination first (j=1: $1000, j=2: $5000,
    ! j=3: $10000). Sell one unit at a time; stop when needed <= 0.
    FOR j := 1 TO 3
        WHILE needed > 0 AND bondUnits[j] > 0
            SELL 1 unit of bond j
            needed := needed - parValue[j]
        ENDWHILE
    NEXT j

    ! If needed > 0 after both passes, total asset value is less than
    ! marginTotal. Residual is handled by Year 10 forced clearance (S23).
ENDIF
```

---

## 5. Buy Phase Logic

The AI evaluates purchases in priority order. Endgame overrides
(Section 3) are applied before this logic executes.

### 5.1 Step 1 — Voluntary Margin Repayment Check

```
IF marginTotal > 0 THEN
    annualCharge := marginTotal * MarginInterestRate
    burdenThresh := cashBalance * aiProfile.marginReservePct / 100
    IF annualCharge > burdenThresh THEN
        repayAmount := cashBalance * repayFractionW / 100
        repayAmount := MIN(repayAmount, marginTotal)
        cashBalance := cashBalance - repayAmount
        marginTotal := marginTotal - repayAmount
    ENDIF
ENDIF
```

A lower `marginReservePct` means repayment triggers sooner. `repayFractionW`
is the working copy of `aiProfile.repayFraction`, subject to endgame
override. See `ai-difficulty-tiers.md` Sections 4 and 6.

### 5.2 Step 2 — Margin Eligibility

```
marginAllowed := FALSE

IF aiProfile.useMargin THEN
    IF hadPriorCashPurchase THEN
        IF currentYear < TotalYears THEN
            IF currentYear < aiProfile.marginClearYear THEN
                marginAllowed := TRUE
            ENDIF
        ENDIF
    ENDIF
ENDIF
```

Per-tier values for `useMargin` and `marginClearYear` are defined in
`ai-difficulty-tiers.md` Section 4.

### 5.3 Step 3 — Stock Candidate Scoring

```
FOR each stock i:

    IF currentPrice[i] = BankruptcyPrice THEN
        score[i] := -1        ! Bankrupt stock; ineligible

    ELSE IF currentPrice[i] <= MarginCallPrice THEN
        score[i] := -1        ! Price at forced-sell threshold; ineligible

    ELSE IF dividendsSuspended[i] THEN
        score[i] := -1        ! Yield lost; position is distressed

    ELSE IF dividendPerShare[i] = 0 THEN
        IF zeroDivEligibleW THEN
            score[i] := 0     ! Eligible but lowest priority
        ELSE
            score[i] := -1    ! Excluded; Hard tier and Hard endgame
        ENDIF

    ELSE
        score[i] := dividendPerShare[i] * 1000 / currentPrice[i]
        ! Yield proxy scaled by 1000 to preserve integer precision.
        ! Higher dividend relative to price scores higher.
    ENDIF

NEXT i

Sort candidates by score[i] descending, excluding score[i] = -1.
Tie-break: ascending stockId.
```

The score is multiplied by 1000 to keep all arithmetic in integers. Sort order is preserved; only relative rank matters. The ascending `stockId` tie-break applies to all equal-score pairs: zero-dividend stocks (all score 0 when eligible) and any two yielding stocks whose dividend-to-price ratios are equal at current prices.

#### Easy Tier: No Yield Scoring

Easy AI (`tier = 1`) does not differentiate stocks by yield. All eligible
stocks receive `score[i] := 0` regardless of `dividendPerShare`. Stocks
are processed in ascending `stockId` order. Governed by `aiProfile.useYieldScoring`. See `ai-difficulty-tiers.md` Section 4.

#### Scoring Reference — Stocks at Starting Price ($100)

| Stock               | Dividend/Share | Score (x1000) | Zero-div? |
|---------------------|----------------|---------------|-----------|
| Shady Brooks        | $7             | 70            | No        |
| Uranium Enterprises | $6             | 60            | No        |
| Pioneer Mutual      | $4             | 40            | No        |
| Valley Power        | $3             | 30            | No        |
| United Auto         | $2             | 20            | No        |
| Growth Corp         | $1             | 10            | No        |
| Metro Properties    | $0             | 0 or -1       | Yes       |
| Stryker Drilling    | $0             | 0 or -1       | Yes       |
| Tri-City Transport  | $0             | 0 or -1       | Yes       |

Zero-dividend stocks score 0 (eligible) or -1 (excluded) based on
`zeroDivEligibleW`. Hard excludes them entirely; Hard in endgame also
excludes them (`zeroDivEligibleW := FALSE`). Scores shift as prices
change. The AI recalculates from current prices each turn.

### 5.4 Step 4a — Cash Stock Purchase Allocation

```
availableCash := cashBalance
stocksBought  := FALSE

! cashPassLots[i] records lots purchased in the cash pass.
! Step 4b reads this to compute remaining concentration headroom.
FOR i := 1 TO 9
    cashPassLots[i] := 0
NEXT i

FOR each candidate stock i in score-descending order:
    IF availableCash < currentPrice[i] THEN
        CONTINUE    ! Cannot afford even one lot; skip
    ENDIF

    maxCashForStock := availableCash * aiProfile.concentrationCap / 100
    maxLots         := maxCashForStock / currentPrice[i]
    maxLots         := INT(maxLots / 10) * 10

    IF maxLots >= 10 THEN
        BUY maxLots shares CASH
        availableCash   := availableCash - (maxLots * currentPrice[i])
        cashPassLots[i] := maxLots
        stocksBought    := TRUE
    ENDIF

NEXT i
```

Per-tier values for `concentrationCap` are defined in
`ai-difficulty-tiers.md` Section 4.

### 5.5 Step 4b — Margin Stock Purchase Allocation

Executed only when `marginAllowed = TRUE` (Hard tier, Years 1–7).

All four margin risk conditions from `ai-difficulty-tiers.md` Section 7
must pass before a margin purchase proceeds:

```
FOR each candidate stock i in score-descending order:

    priceOK     := currentPrice[i] >=
                   (MarginCallPrice + aiProfile.marginBuffer)

    portfolioVal := cashBalance
                  + SUM(sharesOwned[j] * currentPrice[j])
                  + SUM(bondUnits[k] * parValue[k])
    exposureOK  := marginTotal <
                   (portfolioVal * aiProfile.marginMaxExposure / 100)

    IF NOT priceOK OR NOT exposureOK THEN
        CONTINUE    ! Margin unsafe for this stock; try next candidate
    ENDIF

    ! Compute remaining concentration headroom after the cash pass.
    ! capLimit is applied against portfolioVal (not cash alone) to
    ! prevent margin from creating runaway single-stock exposure.
    capLimit     := portfolioVal * aiProfile.concentrationCap / 100
    alreadySpent := cashPassLots[i] * currentPrice[i]
    headroom     := capLimit - alreadySpent

    ! One lot = 10 shares. If headroom cannot cover even one lot,
    ! the cash pass fully consumed this stock's concentration budget.
    IF headroom < currentPrice[i] * 10 THEN
        CONTINUE    ! Cap consumed in cash pass; skip this candidate
    ENDIF

    maxFullCost  := availableCash * 2
    effectiveCap := MIN(maxFullCost, headroom)

    maxLots      := effectiveCap / currentPrice[i]
    maxLots      := INT(maxLots / 10) * 10

    IF maxLots >= 10 THEN
        cashRequired  := (maxLots * currentPrice[i]) / 2
        marginPortion := (maxLots * currentPrice[i]) / 2
        BUY maxLots shares MARGIN
        availableCash := availableCash - cashRequired
        marginTotal   := marginTotal + marginPortion
        stocksBought  := TRUE
    ENDIF

NEXT i
```

Step 4b runs after Step 4a. `cashPassLots[i]` carries forward the lots
purchased in the cash pass. The headroom check subtracts that prior
spend from the concentration cap before computing the margin allocation,
ensuring the combined cash and margin position never exceeds
`concentrationCap` percent of portfolio value for any single stock. A
stock whose cap was fully consumed in the cash pass is skipped without
attempting a margin purchase.

### 5.6 Step 5 — Bond Purchase

```
bondBuyAllowed := FALSE

IF availableCash >= bondIdleCashW THEN
    IF aiProfile.bondPriority THEN
        bondBuyAllowed := TRUE          ! Easy: buy bonds regardless
    ELSE IF NOT stocksBought THEN
        bondBuyAllowed := TRUE          ! Medium/Hard: only if no stocks bought
    ENDIF
ENDIF

IF bondBuyAllowed THEN
    IF availableCash >= 10000 THEN
        BUY 1 large bond  (par 10000)
        availableCash := availableCash - 10000
    ELSE IF availableCash >= 5000 THEN
        BUY 1 medium bond (par 5000)
        availableCash := availableCash - 5000
    ELSE IF availableCash >= 1000 THEN
        BUY 1 small bond  (par 1000)
        availableCash := availableCash - 1000
    ENDIF
ENDIF
```

`bondIdleCashW` is the working copy of `aiProfile.bondIdleCash`, subject
to endgame override. `bondPriority = TRUE` for Easy only. Per-tier values
are defined in `ai-difficulty-tiers.md` Sections 4 and 6.

---

## 6. Decision Priority Summary

| Priority | Phase | Action                                        | Governed By                                 |
|----------|-------|-----------------------------------------------|---------------------------------------------|
| 1        | Sell  | Sell bankrupt stocks (price = 0)              | Spec; universal                             |
| 2        | Sell  | Sell margin-held stocks at call threshold     | Spec; universal                             |
| 3        | Sell  | Partial sell at split threshold               | `splitSellPctW`                             |
| 4        | Sell  | Sell distressed suspended-dividend stocks     | `distressSellPrice`                         |
| 5        | Sell  | Emergency bond liquidation if cash < 0        | Spec; universal                             |
| 6        | Sell  | Proactive margin clearance                    | `marginClearYear`                           |
| 7        | Buy   | Voluntary margin repayment                    | `marginReservePct`, `repayFractionW`        |
| 8        | Buy   | Cash stock purchases by yield score           | `concentrationCap`, `zeroDivEligibleW`      |
| 9        | Buy   | Margin stock purchases by yield score         | `useMargin`, `marginBuffer`, `marginMaxExposure` |
| 10       | Buy   | Bond purchase                                 | `bondIdleCashW`, `bondPriority`             |

When multiple stocks trigger the same rule simultaneously, process them
in ascending `stockId` order for deterministic output.

---

## 7. Known Gaps

### ~~7.1 Easy Tier Yield Scoring Not Parameterized~~ — RESOLVED

Whether yield scoring is applied is not currently a field in `AIProfile`.
Easy AI's "all stocks equal" behavior (Section 5.3) requires an inline
tier check rather than a profile parameter. A `useYieldScoring : BOOLEAN`
field should be added to the `AIProfile` TYPE in `ai-difficulty-tiers.md`
with the following values:

| Tier   | `useYieldScoring` |
|--------|-------------------|
| Easy   | FALSE             |
| Medium | TRUE              |
| Hard   | TRUE              |

Until that field is added, procedures must check `aiProfile.tier = 1`
directly when deciding whether to apply yield scoring.

### 7.2 Zero-Dividend Stock Volatility Scoring

Zero-dividend stocks (Metro Properties, Stryker Drilling, Tri-City
Transport) score 0 when eligible and are purchased only after all
yielding candidates are allocated. No price momentum or volatility
adjustment is applied. Stryker Drilling has the highest price variance
of any stock in the market tables; a future scoring enhancement could
add a volatility component. This is deferred.

### 7.3 ~~`mgnHeld[i]` source undefined~~ — RESOLVED

`mgnHeld[i]` maps to `plyr.mgnHeld(i)` in `PlyrRec`.
Citation added to Section 4.1 Rule 2. See `save-load-design.md`
Section 5.2.

### 7.4 ~~Section 4.4 proactive clearance algorithm missing~~ — RESOLVED

Full algorithm specified in Section 4.4. Asset selection order:
ascending yield score (weakest first), tie-break ascending `stockId`.
Lot rounding rounds up. Bond supplementation ascending by denomination.
Residual delegated to S23.

### 7.5 ~~Step 4b margin pass re-enters fully-capped stocks~~ — RESOLVED

`cashPassLots[i]` tracking array added to Step 4a. Headroom check
added to Step 4b. See Sections 5.4 and 5.5.

### 7.6 ~~Buy phase score tie-break unspecified~~ — RESOLVED

Ascending `stockId` specified as tie-break in Section 5.3, consistent
with sell-phase convention in Section 6.