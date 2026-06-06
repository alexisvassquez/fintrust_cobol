
# Mainframe Concepts for COBOL Reviewers

Understanding the mainframe environment is essential context for
reviewing production COBOL. Code that looks fine in GnuCOBOL may
behave differently on z/OS — and vice versa.

---

## z/OS vs GnuCOBOL Differences

| Behavior | GnuCOBOL | IBM Enterprise COBOL (z/OS) |
| --- | --- | --- |
| WORKING-STORAGE init | Zeroed automatically | **Not guaranteed** — may contain garbage |
| File assignment | File path string | JCL DD name |
| Line length | Flexible | 72 columns (cols 73-80 are sequence numbers) |
| Endianness | Little-endian (x86) | Big-endian (IBM) |
| Packed decimal | Supported | Native hardware instruction |
| `DISPLAY` output | stdout | SYSOUT DD in JCL |

**Critical difference:** GnuCOBOL zeroes WORKING-STORAGE at
program start. IBM COBOL on z/OS does not. Code that relies on
implicit initialization will fail silently on mainframes.

---

## VSAM — Virtual Storage Access Method

VSAM is the primary file system for mainframe COBOL data.
Unlike flat files, VSAM datasets support keyed random access.

**Three VSAM types:**

| Type | Full Name | Access | Typical Use |
| --- | --- | --- | --- |
| KSDS | Key-Sequenced Data Set | Sequential + by key | Account master files |
| ESDS | Entry-Sequenced Data Set | Sequential only | Transaction logs |
| RRDS | Relative Record Data Set | By record number | Fixed reference tables |

**KSDS review pattern:**

```cobol
SELECT ACCOUNT-FILE ASSIGN TO ACCTMAST
    ORGANIZATION IS INDEXED
    ACCESS MODE IS DYNAMIC
    RECORD KEY IS ACCT-NUMBER
    FILE STATUS IS WS-FILE-STATUS.
```

`ACCESS MODE IS DYNAMIC` allows both sequential and random access.
`FILE STATUS` should always be checked after every file operation.

---

## FILE STATUS Codes

Every file operation should be followed by a `FILE STATUS` check:

```cobol
01 WS-FILE-STATUS   PIC X(2).

*> After every READ, WRITE, OPEN, CLOSE:
IF WS-FILE-STATUS NOT = "00"
    DISPLAY "File error: " WS-FILE-STATUS
    PERFORM HANDLE-FILE-ERROR
END-IF
```

**Common status codes:**

| Code | Meaning |
| --- | --- |
| `00` | Success |
| `10` | End of file (AT END condition) |
| `22` | Duplicate key on WRITE |
| `23` | Record not found (INVALID KEY) |
| `35` | File not found on OPEN |
| `39` | File attribute mismatch |
| `47` | READ attempted on file not open INPUT |
| `48` | WRITE attempted on file not open OUTPUT |

**Review flag:** Missing `FILE STATUS` field on any VSAM file,
or a `FILE STATUS` field that is declared but never checked.

---

## JCL — Job Control Language

JCL controls how COBOL programs run on z/OS. A reviewer should
be able to read basic JCL to understand a program's runtime context.

```jcl
//FINTRST  JOB (ACCT),'FINTRUST EOD',CLASS=A,MSGCLASS=X
//STEP01   EXEC PGM=MAINMENU
//STEPLIB  DD DSN=FINTRUST.LOADLIB,DISP=SHR
//TRANFILE DD DSN=PROD.FINTRUST.TRANS,DISP=SHR
//ACCTMAST DD DSN=PROD.FINTRUST.ACCOUNTS,DISP=SHR
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
```

- `JOB` — defines the job name and accounting info
- `EXEC PGM=` — names the compiled COBOL program to run
- `DD` — Data Definition, maps a DD name to a dataset
- `DISP=SHR` — dataset can be shared with other jobs (read)
- `DISP=OLD` — exclusive access (write)
- `SYSOUT=*` — output goes to the job log

**Review flag:** A program `ASSIGN TO` name that has no matching
DD statement in the JCL — the file open will fail at runtime
with a status code `35`.

---

## RACF — Resource Access Control Facility

RACF is IBM's security subsystem for z/OS. It controls who can
access datasets, programs, and system resources.

**Why it matters for code review:**

- Credentials should never appear in COBOL source
- Dataset access is controlled by RACF profiles, not file permissions
- Programs that access sensitive datasets (payroll, account masters)
  should be reviewed for RACF profile alignment
- Hardcoded user IDs or passwords in WORKING-STORAGE are an
  immediate critical finding

---

## Batch Processing Architecture

Most production COBOL runs as overnight batch, not interactive:

```cobol
Input File (ESDS/flat)
    ↓
SORT Step (DFSORT/SYNCSORT)
    ↓
Main Processing Program
    ↓
Master File Update (KSDS VSAM)
    ↓
Report / Output File
    ↓
Control Totals Verification
```

**Control totals** are a critical concept: the number of records
read, processed, and written are accumulated and printed at job
end. If input count ≠ output count, the job fails or alerts.
A COBOL program missing control total logic is a review flag in
any batch processing context.

---

## Abend Codes

An abend (abnormal end) is a mainframe program crash. Common codes:

| Code | Cause | COBOL Connection |
| --- | --- | --- |
| `S0C7` | Data exception | Non-numeric data in numeric field |
| `S0C4` | Protection exception | Invalid memory access (bad table index) |
| `S322` | CPU time limit exceeded | Infinite loop |
| `S806` | Program not found | Missing load module or DD STEPLIB |
| `S013` | File attribute mismatch | FD record length ≠ actual file |

`S0C7` is the most common COBOL abend. It almost always means
a `PIC 9` field contains spaces or alphabetic characters —
often from uninitialized working storage or a bad file read.
