# Stocks and Bonds — Computer Player Decision Logic

---

## 1. Scope and Constraints

This document specifies the decision logic for computer-controlled players
in the Stocks and Bonds game. It is the authoritative reference for authors
writing the AI sell and buy phase procedures.

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

## 2. Design Parameters

These values are named constants in the AI logic. They are design decisions,
not values derived from the specification. They may be adjusted when a
difficulty tier system is introduced.

| Parameter              | Value | Purpose                                              |
|------------------------|-------|------------------------------------------------------|
| `AI_CONCENTRATION_CAP` | 0.40  | Max fraction of available cash per stock purchase    |
| `AI_MARGIN_RESERVE`    | 0.10  | Margin interest burden threshold that triggers repay |
| `AI_REPAY_FRACTION`    | 0.50  | Fraction of available cash applied to margin repay   |
| `AI_USE_MARGIN`        | FALSE | Whether AI ever makes margin purchases (baseline)    |
| `AI_BOND_IDLE_CASH`    | 5000  | Min idle cash required before AI buys a bond         |

`AI_USE_MARGIN = FALSE` is the baseline. The AI never initiates margin
purchases in this version. This eliminates the need for margin call risk
management logic on the buy side. A future difficulty tier system may
enable margin use with additional risk parameters.

---

## 3. Sell Phase Logic

The AI evaluates each holding independently in a fixed priority order.
Rules are applied top-down; the first matching rule governs the decision
for that holding.

### 3.1 Priority Order — Stock Holdings

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

    RULE 3 — Split threshold reached:
        ELSE IF currentPrice[i] >= StockSplitThreshold THEN
            SELL INT(sharesOwned[i] / 2) shares (round down to multiple of 10)
            ! Split is about to halve the price. Partial sell captures
            ! gains before the split. Remaining shares benefit from
            ! doubled quantity post-split.

    RULE 4 — Suspended dividend, depressed price:
        ELSE IF dividendsSuspended[i] AND currentPrice[i] < DividendCutoff THEN
            SELL all shares[i]
            ! No yield and confirmed price weakness. No reason to hold.

    RULE 5 — Default:
        ELSE
            PASS (do not sell this stock)
        ENDIF

NEXT i
```

### 3.2 Stock Sell Rule Reference Table

| Rule | Condition                                          | Action              |
|------|----------------------------------------------------|---------------------|
| 1    | `currentPrice = 0`                                 | Sell all shares     |
| 2    | `currentPrice <= 25` AND `marginHeld`              | Sell all shares     |
| 3    | `currentPrice >= 150`                              | Sell half (round 10)|
| 4    | `dividendsSuspended AND currentPrice < 50`         | Sell all shares     |
| 5    | None of the above                                  | Pass                |

### 3.3 Bond Holdings

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

Bonds are the last resort. The AI does not sell bonds unless cash is negative
after all stock sell decisions have been applied.

### 3.4 Pre-Year 10 Margin Clearance (Sell Phase)

```
IF currentYear = (TotalYears - 1) AND marginTotal > 0 THEN
    ! End of Year 9. Margin must be cleared before Year 10 begins.
    ! Sell assets sufficient to cover marginTotal.
    ! Apply stock sell rules first; supplement with bond sales if needed.
    ! This logic is enforced again at the Year 10 boundary (S23).
ENDIF
```

---

## 4. Buy Phase Logic

The AI evaluates purchases in priority order after applying any mandatory
margin repayment.

### 4.1 Step 1 — Mandatory Margin Repayment Check

```
IF marginTotal > 0 THEN
    annualCharge := marginTotal * MarginInterestRate
    IF annualCharge > (cashBalance * AI_MARGIN_RESERVE) THEN
        repayAmount := MIN(marginTotal, INT(cashBalance * AI_REPAY_FRACTION))
        cashBalance  := cashBalance - repayAmount
        marginTotal  := marginTotal - repayAmount
    ENDIF
ENDIF
```

This step reduces margin burden when the annual interest charge would
exceed 10% of available cash. The AI repays up to 50% of available cash
toward margin before making any purchases.

### 4.2 Step 2 — Year 10 Margin Prohibition

```
IF currentYear = TotalYears THEN
    marginAllowed := FALSE
ELSE IF NOT hadPriorCashPurchase THEN
    marginAllowed := FALSE
ELSE
    marginAllowed := AI_USE_MARGIN
