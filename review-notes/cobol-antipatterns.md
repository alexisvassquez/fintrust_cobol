
# COBOL Antipatterns — Review Notes

Common patterns flagged during COBOL code review. Each entry includes
what to look for, why it's a problem, and what a corrected version looks like.

---

## 1. Missing `AT END` on `READ`

**What to look for:**

```cobol
READ TRANSACTION-FILE
    NOT AT END
        PERFORM PROCESS-RECORD
END-READ
```

**Why it's a problem:**
If the file is empty or a read error occurs, control falls through
unpredictably. The file may never be closed, causing resource leaks.
In batch jobs that run overnight, this can corrupt downstream processing.

**Corrected:**

```cobol
READ TRANSACTION-FILE
    AT END
        MOVE 1 TO WS-EOF
    NOT AT END
        PERFORM PROCESS-RECORD
END-READ
```

---

## 2. Unsigned Numeric Field Where Signed Is Needed

**What to look for:**

```cobol
01 NET-BALANCE   PIC 9(9)V99 VALUE 0.
...
COMPUTE NET-BALANCE = TOTAL-CREDITS - TOTAL-DEBITS
```

**Why it's a problem:**
`PIC 9` is unsigned. If debits exceed credits, the subtraction result
is negative but the field cannot hold a negative value. COBOL will
silently truncate or wrap the result — no error is raised. This is
one of the most common sources of financial data corruption in legacy systems.

**Corrected:**

```cobol
01 NET-BALANCE   PIC S9(9)V99 VALUE 0.
```

The `S` prefix makes the field signed. Always use `S` on any field
that could hold a negative value.

---

## 3. Missing `ON SIZE ERROR` on Financial `COMPUTE`

**What to look for:**

```cobol
COMPUTE TOTAL-CREDITS = TOTAL-CREDITS + LE-AMOUNT(ENTRY-IDX)
```

**Why it's a problem:**
If the result exceeds the capacity of the receiving field, COBOL
truncates silently. A `PIC 9(9)V99` field can hold up to 999999999.99.
In a high-volume batch job accumulating thousands of transactions,
overflow is a realistic risk — and without `ON SIZE ERROR`, it goes
completely undetected.

**Corrected:**

```cobol
COMPUTE TOTAL-CREDITS = TOTAL-CREDITS + LE-AMOUNT(ENTRY-IDX)
    ON SIZE ERROR
        DISPLAY "** SIZE ERROR: Credit total overflow"
        MOVE 1 TO OVERFLOW-FLAG
END-COMPUTE
```

---

## 4. `PERFORM THRU` Fall-Through Risk

**What to look for:**

```cobol
PERFORM VALIDATE-INPUT THRU VALIDATE-EXIT
```

**Why it's a problem:**
`PERFORM THRU` executes all paragraphs between the named start and
end paragraph inclusive. If a developer later inserts a new paragraph
between them, it gets silently included in the range. This is a
maintenance trap that causes unexpected behavior months or years
after the original code was written.

**Corrected:**
Prefer explicit `PERFORM` calls per paragraph:

```cobol
PERFORM VALIDATE-INPUT
PERFORM CHECK-RANGE
PERFORM VALIDATE-EXIT
```

Or use a containing paragraph that calls the others explicitly.

---

## 5. `GO TO` Spaghetti

**What to look for:**

```cobol
IF WS-ERROR = 1
    GO TO ERROR-HANDLER
END-IF
...
ERROR-HANDLER.
    GO TO CLEANUP-ROUTINE.
CLEANUP-ROUTINE.
    GO TO MAIN-EXIT.
```

**Why it's a problem:**
Chained `GO TO` statements make control flow impossible to trace.
There is no guaranteed return point — execution jumps forward only,
never back. Debugging, testing, and modifying this code is extremely
difficult. The `ALTER` verb (which dynamically changes `GO TO` targets
at runtime) is even more dangerous and was formally removed in COBOL 2002.

**Corrected:**
Use structured `PERFORM` with proper paragraph decomposition:

```cobol
IF WS-ERROR = 1
    PERFORM HANDLE-ERROR
END-IF
```

---

## 6. `MOVE` Truncation

**What to look for:**

```cobol
01 WS-LONG-NAME    PIC X(30).
01 WS-SHORT-NAME   PIC X(10).
...
MOVE WS-LONG-NAME TO WS-SHORT-NAME
```

**Why it's a problem:**
COBOL truncates alphanumeric fields on the right without warning.
If `WS-LONG-NAME` contains `"METROPOLITAN BANK"`, `WS-SHORT-NAME`
receives `"METROPOLIT"` — silently. For numeric fields, truncation
happens on the left, which is even more dangerous (losing the most
significant digits).

**What to flag:**
Any `MOVE` between fields of different sizes, especially numeric
fields where left truncation could corrupt values.

---

## 7. Uninitialized Working Storage

**What to look for:**

```cobol
01 WS-TOTAL   PIC 9(9)V99.
...
COMPUTE WS-TOTAL = WS-TOTAL + WS-AMOUNT
```

**Why it's a problem:**
GnuCOBOL initializes WORKING-STORAGE to zero/spaces by default,
but IBM Enterprise COBOL on z/OS does NOT guarantee initialization.
Code that works in a GnuCOBOL environment may produce garbage results
on a mainframe if working storage is not explicitly initialized.

**Corrected:**

```cobol
01 WS-TOTAL   PIC 9(9)V99 VALUE 0.
```

Or use `INITIALIZE WS-TOTAL` before use. Never assume a field
is zero unless explicitly set.

---

## 8. Hardcoded Credentials

**What to look for:**

```cobol
01 USER-TABLE.
    05 USER-ENTRY OCCURS 5 TIMES.
        10 UT-USERNAME   PIC X(10).
        10 UT-PASSWORD   PIC X(10).
```

**Why it's a problem:**
Credentials embedded in WORKING-STORAGE are visible in:

- Source code repositories
- Compiled load modules (readable with a hex dump)
- Memory dumps during abend (abnormal end) processing

This is a critical security vulnerability. On z/OS, authentication
should be delegated to RACF (Resource Access Control Facility) or
an equivalent external security manager. Passwords should never
appear in program source.

---

## 9. `V` vs Actual Decimal Point in Numeric Fields

**What to look for:**

```cobol
01 WS-AMOUNT   PIC 9(7).2.     *> WRONG
01 WS-AMOUNT   PIC 9(7)V99.    *> CORRECT
```

**Why it's a problem:**
`V` denotes an *implied* decimal point — no actual decimal character
is stored in the field. The field `PIC 9(9)V99` occupies 11 digits
of storage with the decimal position tracked by the compiler.
Using an actual `.` in a `PIC` clause is a syntax error or
misinterpretation. Reviewers should verify that display formatting
uses a separate `PIC Z(7)9.99` field, not the storage field itself.

---

## 10. `GOBACK` vs `STOP RUN` in Subprograms

**What to look for:**

```cobol
*> In a called subprogram:
STOP RUN.    *> WRONG in a submodule
GOBACK.      *> CORRECT
```

**Why it's a problem:**
`STOP RUN` terminates the entire runtime environment — the main
program and all subprograms. In a modular system where `mainmenu`
CALLs submodules, a `STOP RUN` inside a submodule kills the whole
application instead of returning control to the caller.
`GOBACK` returns to the caller if the program was called, or
terminates if it is the main program — the correct behavior in both cases.
