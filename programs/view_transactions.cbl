       IDENTIFICATION DIVISION.
       PROGRAM-ID. VIEWTRANS.

      *> VIEW TRANSACTIONS MODULE
      *> Demonstrates:
      *>  - FILE-CONTROL SELECT for logical-to-physical file mapping
      *>  - FD (File Descriptor) with fixed-width record layout
      *>  - OPEN INPUT / CLOSE for proper file discipline
      *>  - READ ... AT END for sequential file processing
      *>  - NOT AT END for record handling
      *>  - 88-level condition names for transaction type flags

      *> Reads from: data/transactions.dat

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

      *> FD defines the physical structure of each record.
      *> All fields are positional, no delimiters.
      *> This mirrors how VSAM and flat files are laid out
      *> on mainframe systems.
       FD TRANSACTION-FILE.
       01 TR-RECORD.
           05 TR-ACCOUNT     PIC X(10).
           05 TR-DATE        PIC X(8).
           05 TR-TYPE        PIC X(2).
               88 TR-CREDIT  VALUE "CR".
               88 TR-DEBIT   VALUE "DR".
           05 TR-DESCRIPTION PIC X(20).
           05 TR-AMOUNT-RAW  PIC 9(6).         

       WORKING-STORAGE SECTION.
       01 WS-EOF             PIC 9 VALUE 0.
           88 END-OF-FILE    VALUE 1.
       01 WS-FOUND           PIC 9 VALUE 0.
       01 WS-FILTER-ACCT     PIC X(10).
       01 WS-FILTER-TYPE     PIC X(2).   
       01 TRANS-CHOICE       PIC 9 VALUE 0.
       01 NAV-CHOICE         PIC 9 VALUE 0.

      *> Display amount: convert raw 9(6) integer to dollars/cents.
      *> e.g. 042069 stored as integer -> displayed as 420.69
       01 WS-DISPLAY-AMT     PIC Z(4)9.99.
       01 WS-AMOUNT-WORK     PIC 9(6)V99.


       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM UNTIL TRANS-CHOICE = 9
               DISPLAY "====================================="
               DISPLAY "      VIEW TRANSACTIONS MODULE      "
               DISPLAY "====================================="
               DISPLAY "Would you like to view your transactions?"
               DISPLAY " 1 - View by Account Number"
               DISPLAY " 2 - View Deposits"
               DISPLAY " 3 - View Withdrawals"
               DISPLAY " 9 - Return to Main Menu"
               ACCEPT TRANS-CHOICE

               EVALUATE TRANS-CHOICE
                   WHEN 1
                       DISPLAY "Enter Account Number: "
                       ACCEPT WS-FILTER-ACCT
                       PERFORM READ-BY-ACCOUNT
                       PERFORM NAV-PROMPT
                   WHEN 2
                       MOVE "CR" TO WS-FILTER-TYPE
                       PERFORM READ-BY-TYPE
                       PERFORM NAV-PROMPT
                   WHEN 3
                       MOVE "DR" TO WS-FILTER-TYPE
                       PERFORM READ-BY-TYPE
                       PERFORM NAV-PROMPT
                   WHEN 9
                       DISPLAY "Returning to Main Menu..."
                   WHEN OTHER
                       DISPLAY "Invalid selection."
               END-EVALUATE
           END-PERFORM
           GOBACK.

      *> READ-BY-ACCOUNT
      *> Opens the file, reads sequentially, and displays only
      *> records matching the entered account number.
      *> Demonstrates: OPEN, READ AT END, NOT AT END, CLOSE.
       READ-BY-ACCOUNT.
           MOVE 0 TO WS-EOF
           MOVE 0 TO WS-FOUND
           OPEN INPUT TRANSACTION-FILE
           DISPLAY "====================================="
           DISPLAY "Transactions for Account: "
               WS-FILTER-ACCT
           DISPLAY "DATE       TYPE DESCRIPTION         AMOUNT"
           DISPLAY "-------------------------------------"

           PERFORM UNTIL END-OF-FILE
               READ TRANSACTION-FILE
                   AT END
                       MOVE 1 TO WS-EOF
                   NOT AT END
                       IF TR-ACCOUNT = WS-FILTER-ACCT
                           PERFORM DISPLAY-RECORD
                           MOVE 1 TO WS-FOUND
                       END-IF
               END-READ
           END-PERFORM

           IF WS-FOUND = 0
               DISPLAY "No transactions found for account "
               DISPLAY WS-FILTER-ACCT
           END-IF

           CLOSE TRANSACTION-FILE
           DISPLAY "=====================================".
       
      *> READ-BY-TYPE
      *> Reads all records and filters by CR (credit) or DR (debit).
      *> WS-FILTER-TYPE is set by the caller before PERFORM.
       READ-BY-TYPE.
           MOVE 0 TO WS-EOF
           MOVE 0 TO WS-FOUND
           OPEN INPUT TRANSACTION-FILE

           IF WS-FILTER-TYPE = "CR"
               DISPLAY "====================================="
               DISPLAY "     DEPOSIT TRANSACTIONS (CR)       "
           ELSE
               DISPLAY "====================================="
               DISPLAY "   WITHDRAWAL TRANSACTIONS (DR)      "
           END-IF

           DISPLAY "DATE     ACCT    TYPE DESCRIPTION    AMOUNT"
           DISPLAY "-------------------------------------"

           PERFORM UNTIL END-OF-FILE
               READ TRANSACTION-FILE
                   AT END
                       MOVE 1 TO WS-EOF
                   NOT AT END
                       IF TR-TYPE = WS-FILTER-TYPE
                           PERFORM DISPLAY-RECORD-FULL
                           MOVE 1 TO WS-FOUND
                       END-IF
               END-READ
           END-PERFORM

           IF WS-FOUND = 0
               DISPLAY "No transactions of this type found."
           END-IF

           CLOSE TRANSACTION-FILE
           DISPLAY "=====================================".

      *> DISPLAY-RECORD
      *> Formats a single transaction for account-filtered view.
      *> TR-AMOUNT-RAW is stored as implied integer
      *> (e.g. 042069 = $420.69)
      *> COMPUTE shifts the decimal for display.
       DISPLAY-RECORD.
           COMPUTE WS-AMOUNT-WORK = TR-AMOUNT-RAW / 100
           MOVE WS-AMOUNT-WORK TO WS-DISPLAY-AMT
           DISPLAY TR-DATE " " TR-TYPE " "
               TR-DESCRIPTION " " WS-DISPLAY-AMT.
           
      *> DISPLAY-RECORD-FULL
      *> Formats a single transaction for type-filtered view,
      *> including the account number column.
       DISPLAY-RECORD-FULL.
           COMPUTE WS-AMOUNT-WORK = TR-AMOUNT-RAW / 100
           MOVE WS-AMOUNT-WORK TO WS-DISPLAY-AMT
           DISPLAY TR-DATE " " TR-ACCOUNT " " TR-TYPE " "
               TR-DESCRIPTION " " WS-DISPLAY-AMT.

      *> NAV-PROMPT
       NAV-PROMPT.
           DISPLAY "-------------------------------"
           DISPLAY " 0 - Back to View Transactions"
           DISPLAY " 9 - Return to Main Menu"
           ACCEPT NAV-CHOICE

           EVALUATE NAV-CHOICE
               WHEN 0
                   CONTINUE
               WHEN 9
                   MOVE 9 TO TRANS-CHOICE
               WHEN OTHER
                   DISPLAY "Invalid selection."
                   DISPLAY "Returning to Transactions menu."
           END-EVALUATE.
