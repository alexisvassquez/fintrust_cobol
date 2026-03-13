       IDENTIFICATION DIVISION.
       PROGRAM-ID. VIEWTRANS.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 TRANS-CHOICE       PIC 9 VALUE 0.
       01 NAV-CHOICE         PIC 9 VALUE 0.
       01 ACCOUNT-NUMBER     PIC X(10).

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
                       ACCEPT ACCOUNT-NUMBER
                       DISPLAY "-------------------------------"
                       DISPLAY "Transactions for Account: " 
                       DISPLAY ACCOUNT-NUMBER
                       DISPLAY "03/12/2026 ACH CREDIT    +586.36"
                       DISPLAY "03/11/2026 POS PURCHASE  -68.75"
                       DISPLAY "03/08/2026 ATM WITHDRAW  -20.00"
                       PERFORM NAVIGATION-PROMPT

                   WHEN 2
                       DISPLAY "Deposit Transactions: "
                       DISPLAY "-------------------------------"
                       DISPLAY "03/10/2026 MOBILE DEPOSIT +999.99"
                       DISPLAY "03/08/2026 ACH CREDIT     +420.69"
                       DISPLAY "03/05/2026 CASH DEPOSIT   +705.00"
                       PERFORM NAVIGATION-PROMPT

                   WHEN 3
                       DISPLAY "Withdrawal Transactions: "
                       DISPLAY "-------------------------------"
                       DISPLAY "03/12/2026 POS PURCHASE    -21.24"
                       DISPLAY "03/11/2026 POS PURCHASE    -68.75"
                       DISPLAY "03/08/2026 ATM WITHDRAW    -20.00"
                       PERFORM NAVIGATION-PROMPT

                   WHEN 9
                       DISPLAY "Returning to Main Menu..."

                   WHEN OTHER
                       DISPLAY "Invalid selection."
               END-EVALUATE
           END-PERFORM

           GOBACK.

       NAVIGATION-PROMPT.
           DISPLAY "Select next action: "
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
