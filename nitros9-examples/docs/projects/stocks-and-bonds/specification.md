# Stocks and Bonds Game Engine Specification

# 1. Game Initialization

## 1.1 Constants

```json
{
  "StartingCash": 5000,
  "TotalYears": 10,
  "StockStartPrice": 100,
  "StockSplitThreshold": 150,
  "StockSplitRatio": 2,
  "DividendCutoff": 50,
  "BankruptcyPrice": 0,
  "MarginRate": 0.5,
  "MarginInterestRate": 0.05,
  "MarginCallPrice": 25,
  "ValidDiceRolls": [2,3,4,5,6,7,8,9,10,11,12]
}
```

## 1.2 Assets

### Stocks

* 9 stock securities
* Initial price = 100
* Dividends defined per certificate
* Certificates in units of 10, 50, 100 shares
* Only round lots (multiples of 10 shares) allowed

### Bonds

* Fixed denominations: 1,000 / 5,000 / 10,000
* Sold at par
* Price does not fluctuate
* Annual fixed interest defined per certificate

# 2. Player State Model

```
Player {
    cash_balance
    holdings {
        stock_id → shares
        bond_id → bond_units
    }
    margin_total
    margin_charges_due
}
```

Initialize:

```
cash_balance = 5000
margin_total = 0
```

---

# 3. Year Loop (Years 1–10)

For each year:

```
for year in 1..10:
    apply_situation_card()
    update_market_prices()
    post_prices()
    distribute_dividends_and_interest()
    collect_margin_charges()
    allow_sell_phase()
    allow_buy_phase()
    handle_splits()
    handle_price_threshold_effects()
```

# 4. Situation Card Effects

Each card:

* Indicates bull or bear market
* Applies additional point increase or decrease
* May affect one or multiple stocks

```
market = BULL | BEAR
price += card_effect
```

# 4. Market Price Determination

```
roll_dice()
movement = calculator_lookup(market, roll)
```

For each stock:

```
price += movement_adjusted_by_situation_card
```

# 6. Buying Rules

## 6.1 Cash Purchase

```
cost = shares * current_price

if cash_balance >= cost:
    cash_balance -= cost
    holdings[stock] += shares
```

## 6.2 Bonds

```
cost = par_value
cash_balance -= cost
holdings[bond] += 1
```

Bond price never changes.

---

# 7. Selling Rules

## 7.1 Stock

```
proceeds = shares_sold * current_price
cash_balance += proceeds
holdings[stock] -= shares_sold
```

## 7.2 Bond

```
proceeds = par_value
cash_balance += proceeds
holdings[bond] -= 1
```

If held on margin:

```
must immediately repay related margin balance
```

---

# 8. Dividends & Interest

## 8.1 Stock Dividend Condition

```
if price >= 50:
    dividend = dividend_per_share * shares_owned
else:
    dividend = 0
```

Add to cash.

## 8.2 Bonds

```
interest = fixed_interest_per_bond * bond_units
cash_balance += interest
```

No dividends or interest in Year 10 (closing year).

---

# 9. Stock Split Logic

Trigger:

```
if price >= 150:
    price = price / 2
    shares_owned *= 2
```

---

# 10. Low Price Effects

## 10.1 Below $50

```
dividends_suspended = true
```

Resume when price ≥ 50.

## 10.2 At or Below $0

```
holdings[stock] = 0
price reset next year to STOCK_START_PRICE logic
```

---

# 11. Margin System

## 11.1 Eligibility

* Cannot use margin until after first cash purchase year
* No margin purchases in Year 10

## 11.2 Margin Purchase

```
purchase_price = shares * price
cash_payment = purchase_price * 0.5
margin_portion = purchase_price * 0.5

cash_balance -= cash_payment
margin_total += margin_portion
```

## 11.3 Annual Margin Charges

```
margin_charge = margin_total * 0.05
cash_balance -= margin_charge
```

Must be payable from cash. If not:

```
force_sell_until_cash_sufficient()
if still insufficient:
    player_bankrupt = true
```

## 11.4 Margin Call

If:

```
price <= 25:
    margin_balance_due_immediately
```

If:

