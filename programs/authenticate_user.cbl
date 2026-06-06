       IDENTIFICATION DIVISION.
       PROGRAM-ID. AUTHUSER.

      *> AUTHENTICATE USER MODULE
      *> Demonstrates:
      *>  - OCCURS for in-memory credential table
      *>  - PERFORM VARYING with found-flag early exit pattern
      *>  - STRING for masked password display
      *>  - 88-level condition names for login state
      *>  - Annotated legacy antipattern (hardcoded credentials)
      *>
      *> REVIEW: Hardcoded credentials in WORKING-STORAGE are a
      *> classic legacy smell found throughout real mainfram COBOL.
      *> In prod, credentials would be retrieved from an
      *> encrypted VSAM dataset or passed via a security subsystem
      *> such as RACF (Resource Access Control Facility) on z/OS.
      *> This pattern is preserved here for historical accuracy and
      *> to demonstrate what a reviewer should flag immediately.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Credential Table
      *> REVIEW: Hardcoded user table. In prod, this would be
      *> an external VSAM file or RACF-controlled security profile.
       01 USER-TABLE.
           05 USER-ENTRY OCCURS 5 TIMES
                         INDEXED BY USER-IDX.
               10 UT-USERNAME     PIC X(10).
               10 UT-PASSWORD     PIC X(10).
               10 UT-ROLE         PIC X(10).
                   88 UT-ADMIN    VALUE "ADMIN    ".
                   88 UT-TELLER   VALUE "TELLER   ".
                   88 UT-AUDITOR  VALUE "AUDITOR  ".

      *> Input Fields
       01 WS-USERNAME        PIC X(10).
       01 WS-PASSWORD        PIC X(10).

      *> Auth State
       01 WS-AUTH-STATUS     PIC 9 VALUE 0.
           88 AUTH-SUCCESS   VALUE 1.
           88 AUTH-FAILED    VALUE 0.
       01 WS-FOUND-IDX       PIC 9 VALUE 0.
       01 WS-ATTEMPT         PIC 9 VALUE 0.
       01 MAX-ATTEMPTS       PIC 9 VALUE 3.

      *> Display
       01 WS-MASKED-PW      PIC X(10).
       01 WS-MASK-IDX        PIC 9 VALUE 0.
       01 WS-ROLE-DISPLAY    PIC X(10).

      * Navigation
       01 AUTH-CHOICE        PIC 9 VALUE 0. 

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           PERFORM LOAD-USERS
           PERFORM UNTIL AUTH-CHOICE = 9
               DISPLAY "====================================="
               DISPLAY "      AUTHENTICATE USER MODULE       "
               DISPLAY "====================================="
               DISPLAY " 1 - Login"
               DISPLAY " 9 - Return to Main Menu"
               ACCEPT AUTH-CHOICE

               EVALUATE AUTH-CHOICE
                   WHEN 1
                       PERFORM DO-LOGIN
                   WHEN 9
                       DISPLAY "Returning to Main Menu..."
                   WHEN OTHER
                       DISPLAY "Invalid selection."
               END-EVALUATE
           END-PERFORM
           GOBACK.

      *> LOAD-USERS
      *> Populates the credential table at runtime.
      *> REVIEW: Plaintext passwords in WORKING-STORAGE.
      *> A real system would store hashed values and compare via
      *> a secure subsystem, never directly in program memory.
       LOAD-USERS.
           MOVE "ADMIN     " TO UT-USERNAME(1)
           MOVE "ADMIN123  " TO UT-PASSWORD(1)
           MOVE "ADMIN     " TO UT-ROLE(1)

           MOVE "SPEREZ    " TO UT-USERNAME(2)
           MOVE "PASS1234  " TO UT-PASSWORD(2)
           MOVE "TELLER    " TO UT-ROLE(2)

           MOVE "SGERUS    " TO UT-USERNAME(3)
           MOVE "SECURE99  " TO UT-PASSWORD(3)
           MOVE "TELLER    " TO UT-ROLE(3)

           MOVE "AVASQUEZ  " TO UT-USERNAME(4)
           MOVE "AUDIT2026 " TO UT-PASSWORD(4)
           MOVE "AUDITOR   " TO UT-ROLE(4)

           MOVE "JGLOVER   " TO UT-USERNAME(5)
           MOVE "BANK5678  " TO UT-PASSWORD(5)
           MOVE "TELLER    " TO UT-ROLE(5).

      *> DO-LOGIN
      *> Accepts credentials and performs a table lookup.
      *> Limits attempts to MAX-ATTEMPTS (3) before lockout.
       DO-LOGIN.
           MOVE 0 TO WS-ATTEMPT
           MOVE 0 TO WS-AUTH-STATUS

           PERFORM UNTIL AUTH-SUCCESS
               OR WS-ATTEMPT >= MAX-ATTEMPTS

               ADD 1 TO WS-ATTEMPT

               DISPLAY "-------------------------------------"
               DISPLAY "Username: "
               ACCEPT WS-USERNAME
               DISPLAY "Password: "
               ACCEPT WS-PASSWORD

               PERFORM MASK-PASSWORD
               DISPLAY "Authenticating: " WS-USERNAME
               DISPLAY "Password      : " WS-MASKED-PW

               PERFORM TABLE-LOOKUP

               IF AUTH-FAILED
                   DISPLAY "** Login failed. Invalid credentials."
                   IF WS-ATTEMPT < MAX-ATTEMPTS
                       COMPUTE WS-MASK-IDX =
                           MAX-ATTEMPTS - WS-ATTEMPT
                       DISPLAY "Attempts remaining: " WS-MASK-IDX
                   END-IF
               END-IF
           END-PERFORM

           IF AUTH-SUCCESS
               PERFORM SHOW-WELCOME
           ELSE
               DISPLAY "====================================="
               DISPLAY "** ACCOUNT LOCKED: Too many failed "
               DISPLAY "** attempts. Contact administrator. "
               DISPLAY "====================================="
           END-IF

           MOVE 0 TO WS-AUTH-STATUS
           MOVE 0 TO WS-ATTEMPT.

      *> TABLE-LOOKUP
      *> Iterates USER-TABLE using PERFORM VARYING.
      *> Sets AUTH-SUCCESS via 88-level when match is found.
      *> WS-FOUND-IDX stores the matched row for role display.
      *>
      *> REVIEW: Linear table scan is 0(n). Production systems us
      *> binary search or hash lookup for large user tables.
      *> For small fixed tables (< 50 entries), this pattern is
      *> acceptable and common in legacy COBOL.
       TABLE-LOOKUP.
           MOVE 0 TO WS-FOUND-IDX

           PERFORM VARYING USER-IDX FROM 1 BY 1
               UNTIL USER-IDX > 5
               OR WS-FOUND-IDX > 0

               IF UT-USERNAME(USER-IDX) = WS-USERNAME
               AND UT-PASSWORD(USER-IDX) = WS-PASSWORD
                   MOVE 1 TO WS-AUTH-STATUS
                   MOVE USER-IDX TO WS-FOUND-IDX
               END-IF

           END-PERFORM.

      *> MASK-PASSWORD
      *> Builds a masked version of WS-PASSWORD for display.
      *> Uses STRING to concetenate asterisks positionally.
      *> Demonstrates STRING ... DELIMITED SIZE pattern.
       MASK-PASSWORD.
           MOVE SPACES TO WS-MASKED-PW
           STRING "**********"
               DELIMITED SIZE
               INTO WS-MASKED-PW.

      *> SHOW-WELCOME
      *> Displays a role-aware welcome message after login.
      *> Uses 88-level condition names on UT-ROLE for branching.
       SHOW-WELCOME.
           MOVE UT-ROLE(WS-FOUND-IDX) TO WS-ROLE-DISPLAY
           DISPLAY "====================================="
           DISPLAY "          LOGIN SUCCESSFUL           "
           DISPLAY "====================================="
           DISPLAY " Welcome, " WS-USERNAME
           DISPLAY " Role   : " WS-ROLE-DISPLAY

           EVALUATE TRUE
               WHEN UT-ADMIN(WS-FOUND-IDX)
                   DISPLAY "  Access  : FULL SYSTEM ACCESS"
               WHEN UT-TELLER(WS-FOUND-IDX)
                   DISPLAY "  Access  : TELLER OPERATIONS"
               WHEN UT-AUDITOR(WS-FOUND-IDX)
                   DISPLAY "  Access  : READ-ONLY AUDIT VIEW"
               WHEN OTHER
                   DISPLAY "  Access  : STANDARD"
           END-EVALUATE

           DISPLAY "====================================="
           DISPLAY "Press ENTER to continue."
           ACCEPT OMITTED.
