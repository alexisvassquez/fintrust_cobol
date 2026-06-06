
# FinTrust COBOL
>
> 💼 A modular COBOL banking simulation demonstrating core legacy financial system patterns.

FinTrust COBOL simulates the architecture of mainframe-era banking software using GnuCOBOL.
It is structured as a multi-module COBOL application with a central menu driver that
dynamically CALLs subprograms as shared objects — mirroring how real COBOL systems
are organized in production mainframe environments.

---

## 🏦 Architecture

The system follows a standard COBOL subprogram model:

- `mainmenu.cbl` — Main driver. Compiled as an executable. Routes user input
  to submodules via dynamic `CALL` statements.
- `programs/` — Submodules compiled as `.so` shared objects (GnuCOBOL `-m` flag),
  loaded at runtime via `COB_LIBRARY_PATH`.

```bash
mainmenu (executable)
├── CALL "ACCTMGMT"   → programs/account_management.cbl
├── CALL "VIEWTRANS"  → programs/view_transactions.cbl
├── CALL "LEDGERSM"   → programs/ledger_summary.cbl
└── CALL "AUTHUSER"   → programs/authenticate_user.cbl
```

---

## 💡 Modules

| Module | Program-ID | Description |
| --- | --- | --- |
| Account Management | `ACCTMGMT` | View, open, close, and update account records |
| View Transactions | `VIEWTRANS` | Browse transactions by account, type, or date |
| Ledger Summary | `LEDGERSM` | Summarize balances using fixed-decimal arithmetic |
| Authenticate User | `AUTHUSER` | Credential lookup via table search |

---

## 🧰 Requirements

- GnuCOBOL 3.x (`sudo apt install gnucobol` on Ubuntu/WSL)
- GNU Make (optional, for the Makefile build)
- Linux or WSL (Windows Subsystem for Linux)

---

## 🔧 Build & Run

**Using Make (recommended):**

```bash
make        # compile all modules and main executable
make run    # launch FinTrust COBOL
make clean  # remove compiled artifacts
```

**Manual compilation:**

```cobol
cobc -m -o ACCTMGMT  programs/account_management.cbl
cobc -m -o VIEWTRANS programs/view_transactions.cbl
cobc -m -o LEDGERSM  programs/ledger_summary.cbl
cobc -m -o AUTHUSER  programs/authenticate_user.cbl
cobc -x -o fintrust  mainmenu.cbl

COB_LIBRARY_PATH=. ./fintrust
```

---

## 🗂 Data Division Patterns Used

- `PIC 9` / `PIC X` — numeric and alphanumeric field definitions
- `PIC 9(9)V99` — fixed-decimal for monetary values
- `PIC S9(9)V99` - signed variable that can hold both positive and negative values
- `OCCURS` — table definitions for multi-record structures
- `REDEFINES` — field overlay for alternative data interpretations
- `VALUE` — field initialization at declaration

---

## 📋 Review Notes

Supplementary documentation written from a code reviewer's perspective,
covering the patterns, pitfalls, and mainframe concepts that matter most
in production COBOL environments.

| Document | Contents |
| --- | --- |
| [COBOL Antipatterns](review-notes/cobol-antipatterns.md) | Top 10 patterns to flag in any review — missing `AT END`, unsigned fields, `GO TO` chains, `MOVE` truncation, and more |
| [Numeric Precision](review-notes/numeric-precision.md) | Fixed-decimal arithmetic, implied decimal `V`, signed vs unsigned, `ROUNDED`, `ON SIZE ERROR` |
| [File Handling](review-notes/file-handling.md) | Sequential I/O patterns, `OPEN`/`CLOSE` discipline, VSAM organizations, JCL DD context |
| [Data Division Guide](review-notes/data-division-guide.md) | Level numbers, `PIC` clause reference, `OCCURS`, `REDEFINES`, 88-levels, `LINKAGE SECTION` |
| [Mainframe Concepts](review-notes/mainframe-concepts.md) | z/OS vs GnuCOBOL differences, VSAM, FILE STATUS codes, JCL, RACF, batch architecture, abend codes |

---

## 📖 Purpose

Built for educational and demonstrative purposes. FinTrust COBOL is not a banking institution.

© 2026 Alexis M Vasquez, Software Engineer. All rights reserved. No financial services are provided by this software.
