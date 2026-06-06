
# Data Division Guide — Review Notes

The DATA DIVISION is where most COBOL bugs are introduced and where
reviewers spend the most time. Understanding its structure deeply is
the foundation of effective COBOL code review.

---

## Division Structure

```cobol
DATA DIVISION.
    FILE SECTION.         -- FD entries for files
    WORKING-STORAGE SECTION.  -- program variables
    LOCAL-STORAGE SECTION.    -- re-initialized per CALL (less common)
    LINKAGE SECTION.          -- parameters passed from calling program
```

---

## Level Numbers

Level numbers define the hierarchy of a record structure:

```cobol
01 CUSTOMER-RECORD.           *> group item (top level)
    05 CUST-ID     PIC X(10). *> elementary item
    05 CUST-NAME.             *> group item (nested)
        10 CUST-FIRST  PIC X(15).
        10 CUST-LAST   PIC X(20).
    05 CUST-BALANCE PIC S9(9)V99.
```

**Level rules:**

- `01` — record level, always starts at column 8 (Area A)
- `02`–`49` — subordinate fields, any consistent indentation
- `66` — RENAMES clause (rare, flag if seen)
- `77` — standalone field, not part of a group (legacy style, avoid)
- `88` — condition name (value flag, not a storage field)

**Review flag:** `77` level items are a legacy holdover. Modern
COBOL uses `01` for all standalone fields. Flag for modernization.

---

## `PIC` Clause Reference

| Symbol | Meaning | Example |
| --- | --- | --- |
| `9` | Numeric digit | `PIC 9(5)` — 5 digits |
| `X` | Alphanumeric character | `PIC X(10)` — 10 chars |
| `A` | Alphabetic only | `PIC A(10)` — rarely used |
| `S` | Signed (prefix only) | `PIC S9(5)` |
| `V` | Implied decimal point | `PIC 9(7)V99` |
| `Z` | Zero-suppressed digit (display) | `PIC Z(7)9.99` |
| `.` | Actual decimal point (display) | `PIC Z(7)9.99` |
| `-` | Leading minus sign (display) | `PIC -Z(7)9.99` |
| `+` | Leading plus/minus sign (display) | `PIC +Z(7)9.99` |

**Storage vs display fields:**

- Storage fields use `9`, `X`, `S`, `V` — compact, no formatting chars
- Display fields use `Z`, `.`, `-`, `+` — formatted for human output
- Never use a display field in arithmetic — always move to a storage
  field first

---

## `OCCURS` — Table Definition

```cobol
01 ACCOUNT-TABLE.
    05 ACCT-ENTRY OCCURS 100 TIMES
                  INDEXED BY ACCT-IDX.
        10 ACCT-NUMBER   PIC X(10).
        10 ACCT-BALANCE  PIC S9(9)V99.
```

**Review flags:**

- `OCCURS` without `INDEXED BY` — uses a numeric subscript instead
  of an index; less efficient but valid. Subscripts are `PIC 9`,
  indexes are internal compiler types. Mixing them causes subtle bugs.
- Accessing `ACCT-ENTRY(0)` — COBOL tables are 1-based. Index 0
  accesses memory before the table.
- No bounds check before access — if the index exceeds `OCCURS`
  size, behavior is undefined (memory corruption on mainframes).

**`OCCURS DEPENDING ON`** — variable-length tables:

```cobol
05 ITEM-ENTRY OCCURS 1 TO 50 TIMES
              DEPENDING ON ITEM-COUNT.
```

Review flag: `ITEM-COUNT` must be set correctly before any table
access. If it exceeds the actual populated entries, garbage data
is read.

---

## `REDEFINES` — Field Overlay

`REDEFINES` maps two different data definitions to the same memory:

```cobol
01 WS-DATE-NUMERIC    PIC 9(8).
01 WS-DATE-FORMATTED  REDEFINES WS-DATE-NUMERIC.
    05 WS-YEAR   PIC 9(4).
    05 WS-MONTH  PIC 9(2).
    05 WS-DAY    PIC 9(2).
```

Both names refer to the same 8 bytes. Writing to one changes
the other.

**Review flags:**

- `REDEFINES` with different size fields — COBOL requires the
  redefining field to be the same size or smaller. Larger
  redefines cause compiler errors or memory overlap.
- Misuse as a type-cast substitute — `REDEFINES` is legitimate
  for parsing packed fields or date manipulation, but using it
  to "convert" between incompatible types is a design smell.

---

## 88-Level Condition Names

88-level items are not storage fields — they define named conditions
on a parent field:

```cobol
05 TR-TYPE     PIC X(2).
    88 TR-CREDIT   VALUE "CR".
    88 TR-DEBIT    VALUE "DR".
```

Usage:

```cobol
IF TR-CREDIT        *> reads as English
IF TR-TYPE = "CR"   *> equivalent but less readable
```

Setting a condition name:

```cobol
SET TR-CREDIT TO TRUE   *> moves "CR" into TR-TYPE
```

**Review flags:**

- 88-levels without `VALUE` — compiler error
- Comparing directly to the 88-level name in arithmetic context —
  88-levels are boolean conditions, not values
- Missing 88-level for `SPACES` or `LOW-VALUES` on status fields —
  uninitialized state should be a named condition too

---

## `LINKAGE SECTION` — Subprogram Parameters

Parameters passed between programs via `CALL ... USING` are
defined in the called program's `LINKAGE SECTION`:

```cobol
*> Caller:
CALL "SUBPROG" USING WS-ACCOUNT-NUMBER WS-BALANCE

*> Called program:
LINKAGE SECTION.
01 LK-ACCOUNT-NUMBER   PIC X(10).
01 LK-BALANCE          PIC S9(9)V99.

PROCEDURE DIVISION USING LK-ACCOUNT-NUMBER LK-BALANCE.
```

`LINKAGE SECTION` fields are not allocated by the subprogram —
they point to the caller's memory. Writing to them modifies
the caller's variables directly (pass by reference).

**Review flags:**

- `LINKAGE SECTION` field sizes that don't match the caller's
  `USING` fields — mismatched sizes cause memory misalignment
- Attempting to initialize `LINKAGE SECTION` fields with `VALUE`
  clauses — `VALUE` is ignored in `LINKAGE SECTION`
