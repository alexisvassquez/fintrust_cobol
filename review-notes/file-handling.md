
# File Handling in COBOL — Review Notes

File I/O is the backbone of batch COBOL. Most production banking
jobs read an input file, process records, and write to an output
file or report. This document covers what reviewers look for.

---

## File Definition Structure

Every file requires three things:

**1. `FILE-CONTROL` in ENVIRONMENT DIVISION**
Maps the logical file name to a physical path or DD name:

```cobol
ENVIRONMENT DIVISION.
INPUT-OUTPUT SECTION.
FILE-CONTROL.
    SELECT TRANSACTION-FILE
        ASSIGN TO "data/transactions.dat"
        ORGANIZATION IS LINE SEQUENTIAL.
```

On z/OS mainframes, `ASSIGN TO` references a DD (Data Definition)
name from the JCL (Job Control Language), not a file path:

```cobol
SELECT TRANSACTION-FILE ASSIGN TO TRANFILE.
```

**2. `FD` in FILE SECTION**
Defines the physical record layout:

```cobol
FILE SECTION.
FD TRANSACTION-FILE.
01 TR-RECORD.
    05 TR-ACCOUNT     PIC X(10).
    05 TR-DATE        PIC X(8).
    05 TR-TYPE        PIC X(2).
    05 TR-AMOUNT      PIC 9(6).
```

**3. `OPEN` / `READ` / `CLOSE` in PROCEDURE DIVISION**

---

## `OPEN` / `CLOSE` Discipline

**Review flag:** Any file opened without a guaranteed `CLOSE`.

```cobol
*> WRONG - no CLOSE if an error occurs mid-read
OPEN INPUT TRANSACTION-FILE
PERFORM READ-RECORDS
CLOSE TRANSACTION-FILE

*> BETTER - ensure CLOSE is always reached
OPEN INPUT TRANSACTION-FILE
PERFORM READ-RECORDS
CLOSE TRANSACTION-FILE    *> place after ALL exit paths
```

On mainframes, unclosed files can lock datasets, preventing
downstream jobs in the same JCL from accessing them. In a
nightly batch chain, one unclosed file can cascade into
multiple job failures.

---

## `READ ... AT END` Pattern

The correct sequential read pattern:

```cobol
01 WS-EOF   PIC 9 VALUE 0.
    88 END-OF-FILE VALUE 1.
...
OPEN INPUT TRANSACTION-FILE

PERFORM UNTIL END-OF-FILE
    READ TRANSACTION-FILE
        AT END
            MOVE 1 TO WS-EOF
        NOT AT END
            PERFORM PROCESS-RECORD
    END-READ
END-PERFORM

CLOSE TRANSACTION-FILE
```

**Review flags:**

- Missing `AT END` clause — file exhaustion goes unhandled
- Missing `NOT AT END` — record processing mixed with EOF logic
- EOF flag not initialized before `OPEN` — stale value from a
  previous read cycle causes the loop to exit immediately
- `CLOSE` inside the loop — file closed before all records are read

---

## File Organizations

| Organization | Description | Typical Use |
| --- | --- | --- |
| `LINE SEQUENTIAL` | Text lines, newline-delimited | GnuCOBOL flat files |
| `SEQUENTIAL` | Fixed-length binary records | Mainframe tape/flat files |
| `INDEXED` | VSAM KSDS — keyed random access | Master account files |
| `RELATIVE` | Record number-based access | Less common |

**VSAM (Virtual Storage Access Method)** is the dominant file
system on IBM mainframes. VSAM KSDS (Key-Sequenced Data Set)
supports both sequential and random access by key — the standard
for account master files. Reviewers working on mainframe code
should be familiar with `START`, `READ NEXT`, and `INVALID KEY`
clauses used with indexed files.

---

## Fixed-Width Record Layout

Mainframe flat files use fixed-width positional fields — no
delimiters, no quotes. Every field occupies an exact byte range:

```cobol
Position  1-10  : Account Number   PIC X(10)
Position 11-18  : Date YYYYMMDD    PIC X(8)
Position 19-20  : Type CR/DR       PIC X(2)
Position 21-26  : Amount (implied) PIC 9(6)
```

**Review flag:** If the sum of field sizes in the `FD` record
layout does not match the actual file record length, every read
will misalign fields. This is a common bug when a file layout
changes and the FD is not updated to match.

---

## JCL Context (z/OS)

On mainframes, COBOL programs don't reference file paths directly.
File assignments are controlled by JCL DD statements:

```jcl
//TRANFILE DD DSN=PROD.FINTRUST.TRANS,DISP=SHR
```

The COBOL program uses:

```cobol
SELECT TRANSACTION-FILE ASSIGN TO TRANFILE.
```

The DD name `TRANFILE` links the two. This separation means the
same compiled program can run against different datasets by changing
only the JCL — no recompilation needed. Reviewers should verify
that `ASSIGN TO` names match the expected DD names in the JCL.
