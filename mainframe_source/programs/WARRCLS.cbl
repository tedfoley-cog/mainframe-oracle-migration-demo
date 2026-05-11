       IDENTIFICATION DIVISION.
       PROGRAM-ID. WARRCLS.
      *================================================================*
      * WARRCLS - WARRANTY CLAIMS SETTLEMENT PROCESSING               *
      *                                                                *
      * BATCH PROGRAM THAT PROCESSES WARRANTY CLAIMS FROM DEALERS.     *
      * VALIDATES CLAIM DATA AGAINST PART MASTER (WARRANTY PERIOD,    *
      * DEFECT TYPE, MILEAGE), CALCULATES SETTLEMENT AMOUNTS, AND    *
      * GENERATES PAYMENT AUTHORIZATION RECORDS.                       *
      *                                                                *
      * WARRANTY TYPES:                                                *
      *   BW - BUMPER-TO-BUMPER (36 MONTHS / 36,000 MILES)            *
      *   PT - POWERTRAIN (60 MONTHS / 60,000 MILES)                  *
      *   EM - EMISSIONS (96 MONTHS / 80,000 MILES)                   *
      *   CR - CORROSION (120 MONTHS / UNLIMITED MILES)               *
      *                                                                *
      * INPUT:  DEALER CLAIMS FILE (CLAIMSIN DD)                       *
      * OUTPUT: PAYMENT AUTHORIZATION (PAYAUTH DD)                     *
      *         REJECTED CLAIMS (CLMREJ DD)                            *
      *         CLAIMS SUMMARY REPORT (CLMSUMM DD)                     *
      *                                                                *
      * IMS: GU ON PARTSEG, DB2 CALL FOR CLAIMS HISTORY TABLE         *
      *================================================================*
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CLAIMS-IN    ASSIGN TO CLAIMSIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-CLM-STATUS.
           SELECT PAY-AUTH     ASSIGN TO PAYAUTH
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-PAY-STATUS.
           SELECT CLAIM-REJECT ASSIGN TO CLMREJ
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-REJ-STATUS.
           SELECT CLAIM-SUMM   ASSIGN TO CLMSUMM
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SUM-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
      *
       FD  CLAIMS-IN
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 250 CHARACTERS.
       01  CLAIM-INPUT-RECORD.
           05  CL-CLAIM-NUMBER           PIC X(12).
           05  CL-DEALER-CODE            PIC X(8).
           05  CL-VIN                    PIC X(17).
           05  CL-PART-NUMBER            PIC X(15).
           05  CL-WARRANTY-TYPE          PIC X(2).
               88  CL-BUMPER-TO-BUMPER       VALUE 'BW'.
               88  CL-POWERTRAIN             VALUE 'PT'.
               88  CL-EMISSIONS              VALUE 'EM'.
               88  CL-CORROSION              VALUE 'CR'.
           05  CL-DEFECT-CODE            PIC X(6).
           05  CL-REPAIR-DATE            PIC X(8).
           05  CL-MILEAGE                PIC S9(7)   COMP-3.
           05  CL-SALE-DATE              PIC X(8).
           05  CL-LABOR-HOURS            PIC S9(3)V99 COMP-3.
           05  CL-LABOR-RATE             PIC S9(5)V99 COMP-3.
           05  CL-PARTS-COST             PIC S9(7)V99 COMP-3.
           05  CL-SUBLET-COST            PIC S9(7)V99 COMP-3.
           05  CL-DESCRIPTION            PIC X(60).
           05  FILLER                    PIC X(86).
      *
       FD  PAY-AUTH
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  PAY-AUTH-RECORD               PIC X(132).
      *
       FD  CLAIM-REJECT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  CLAIM-REJECT-RECORD           PIC X(132).
      *
       FD  CLAIM-SUMM
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  CLAIM-SUMM-RECORD             PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
           COPY PARTMSTR.
           COPY ERRCODES.
      *
       01  WS-FILE-STATUS.
           05  WS-CLM-STATUS             PIC XX.
           05  WS-PAY-STATUS             PIC XX.
           05  WS-REJ-STATUS             PIC XX.
           05  WS-SUM-STATUS             PIC XX.
      *
       01  WS-FLAGS.
           05  WS-EOF-FLAG               PIC X(1) VALUE 'N'.
               88  WS-END-OF-FILE            VALUE 'Y'.
           05  WS-VALID-CLAIM            PIC X(1) VALUE 'Y'.
               88  WS-CLAIM-VALID            VALUE 'Y'.
               88  WS-CLAIM-INVALID          VALUE 'N'.
      *
       01  WS-WARRANTY-LIMITS.
           05  WS-BW-MONTHS              PIC S9(3) COMP VALUE 36.
           05  WS-BW-MILES               PIC S9(7) COMP VALUE 36000.
           05  WS-PT-MONTHS              PIC S9(3) COMP VALUE 60.
           05  WS-PT-MILES               PIC S9(7) COMP VALUE 60000.
           05  WS-EM-MONTHS              PIC S9(3) COMP VALUE 96.
           05  WS-EM-MILES               PIC S9(7) COMP VALUE 80000.
           05  WS-CR-MONTHS              PIC S9(3) COMP VALUE 120.
      *
       01  WS-CALCULATION-FIELDS.
           05  WS-TOTAL-LABOR            PIC S9(9)V99 COMP-3.
           05  WS-TOTAL-CLAIM            PIC S9(9)V99 COMP-3.
           05  WS-COVERAGE-PCT           PIC S9(1)V99 COMP-3.
           05  WS-SETTLEMENT-AMT         PIC S9(9)V99 COMP-3.
      *
       01  WS-DATE-WORK.
           05  WS-REPAIR-YYYY            PIC 9(4).
           05  WS-REPAIR-MM              PIC 9(2).
           05  WS-REPAIR-DD              PIC 9(2).
           05  WS-SALE-YYYY              PIC 9(4).
           05  WS-SALE-MM                PIC 9(2).
           05  WS-SALE-DD                PIC 9(2).
           05  WS-MONTHS-ELAPSED         PIC S9(5) COMP-3.
           05  WS-WARRANTY-MONTHS        PIC S9(3) COMP.
           05  WS-WARRANTY-MILES         PIC S9(7) COMP.
      *
       01  WS-COUNTERS.
           05  WS-CLAIMS-READ            PIC S9(7) COMP-3 VALUE 0.
           05  WS-CLAIMS-APPROVED        PIC S9(7) COMP-3 VALUE 0.
           05  WS-CLAIMS-REJECTED        PIC S9(7) COMP-3 VALUE 0.
           05  WS-TOTAL-SETTLEMENTS      PIC S9(11)V99 COMP-3
                                         VALUE 0.
      *
       01  WS-DLI-FUNCTIONS.
           05  WS-GU                     PIC X(4) VALUE 'GU  '.
      *
       01  WS-SSA-PART.
           05  FILLER                    PIC X(9)
               VALUE 'PARTSEG '.
           05  FILLER                    PIC X(1) VALUE '('.
           05  FILLER                    PIC X(10)
               VALUE 'PARTNO   ='.
           05  WS-SSA-PART-KEY           PIC X(15).
           05  FILLER                    PIC X(1) VALUE ')'.
      *
       01  WS-PAY-AUTH-DTL.
           05  WS-PA-CLAIM               PIC X(12).
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-PA-DEALER              PIC X(8).
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-PA-VIN                 PIC X(17).
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-PA-SETTLEMENT          PIC Z(8)9.99-.
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-PA-TYPE                PIC X(2).
           05  FILLER                    PIC X(67) VALUE SPACES.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  IO-LTERM-NAME            PIC X(8).
           05  IO-RESERVE               PIC XX.
           05  IO-STATUS-CODE           PIC XX.
      *
       01  DB-PCB.
           05  DB-DBD-NAME              PIC X(8).
           05  DB-SEG-LEVEL             PIC XX.
           05  DB-STATUS-CODE           PIC XX.
           05  DB-PROC-OPTIONS          PIC X(4).
           05  DB-RESERVE-DLI           PIC S9(5) COMP.
           05  DB-SEG-NAME              PIC X(8).
           05  DB-LENGTH-FB-KEY         PIC S9(5) COMP.
           05  DB-NUM-SENS-SEGS         PIC S9(5) COMP.
           05  DB-KEY-FB-AREA           PIC X(30).
      *
       PROCEDURE DIVISION USING IO-PCB DB-PCB.
      *
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-CLAIMS
               UNTIL WS-END-OF-FILE
           PERFORM 3000-GENERATE-SUMMARY
           PERFORM 9000-TERMINATE
           GOBACK.
      *
       1000-INITIALIZE.
           OPEN INPUT  CLAIMS-IN
           OPEN OUTPUT PAY-AUTH
           OPEN OUTPUT CLAIM-REJECT
           OPEN OUTPUT CLAIM-SUMM
           PERFORM 1100-READ-CLAIM.
      *
       1100-READ-CLAIM.
           READ CLAIMS-IN
               AT END
                   SET WS-END-OF-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-CLAIMS-READ
           END-READ.
      *
       2000-PROCESS-CLAIMS.
           MOVE 'Y' TO WS-VALID-CLAIM
           PERFORM 2100-VALIDATE-WARRANTY-PERIOD
           IF WS-CLAIM-VALID
               PERFORM 2200-VALIDATE-MILEAGE
           END-IF
           IF WS-CLAIM-VALID
               PERFORM 2300-VALIDATE-PART
           END-IF
           IF WS-CLAIM-VALID
               PERFORM 2400-CALCULATE-SETTLEMENT
               PERFORM 2500-WRITE-APPROVAL
           ELSE
               PERFORM 2600-WRITE-REJECTION
           END-IF
           PERFORM 1100-READ-CLAIM.
      *
       2100-VALIDATE-WARRANTY-PERIOD.
           MOVE CL-REPAIR-DATE(1:4) TO WS-REPAIR-YYYY
           MOVE CL-REPAIR-DATE(5:2) TO WS-REPAIR-MM
           MOVE CL-SALE-DATE(1:4)   TO WS-SALE-YYYY
           MOVE CL-SALE-DATE(5:2)   TO WS-SALE-MM
           COMPUTE WS-MONTHS-ELAPSED =
               ((WS-REPAIR-YYYY - WS-SALE-YYYY) * 12) +
               (WS-REPAIR-MM - WS-SALE-MM)
           EVALUATE TRUE
               WHEN CL-BUMPER-TO-BUMPER
                   MOVE WS-BW-MONTHS TO WS-WARRANTY-MONTHS
                   MOVE WS-BW-MILES  TO WS-WARRANTY-MILES
               WHEN CL-POWERTRAIN
                   MOVE WS-PT-MONTHS TO WS-WARRANTY-MONTHS
                   MOVE WS-PT-MILES  TO WS-WARRANTY-MILES
               WHEN CL-EMISSIONS
                   MOVE WS-EM-MONTHS TO WS-WARRANTY-MONTHS
                   MOVE WS-EM-MILES  TO WS-WARRANTY-MILES
               WHEN CL-CORROSION
                   MOVE WS-CR-MONTHS TO WS-WARRANTY-MONTHS
                   MOVE 9999999      TO WS-WARRANTY-MILES
               WHEN OTHER
                   SET WS-CLAIM-INVALID TO TRUE
           END-EVALUATE
           IF WS-MONTHS-ELAPSED > WS-WARRANTY-MONTHS
               SET WS-CLAIM-INVALID TO TRUE
           END-IF.
      *
       2200-VALIDATE-MILEAGE.
           IF CL-MILEAGE > WS-WARRANTY-MILES
               SET WS-CLAIM-INVALID TO TRUE
           END-IF.
      *
       2300-VALIDATE-PART.
           MOVE CL-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE NOT = '  '
               SET WS-CLAIM-INVALID TO TRUE
           END-IF.
      *
       2400-CALCULATE-SETTLEMENT.
           COMPUTE WS-TOTAL-LABOR =
               CL-LABOR-HOURS * CL-LABOR-RATE
           COMPUTE WS-TOTAL-CLAIM =
               WS-TOTAL-LABOR + CL-PARTS-COST + CL-SUBLET-COST
           EVALUATE TRUE
               WHEN CL-BUMPER-TO-BUMPER
                   MOVE 1.00 TO WS-COVERAGE-PCT
               WHEN CL-POWERTRAIN
                   MOVE 1.00 TO WS-COVERAGE-PCT
               WHEN CL-EMISSIONS
                   MOVE 1.00 TO WS-COVERAGE-PCT
               WHEN CL-CORROSION
                   IF WS-MONTHS-ELAPSED > 60
                       COMPUTE WS-COVERAGE-PCT =
                           1.00 - ((WS-MONTHS-ELAPSED - 60)
                                   * 0.01)
                       IF WS-COVERAGE-PCT < 0.50
                           MOVE 0.50 TO WS-COVERAGE-PCT
                       END-IF
                   ELSE
                       MOVE 1.00 TO WS-COVERAGE-PCT
                   END-IF
           END-EVALUATE
           COMPUTE WS-SETTLEMENT-AMT =
               WS-TOTAL-CLAIM * WS-COVERAGE-PCT.
      *
       2500-WRITE-APPROVAL.
           ADD 1 TO WS-CLAIMS-APPROVED
           ADD WS-SETTLEMENT-AMT TO WS-TOTAL-SETTLEMENTS
           MOVE CL-CLAIM-NUMBER  TO WS-PA-CLAIM
           MOVE CL-DEALER-CODE   TO WS-PA-DEALER
           MOVE CL-VIN            TO WS-PA-VIN
           MOVE WS-SETTLEMENT-AMT TO WS-PA-SETTLEMENT
           MOVE CL-WARRANTY-TYPE TO WS-PA-TYPE
           WRITE PAY-AUTH-RECORD FROM WS-PAY-AUTH-DTL.
      *
       2600-WRITE-REJECTION.
           ADD 1 TO WS-CLAIMS-REJECTED
           STRING 'REJECTED: ' CL-CLAIM-NUMBER
               ' REASON: WARRANTY/MILEAGE EXCEEDED'
               DELIMITED BY SIZE INTO CLAIM-REJECT-RECORD
           WRITE CLAIM-REJECT-RECORD.
      *
       3000-GENERATE-SUMMARY.
           CONTINUE.
      *
       9000-TERMINATE.
           CLOSE CLAIMS-IN
           CLOSE PAY-AUTH
           CLOSE CLAIM-REJECT
           CLOSE CLAIM-SUMM.
