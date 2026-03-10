       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTMGMT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 ACCT-CHOICE        PIC 9 VALUE 0.
       01 NAV-CHOICE         PIC 9 VALUE 0.
       01 ACCOUNT-NUMBER     PIC X(10).
       01 ACCOUNT-STATUS     PIC X(10).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM UNTIL ACCT-CHOICE = 9
               DISPLAY "====================================="
               DISPLAY "      ACCOUNT MANAGEMENT MODULE      "     
               DISPLAY "====================================="
               DISPLAY "Welcome to your Account Management. :)"
               DISPLAY " 1 - View Account Details"
               DISPLAY " 2 - Open New Account"
               DISPLAY " 3 - Close Existing Account"
               DISPLAY " 4 - Update Account Status"
               DISPLAY " 9 - Return to Main Menu"
               ACCEPT ACCT-CHOICE

               EVALUATE ACCT-CHOICE
                   WHEN 1
                       DISPLAY "Enter Account Number: "
                       ACCEPT ACCOUNT-NUMBER
                       DISPLAY "-------------------------------------"
                       DISPLAY "Account Number : " ACCOUNT-NUMBER
                       DISPLAY "Account Type   : CHECKING"
                       DISPLAY "Status         : ACTIVE"
                       DISPLAY "Balance        : $999.99"
                       PERFORM NAVIGATION-PROMPT

                   WHEN 2
                       DISPLAY "Opening new account..."
                       DISPLAY "Feature is simulated."
                       PERFORM NAVIGATION-PROMPT

                   WHEN 3
                       DISPLAY "Enter Account Number to Close: "
                       ACCEPT ACCOUNT-NUMBER
                       DISPLAY "Account " ACCOUNT-NUMBER
                       DISPLAY "marked for closure review."
                       DISPLAY "Feature is simulated."
                       PERFORM NAVIGATION-PROMPT

                   WHEN 4
                       DISPLAY "Enter Account Number: "
                       ACCEPT ACCOUNT-NUMBER
                       DISPLAY "Enter New Status (ACTIVE/HOLD): "
                       ACCEPT ACCOUNT-STATUS
                       DISPLAY "Account " ACCOUNT-NUMBER
                       DISPLAY "Status updated to " ACCOUNT-STATUS
                       PERFORM NAVIGATION-PROMPT

                   WHEN 9
                       DISPLAY "Returning to Main Menu..."

                   WHEN OTHER
                       DISPLAY "Invalid selection."
                       DISPLAY "Returning to Accout Management menu."
               END-EVALUATE
           END-PERFORM

           GOBACK.

       NAVIGATION-PROMPT.
           DISPLAY "-------------------------------------"
           DISPLAY "Select next action: "
           DISPLAY " 0 - Back to Account Management"
           DISPLAY " 9 - Return to Main Menu."
           ACCEPT NAV-CHOICE

           EVALUATE NAV-CHOICE
               WHEN 0
                   CONTINUE
               WHEN 9
                   MOVE 9 TO ACCT-CHOICE
               WHEN OTHER
                   DISPLAY "Invalid selection."
                   DISPLAY "Returning to Account Management menu."
           END-EVALUATE.
