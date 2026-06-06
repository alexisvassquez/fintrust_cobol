
# Review Notes

Reference documentation written from the perspective of a COBOL
code reviewer. Each document covers a domain where legacy COBOL
commonly introduces bugs, security issues, or maintenance risk.

---

## Documents

| File | Contents |
| --- | --- |
| `cobol-antipatterns.md` | Top 10 patterns to flag in any COBOL review — missing AT END, unsigned fields, GO TO chains, MOVE truncation, and more |
| `numeric-precision.md` | Fixed-decimal arithmetic, implied decimal V, signed vs unsigned, ROUNDED, ON SIZE ERROR |
| `file-handling.md` | Sequential file I/O patterns, OPEN/CLOSE discipline, VSAM organizations, JCL DD context |
| `data-division-guide.md` | Level numbers, PIC clause reference, OCCURS, REDEFINES, 88-levels, LINKAGE SECTION |
| `mainframe-concepts.md` | z/OS vs GnuCOBOL differences, VSAM, FILE STATUS codes, JCL, RACF, batch architecture, abend codes |

---

## How to Use

These notes are written as a study and reference guide for COBOL
code review. Each document includes:

- **What to look for** — specific code patterns and syntax
- **Why it's a problem** — the runtime or business impact
- **Corrected examples** — the right way to write it

They complement the source modules in `programs/` — many of the
patterns demonstrated in the code (88-levels, ON SIZE ERROR,
GOBACK vs STOP RUN, annotated antipatterns) are explained in
detail here.