```
price <= 0:
    stock surrendered
    margin balance still due
```

## 11.5 Paying Margin Balance

```
cash_balance -= amount_paid
margin_total -= amount_paid
```

All margin must be cleared before Year 10.

---

# 12. End of Game (Year 10)

After final prices posted:

```
total_asset_value =
    cash_balance +
    sum(shares * price) +
    sum(bonds * par_value)
```

No dividends or interest.

Winner:

```
max(total_asset_value)
```

---

# 13. Bankruptcy Conditions

Player eliminated if:

```
cannot pay margin charges
OR
cannot meet margin call
```

---

# 14. Optional Variant Logic

## Variant A

Roll once per year → applies to all stocks.

## Variant B

Roll per security.

Special rule:

```
if roll == 2 OR roll == 12:
    override all prices using calculator values for that roll
```

---

# 15. Deterministic Implementation Notes

* All price changes are additive integers.
* Shares always integer multiples of 10.
* Bonds are discrete units.
* Order of operations per year must be consistent:

  1. Price update
  2. Dividends/interest
  3. Margin charges
  4. Selling
  5. Buying
  6. Split resolution
  7. Bankruptcy checks


# 1. Core Game Structure

## 1.1 Game Length
- TotalYears = 10

## 1.2 Annual Market Flow

For each year:

1. Draw one Situation Card (random).
2. marketType = card.marketType (Bull or Bear).
3. Roll 2d6 (result 2–12).
4. Apply Market Price Table (based on marketType and roll).
5. Apply Situation Card price adjustments.
6. Resolve stock thresholds (bankruptcy floor, dividend suspension, stock splits).
7. Apply dividends and bond interest (skip in final year).
8. Apply margin interest.
9. Player trading phase (sell then buy).
10. End year.

Final year:
- No dividends.
- No bond interest.
- No margin purchases.
- Calculate final wealth.

---

# 2. Stocks

## 2.1 Stock List

- City Bonds (no situation effects)
- Growth Corp
- Metro Properties
- Pioneer Mutual
- Shady Brooks
- Stryker Drilling
- Tri-City Transport
- United Auto
- Uranium Enterprises
- Valley Power

---

# 3. Situation Cards

## 3.1 Structure

Each card:

- marketType: Bull or Bear
- effects: list of stock price adjustments
- optional dividendBonusPerShare

Total cards:
- 36 cards
  - 18 Bull
  - 18 Bear

## 3.2 Card Effects

### Single-Stock Cards

**Growth Corp**
- -10
- +10
- +8
- -8
- +10 & $2/share
- -10

**Metro Properties**
- +5
- +10
- -5
- -10

**Pioneer Mutual**
- none (except combo cards)

**Shady Brooks**
- +5
- -5

**Stryker Drilling**
- +17
- -15
- -10

**Tri-City Transport**
- +15
- +10
- +5
- -5
- -25

**United Auto**
- +10
- +15
- +10
- -5
- -15
- -15

**Uranium Enterprises**
- +10
- +10
- -25

**Valley Power**
- -14
- +5
- +5

---

### Multi-Stock Cards

- Pioneer +3 / Valley +4  (Bull)
- Growth -8 / Metro -5 / United Auto -7 (Bear)
- Pioneer -8 / Stryker +8 / Uranium +5 (Bull)
- Growth +8 / Metro +5 / Pioneer +5 / United Auto +7 (Bull)

---

## 3.3 Card Classification Rule

- Cards with positive net effects → Bull
- Cards with negative net effects → Bear
- Explicit exception:
  - Growth -8 / Metro -5 / United Auto -7 → Bear

---

# 4. Market Price Tables

After drawing a card and determining marketType, roll 2d6 and apply the corresponding table.

---

## 4.1 Bull Market Table

