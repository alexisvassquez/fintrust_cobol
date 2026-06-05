       IDENTIFICATION DIVISION.
       PROGRAM-ID. LEDGERSM.

      *> LEDGER SUMMARY MODULE
      *> Demonstrates:
      *>  - PIC 9(9)V99  fixed-decimal monetary fields
      *>  - OCCURS for tabular ledger entry storage
      *>  - ON SIZE ERROR for overflow protection
      *>  - 88-level condition names for entry type flags
      
       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Ledger Entry Table
       01 LEDGER-TABLE.
           05 LEDGER-ENTRY OCCURS 10 TIMES
                           INDEXED BY ENTRY-IDX.
               10 LE-DATE         PIC X(10).
               10 LE-DESCRIPTION  PIC X(20).
               10 LE-TYPE         PIC X(1).
                   88 LE-CREDIT   VALUE "C".
                   88 LE-DEBIT    VALUE "D".
               10 LE-AMOUNT       PIC 9(9)V99.

      *> Running Totals
       01 TOTAL-CREDITS       PIC 9(9)V99  VALUE 0.
       01 TOTAL-DEBITS        PIC 9(9)V99  VALUE 0.
       01 NET-BALANCE         PIC S9(9)V99  VALUE 0.
       01 OVERFLOW-FLAG       PIC 9 VALUE 0.

      *> Display Formatting
       01 DISPLAY-AMOUNT      PIC Z(7)9.99.
       01 DISPLAY-BALANCE     PIC -Z(7)9.99.

      *> Loop Control
       01 ENTRY-COUNT         PIC 99 VALUE 10.
       01 LEDGER-CHOICE       PIC 9 VALUE 0.

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM LOAD-LEDGER
           PERFORM UNTIL LEDGER-CHOICE = 9
               DISPLAY "====================================="
               DISPLAY "        LEDGER SUMMARY MODULE        "
               DISPLAY "====================================="
               DISPLAY " 1 - View All Ledger Entries"
               DISPLAY " 2 - View Summary Totals"
               DISPLAY " 9 - Return to Main Menu"
               ACCEPT LEDGER-CHOICE

               EVALUATE LEDGER-CHOICE
                   WHEN 1
                       PERFORM SHOW-ENTRIES
                   WHEN 2
                       PERFORM CALC-TOTALS
                       PERFORM SHOW-SUMMARY
                   WHEN 9
                       DISPLAY "Returning to Main Menu..."
                   WHEN OTHER
                       DISPLAY "Invalid choice. Try again."
               END-EVALUATE
           END-PERFORM
           GOBACK.

      *> LOAD-LEDGER DATA
      *> Populates the OCCURS table with hardcoded ledger entries.
      *> In a production system, this would READ from a flat file
      *> or VSAM dataset.
      *> See view_transactions.cbl for file I/O pattern
       LOAD-LEDGER.
           MOVE "05/01/2026" TO LE-DATE(1)
           MOVE "OPENING BALANCE    " TO LE-DESCRIPTION(1)
           MOVE "C"                   TO LE-TYPE(1)
           MOVE 5000.00               TO LE-AMOUNT(1)

           MOVE "05/05/2026" TO LE-DATE(2)
           MOVE "CASH DEPOSIT       " TO LE-DESCRIPTION(2)
           MOVE "C"                   TO LE-TYPE(2)
           MOVE 705.00                TO LE-AMOUNT(2)

           MOVE "05/08/2026" TO LE-DATE(3)
           MOVE "ATM WITHDRAW       " TO LE-DESCRIPTION(3)
           MOVE "D"                   TO LE-TYPE(3)
           MOVE 20.00                 TO LE-AMOUNT(3)

           MOVE "05/08/2026" TO LE-DATE(4)
           MOVE "ACH CREDIT         " TO LE-DESCRIPTION(4)
           MOVE "C"                   TO LE-TYPE(4)
           MOVE 420.69                TO LE-AMOUNT(4)

           MOVE "05/10/2026" TO LE-DATE(5)
           MOVE "MOBILE DEPOSIT     " TO LE-DESCRIPTION(5)
           MOVE "C"                   TO LE-TYPE(5)
           MOVE 999.99                TO LE-AMOUNT(5)

           MOVE "05/11/2026" TO LE-DATE(6)
           MOVE "POS PURCHASE       " TO LE-DESCRIPTION(6)
           MOVE "D"                   TO LE-TYPE(6)
           MOVE 68.75                 TO LE-AMOUNT(6)

           MOVE "05/12/2026" TO LE-DATE(7)
           MOVE "ACH CREDIT         " TO LE-DESCRIPTION(7)
           MOVE "C"                   TO LE-TYPE(7)
           MOVE 586.36                TO LE-AMOUNT(7)

           MOVE "05/12/2026" TO LE-DATE(8)
           MOVE "POS PURCHASE       " TO LE-DESCRIPTION(8)
           MOVE "D"                   TO LE-TYPE(8)
           MOVE 21.24                 TO LE-AMOUNT(8)

           MOVE "05/14/2026" TO LE-DATE(9)
           MOVE "WIRE TRANSFER      " TO LE-DESCRIPTION(9)
           MOVE "D"                   TO LE-TYPE(9)
           MOVE 250.00                TO LE-AMOUNT(9)

           MOVE "05/15/2026" TO LE-DATE(10)
           MOVE "PAYROLL DEPOSIT    " TO LE-DESCRIPTION(10)
           MOVE "C"                   TO LE-TYPE(10)
           MOVE 2400.00               TO LE-AMOUNT(10).

      *> SHOW-ENTRIES
      *> Iterates the OCCURS table using VARYING/INDEXED BY
      *> and uses 88-level condition names to label each
      *> entry type.
       SHOW-ENTRIES.
           DISPLAY "====================================="
           DISPLAY " DATE       DESCRIPTION          T      AMOUNT"
           DISPLAY "-------------------------------------"
           PERFORM VARYING ENTRY-IDX FROM 1 BY 1
               UNTIL ENTRY-IDX > ENTRY-COUNT
               MOVE LE-AMOUNT(ENTRY-IDX) TO DISPLAY-AMOUNT
               IF LE-CREDIT(ENTRY-IDX)
                   DISPLAY LE-DATE(ENTRY-IDX) " "
                       LE-DESCRIPTION(ENTRY-IDX) " CR "
                       DISPLAY-AMOUNT
               ELSE
                   DISPLAY LE-DATE(ENTRY-IDX) " "
                       LE-DESCRIPTION(ENTRY-IDX) " DR "
                       DISPLAY-AMOUNT
               END-IF
           END-PERFORM
           DISPLAY "====================================="
           DISPLAY "Press ENTER to continue."
           ACCEPT OMITTED.

           *> CALC-TOTALS
           *> Accumulates credit and debits separately using
           *> COMPUTE.
           *> ON SIZE ERROR guards against overflow on the
           *> 9(9)V99 field.
           *> NET-BALANCE uses PIC S9(9)V99 (signed) to allow
           *> negative
           CALC-TOTALS.
               MOVE 0 TO TOTAL-CREDITS
               MOVE 0 TO TOTAL-DEBITS
               MOVE 0 TO OVERFLOW-FLAG

               PERFORM VARYING ENTRY-IDX FROM 1 BY 1
                   UNTIL ENTRY-IDX > ENTRY-COUNT

                   IF LE-CREDIT(ENTRY-IDX)
                       COMPUTE TOTAL-CREDITS = TOTAL-CREDITS
                           + LE-AMOUNT(ENTRY-IDX)
                           ON SIZE ERROR
                               DISPLAY "** SIZE ERROR: "
                               DISPLAY "Credit total overflow"
                               MOVE 1 TO OVERFLOW-FLAG
                       END-COMPUTE
                   ELSE
                       COMPUTE TOTAL-DEBITS = TOTAL-DEBITS
                           + LE-AMOUNT(ENTRY-IDX)
                           ON SIZE ERROR
                               DISPLAY "** SIZE ERROR: "
                               DISPLAY "Debit total overflow"
                               MOVE 1 TO OVERFLOW-FLAG
                       END-COMPUTE
                   END-IF

               END-PERFORM

               IF OVERFLOW-FLAG = 0
                   COMPUTE NET-BALANCE = TOTAL-CREDITS - TOTAL-DEBITS
                       ON SIZE ERROR
                           DISPLAY "** SIZE ERROR: "
                           DISPLAY "Net balance overflow"
                           MOVE 1 TO OVERFLOW-FLAG
                   END-COMPUTE
               END-IF.

           *> SHOW-SUMMARY
           *> Formats and displays the computed totals.
           *> PIC Z(7)9.99 suppresses leading zeros on display fields
           *> PIC -Z(7)9.99 shows a leading minus for negative balances
           SHOW-SUMMARY.
               DISPLAY "====================================="
               DISPLAY "         LEDGER TOTALS               "
               DISPLAY "====================================="
               MOVE TOTAL-CREDITS TO DISPLAY-AMOUNT
               DISPLAY " Total Credits  : " DISPLAY-AMOUNT
               MOVE TOTAL-DEBITS TO DISPLAY-AMOUNT
               DISPLAY " Total Debits   : " DISPLAY-AMOUNT
               DISPLAY "-------------------------------------"
               MOVE NET-BALANCE TO DISPLAY-BALANCE
               DISPLAY " Net Balance    : " DISPLAY-BALANCE
               DISPLAY "====================================="
               DISPLAY "Press ENTER to continue."
               ACCEPT OMITTED.

