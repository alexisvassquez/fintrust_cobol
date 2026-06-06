
# Numeric Precision in COBOL — Review Notes

Numeric handling is where most financial COBOL bugs originate.
This document covers the key precision concepts a reviewer must know.

---

## `PIC 9` vs `PIC S9` — Signed vs Unsigned

| Clause | Signed | Range (for 9(5)V99) |
| --- | --- | --- |
| `PIC 9(5)V99` | No | 0.00 to 99999.99 |
| `PIC S9(5)V99` | Yes | -99999.99 to 99999.99 |

**Rule:** Any field that could hold a negative value — balances,
net totals, differences — must use `PIC S9`. Assigning a negative
value to an unsigned field produces silent data corruption.

---

## The `V` Implied Decimal

`V` marks the position of an implied decimal point. No decimal
character is stored — the compiler tracks the position.

```cobol
01 WS-AMOUNT   PIC 9(7)V99.
```

This field stores 9 digits total (7 before, 2 after the implied
decimal). It occupies 9 bytes of storage, not 10. The decimal
point does not exist in memory.

**Display formatting** requires a separate field:

```cobol
01 DISPLAY-AMOUNT   PIC Z(7)9.99.
...
MOVE WS-AMOUNT TO DISPLAY-AMOUNT
DISPLAY DISPLAY-AMOUNT
```

`PIC Z(7)9.99` contains an actual decimal point character and
suppresses leading zeros with spaces (`Z`). Never display a `V`
field directly for human-readable output.

---

## Implied Integer Storage (Mainframe Convention)

A common pattern in legacy systems is storing monetary values as
implied integers to avoid decimal handling entirely:

```cobol
042069  stored as PIC 9(6)  =  $420.69
```

The application divides by 100 when displaying:

```cobol
COMPUTE WS-DISPLAY = TR-AMOUNT-RAW / 100
```

**Why it exists:** Older COBOL compilers and some file systems had
limited support for decimal fields in records. Integer storage
guaranteed consistent byte length and avoided alignment issues.

**Review flag:** Look for division by 10, 100, or 1000 near display
logic — this is a sign the codebase uses implied integer storage.
Ensure the divisor is consistent throughout and that rounding is
handled where needed.

---

## `COMPUTE` Precision Rules

When operands have different decimal positions, COBOL aligns
decimals before computing:

```cobol
01 WS-A   PIC 9(5)V99.    *> 2 decimal places
01 WS-B   PIC 9(3)V9.     *> 1 decimal place
01 WS-C   PIC 9(7)V99.    *> result field

COMPUTE WS-C = WS-A + WS-B
```

COBOL expands `WS-B` to 2 decimal places internally before adding.
The result is stored in `WS-C` at 2 decimal places. Precision is
determined by the receiving field — if `WS-C` has fewer decimal
places than the result, truncation occurs (not rounding).

**Review flag:** Mismatched decimal positions between operands and
result fields, especially in accumulation loops.

---

## Rounding

COBOL truncates by default. To round:

```cobol
COMPUTE WS-RESULT ROUNDED = WS-A / WS-B
```

The `ROUNDED` keyword applies standard half-up rounding.
Its absence in financial calculations is a review flag — silent
truncation of fractional cents accumulates over large transaction
volumes (a real-world source of audit failures).

---

## `ON SIZE ERROR` — Required on Financial Computes

```cobol
COMPUTE WS-TOTAL = WS-TOTAL + WS-AMOUNT
    ON SIZE ERROR
        PERFORM HANDLE-OVERFLOW
END-COMPUTE
```

Without `ON SIZE ERROR`, arithmetic overflow truncates the result
silently. In a batch job processing millions of transactions, this
produces incorrect totals with no error raised — one of the most
dangerous failure modes in financial COBOL.

**Rule:** Every `COMPUTE` on a financial field should have
`ON SIZE ERROR` handling. Flag any that do not.