| Stock               | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12  |
|---------------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Growth Corp         | -2  | 26  | 18  | 23  | 20  | 17  | 19  | 11  | 13  | 14  | 24  |
| Metro Properties    | -10 | 16  | 23  | 28  | 15  | 21  | 24  | 18  | 31  | -8  | 24  |
| Pioneer Mutual      | -7  | 25  | 11  | -2  | 15  | 13  | 17  | 14  | 1   | 19  | 23  |
| Shady Brooks        | -9  | 8   | 12  | 11  | 7   | -2  | 9   | 11  | 14  | -1  | 20  |
| Stryker Drilling    | -2  | -14 | 46  | 56  | -20 | 37  | -5  | 67  | -11 | -9  | 51  |
| Tri-City Transport  | -9  | 21  | 18  | 19  | 15  | 23  | 26  | 15  | 18  | 25  | 27  |
| United Auto         | -7  | 14  | -5  | 30  | 13  | 23  | 13  | 22  | 18  | -10 | 38  |
| Uranium Enterprises | -16 | -4  | 34  | 29  | -10 | 19  | -7  | 18  | -14 | 13  | 33  |
| Valley Power        | -4  | 17  | 15  | 14  | 12  | 14  | 15  | 13  | 10  | 19  | 18  |

---

## 4.2 Bear Market Table

| Stock               | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12  |
|---------------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
| Growth Corp         | 12  | 7   | 9   | 7   | 8   | 6   | 5   | -2  | 11  | -5  | -8  |
| Metro Properties    | 14  | -6  | 10  | 8   | 6   | 4   | 7   | 6   | 11  | 13  | -10 |
| Pioneer Mutual      | 13  | 10  | 7   | 5   | 4   | 3   | -1  | -3  | -5  | -8  | -10 |
| Shady Brooks        | 10  | -10 | -5  | -6  | -4  | 3   | -3  | -8  | -7  | 6   | -15 |
| Stryker Drilling    | 10  | 30  | -20 | -40 | 40  | -15 | 45  | -20 | 30  | 25  | -20 |
| Tri-City Transport  | 20  | 6   | 12  | 3   | 8   | 5   | 6   | 7   | 10  | 4   | -20 |
| United Auto         | 21  | -19 | 21  | 16  | 4   | 8   | -10 | 10  | -11 | 18  | -23 |
| Uranium Enterprises | 25  | 22  | 18  | -14 | -12 | -8  | 10  | 14  | -18 | -22 | -25 |
| Valley Power        | 8   | -2  | 7   | 4   | 3   | 5   | 4   | 6   | -4  | -4  | -7  |

---

# 5. Price Resolution Order

For each stock:

1. Apply Market Table delta.
2. Apply Situation Card delta.
3. If price < 0 → set price = 0.
4. If price < DividendCutoff → dividends suspended.
5. If price ≥ StockSplitThreshold → execute split.

---

# 6. Dividends

- Paid annually except final year.
- Not paid if dividendsSuspended = true.
- Bonus dividends from cards applied immediately.

---

# 7. Optional Rule: Market Roll Variants

Option A:
- Roll once per year (default).

Option B:
- Roll separately for each stock in Year 1 only.

Option C:
- Roll separately for each stock every year.

---

# 8. Margin Rules (Optional)

## 8.1 Margin Purchase

- Player may pay 50% cash.
- Remaining 50% recorded as marginBalance.

## 8.2 Interest

- Annual margin interest applied before trading phase.

## 8.3 Margin Restrictions

- No margin purchases in final year.

## 8.4 Margin Call

- If stock price falls to defined marginCallPrice:
  - Immediate repayment required.

## 8.5 Bankruptcy

- If player cannot cover obligations:
  - Liquidate assets.
  - If still negative → player eliminated.

---

# 9. Stock Split Rule

- Triggered when price ≥ StockSplitThreshold.
- Price divided by 2.
- Shares doubled.

---

# 10. Final Wealth Calculation

At end of Year 10:

TotalWealth =
- cash
- + (shares × current price)
- + bonds at par

Highest TotalWealth wins.

---

# 11. Engine Execution Order (Deterministic)

DrawCard  
→ DetermineMarketType  
→ Roll2d6  
→ ApplyMarketTable  
→ ApplyCardEffects  
→ ResolveThresholds  
→ DividendsAndInterest  
→ MarginInterest  
→ SellPhase  
→ BuyPhase  
→ EndYear  

Final year:
- Skip dividends and interest.
- No margin buying.
- Compute final wealth.

---