ENDIF
```

`AI_USE_MARGIN = FALSE` in the baseline, so `marginAllowed` is always
FALSE in this version regardless of year.

### 4.3 Step 3 — Stock Candidate Scoring

```
FOR each stock i:
    IF currentPrice[i] = BankruptcyPrice THEN
        score[i] := -1    ! Exclude bankrupt stocks
    ELSE IF currentPrice[i] <= MarginCallPrice THEN
        score[i] := -1    ! Exclude high-risk stocks
    ELSE IF dividendsSuspended[i] THEN
        score[i] := -1    ! Exclude distressed no-yield stocks
    ELSE IF dividendPerShare[i] > 0 THEN
        score[i] := dividendPerShare[i] / currentPrice[i]
        ! Yield proxy. Higher dividend relative to price scores higher.
    ELSE
        score[i] := 0
        ! Zero-dividend stocks are eligible but lowest priority.
    ENDIF
NEXT i

Sort candidates by score[i] descending, excluding score[i] = -1.
```

#### Scoring Reference — Stocks at Starting Price ($100)

| Stock               | Dividend/Share | Score at $100 |
|---------------------|----------------|---------------|
| Shady Brooks        | $7             | 0.070         |
| Uranium Enterprises | $6             | 0.060         |
| Pioneer Mutual      | $4             | 0.040         |
| Valley Power        | $3             | 0.030         |
| United Auto         | $2             | 0.020         |
| Growth Corp         | $1             | 0.010         |
| Metro Properties    | $0             | 0.000         |
| Stryker Drilling    | $0             | 0.000         |
| Tri-City Transport  | $0             | 0.000         |

Scores shift as prices change. The AI recalculates from current prices
each turn.

### 4.4 Step 4 — Stock Purchase Allocation

```
availableCash := cashBalance

FOR each candidate stock i in score-descending order:
    IF availableCash < currentPrice[i] THEN
        CONTINUE    ! Cannot afford even one lot
    ENDIF

    maxCashForStock := INT(availableCash * AI_CONCENTRATION_CAP)
    maxLots         := INT(maxCashForStock / (currentPrice[i] * 10)) * 10
    ! maxLots is the largest multiple of 10 shares affordable within cap.

    IF maxLots >= 10 THEN
        BUY maxLots shares CASH
        availableCash := availableCash - (maxLots * currentPrice[i])
    ENDIF

NEXT i
```

The 40% concentration cap (`AI_CONCENTRATION_CAP`) prevents the AI from
committing all cash to one stock. If multiple candidates exist, later
candidates receive allocations from remaining cash.

### 4.5 Step 5 — Bond Purchase Fallback

```
IF availableCash >= AI_BOND_IDLE_CASH AND noStocksBoughtThisTurn THEN
    ! Find the largest denomination bond affordable.
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

The AI only buys bonds when no stocks were purchased this turn. Bonds
provide steady 5% annual income and are a safe fallback for idle cash.

---

## 5. Decision Priority Summary

| Priority | Phase | Action                                         |
|----------|-------|------------------------------------------------|
| 1        | Sell  | Sell bankrupt stocks (price = 0)               |
| 2        | Sell  | Sell margin-held stocks at or below $25        |
| 3        | Sell  | Partial sell of stocks at or above split price |
| 4        | Sell  | Sell suspended-dividend depressed stocks       |
| 5        | Sell  | Emergency bond liquidation if cash < 0         |
| 6        | Buy   | Repay margin if interest burden exceeds 10%    |
| 7        | Buy   | Purchase stocks by yield score, 40% cap each   |
| 8        | Buy   | Purchase bond if cash idle and no stocks bought|

In the event of conflicting rules within the same priority level (e.g.,
multiple stocks trigger Rule 3 simultaneously), process stocks in ascending
`stockId` order for deterministic output.

---

## 6. Known Gaps and Deferred Work

### 6.1 Difficulty Tiers

All parameters in Section 2 are fixed in the baseline. A difficulty system
would vary these per tier. Candidate parameters:

- `AI_CONCENTRATION_CAP` — lower value = more diversification (harder)
- `AI_USE_MARGIN` — enable margin use for higher-difficulty AI
- `AI_MARGIN_RESERVE` — lower threshold = AI repays margin less aggressively
- Sell Rule 3 threshold — sell at a different fraction before split

No difficulty tier design is in scope for this version.

### 6.2 Margin Buy Logic

When `AI_USE_MARGIN = TRUE` is enabled in a future version, the buy phase
will require additional rules:

- Maximum margin exposure as a fraction of portfolio value
- Margin call avoidance scoring (avoid stocks near $25)
- Forced margin repayment schedule as Year 10 approaches

### 6.3 Endgame Strategy

The AI does not adjust behavior based on proximity to Year 10 or relative
wealth standing compared to other players. A competitive AI would shift
from income-maximization to wealth-gap-closing in the final years. This
is deferred.

### 6.4 Zero-Dividend Stock Strategy

Zero-dividend stocks (Metro Properties, Stryker Drilling, Tri-City Transport)
score 0 and are bought only if no yielding candidates remain after
concentration-cap allocation. No price momentum or volatility logic is
applied. Stryker Drilling has high price volatility in the market tables;
a future version could add a volatility bonus to the scoring model.
