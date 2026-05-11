       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARTINV.
      *================================================================*
      * PARTINV - PARTS INVENTORY BATCH PROCESSING                    *
      *                                                                *
      * NIGHTLY BATCH PROGRAM THAT PROCESSES INVENTORY TRANSACTIONS   *
      * FROM THE DAILY TRANSACTION FILE. UPDATES PART MASTER RECORDS  *
      * IN THE IMS DATABASE AND GENERATES AN INVENTORY VALUATION      *
      * REPORT FOR THE PLANT CONTROLLER.                               *
      *                                                                *
      * TRANSACTION TYPES:                                             *
      *   RC - RECEIPT:     ADD STOCK FROM SUPPLIER DELIVERY           *
      *   IS - ISSUE:       DEDUCT STOCK FOR PRODUCTION ORDER          *
      *   AJ - ADJUSTMENT:  PHYSICAL COUNT CORRECTION                  *
      *   TR - TRANSFER:    INTER-WAREHOUSE MOVEMENT                   *
      *                                                                *
      * INPUT:  DAILY TRANSACTION FILE (INVTRANS DD)                   *
      * OUTPUT: INVENTORY VALUATION REPORT (INVRPT DD)                 *
      *         EXCEPTION REPORT (EXCPRPT DD)                          *
      *                                                                *
      * IMS:    GHU/REPL ON PARTSEG VIA MFGDB DATABASE                 *
      *================================================================*
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANS-FILE  ASSIGN TO INVTRANS
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-TRANS-STATUS.
           SELECT REPORT-FILE ASSIGN TO INVRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.
           SELECT EXCEPT-FILE ASSIGN TO EXCPRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-EXC-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
      *
       FD  TRANS-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS.
       01  TRANS-RECORD.
           05  TR-TRAN-TYPE              PIC X(2).
               88  TR-RECEIPT                VALUE 'RC'.
               88  TR-ISSUE                  VALUE 'IS'.
               88  TR-ADJUSTMENT             VALUE 'AJ'.
               88  TR-TRANSFER               VALUE 'TR'.
           05  TR-PART-NUMBER            PIC X(15).
           05  TR-QUANTITY               PIC S9(9)   COMP-3.
           05  TR-UNIT-COST              PIC S9(7)V99 COMP-3.
           05  TR-FROM-WAREHOUSE         PIC X(4).
           05  TR-TO-WAREHOUSE           PIC X(4).
           05  TR-REFERENCE-NUM          PIC X(12).
           05  TR-TRAN-DATE              PIC X(8).
           05  TR-OPERATOR-ID            PIC X(8).
           05  FILLER                    PIC X(11).
      *
       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  REPORT-RECORD                 PIC X(132).
      *
       FD  EXCEPT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  EXCEPT-RECORD                 PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
           COPY PARTMSTR.
           COPY ERRCODES.
      *
       01  WS-FILE-STATUS.
           05  WS-TRANS-STATUS           PIC XX.
           05  WS-RPT-STATUS             PIC XX.
           05  WS-EXC-STATUS             PIC XX.
      *
       01  WS-FLAGS.
           05  WS-EOF-FLAG               PIC X(1)  VALUE 'N'.
               88  WS-END-OF-FILE            VALUE 'Y'.
               88  WS-NOT-EOF                VALUE 'N'.
      *
       01  WS-COUNTERS.
           05  WS-TRANS-READ             PIC S9(7) COMP-3 VALUE 0.
           05  WS-TRANS-PROCESSED        PIC S9(7) COMP-3 VALUE 0.
           05  WS-TRANS-ERRORS           PIC S9(7) COMP-3 VALUE 0.
           05  WS-RECEIPTS               PIC S9(7) COMP-3 VALUE 0.
           05  WS-ISSUES                 PIC S9(7) COMP-3 VALUE 0.
           05  WS-ADJUSTMENTS            PIC S9(7) COMP-3 VALUE 0.
           05  WS-TRANSFERS              PIC S9(7) COMP-3 VALUE 0.
      *
       01  WS-VALUATION.
           05  WS-TOTAL-VALUE            PIC S9(13)V99 COMP-3
                                         VALUE 0.
           05  WS-LINE-VALUE             PIC S9(11)V99 COMP-3.
      *
       01  WS-DLI-FUNCTIONS.
           05  WS-GU                     PIC X(4)  VALUE 'GU  '.
           05  WS-GHU                    PIC X(4)  VALUE 'GHU '.
           05  WS-REPL                   PIC X(4)  VALUE 'REPL'.
      *
       01  WS-SSA-PART.
           05  FILLER                    PIC X(9)
               VALUE 'PARTSEG '.
           05  FILLER                    PIC X(1)  VALUE '('.
           05  FILLER                    PIC X(10)
               VALUE 'PARTNO   ='.
           05  WS-SSA-PART-KEY           PIC X(15).
           05  FILLER                    PIC X(1)  VALUE ')'.
      *
       01  WS-REPORT-HDR.
           05  FILLER                    PIC X(40)
               VALUE '  INVENTORY VALUATION REPORT            '.
           05  WS-RPT-DATE              PIC X(10).
           05  FILLER                    PIC X(82) VALUE SPACES.
      *
       01  WS-REPORT-DTL.
           05  WS-DTL-PART               PIC X(15).
           05  FILLER                    PIC X(2) VALUE SPACES.
           05  WS-DTL-DESC               PIC X(30).
           05  FILLER                    PIC X(2) VALUE SPACES.
           05  WS-DTL-QOH               PIC Z(8)9-.
           05  FILLER                    PIC X(2) VALUE SPACES.
           05  WS-DTL-COST              PIC Z(6)9.99-.
           05  FILLER                    PIC X(2) VALUE SPACES.
           05  WS-DTL-VALUE             PIC Z(10)9.99-.
           05  FILLER                    PIC X(37) VALUE SPACES.
      *
       01  WS-CURRENT-DATE              PIC X(8).
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
           PERFORM 2000-PROCESS-TRANSACTIONS
               UNTIL WS-END-OF-FILE
           PERFORM 3000-GENERATE-REPORT
           PERFORM 9000-TERMINATE
           GOBACK.
      *
       1000-INITIALIZE.
           OPEN INPUT  TRANS-FILE
           OPEN OUTPUT REPORT-FILE
           OPEN OUTPUT EXCEPT-FILE
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD
           MOVE WS-CURRENT-DATE TO WS-RPT-DATE
           WRITE REPORT-RECORD FROM WS-REPORT-HDR
           PERFORM 1100-READ-TRANSACTION.
      *
       1100-READ-TRANSACTION.
           READ TRANS-FILE
               AT END
                   SET WS-END-OF-FILE TO TRUE
               NOT AT END
                   ADD 1 TO WS-TRANS-READ
           END-READ.
      *
       2000-PROCESS-TRANSACTIONS.
           EVALUATE TRUE
               WHEN TR-RECEIPT
                   PERFORM 2100-PROCESS-RECEIPT
               WHEN TR-ISSUE
                   PERFORM 2200-PROCESS-ISSUE
               WHEN TR-ADJUSTMENT
                   PERFORM 2300-PROCESS-ADJUSTMENT
               WHEN TR-TRANSFER
                   PERFORM 2400-PROCESS-TRANSFER
               WHEN OTHER
                   PERFORM 2900-LOG-ERROR
           END-EVALUATE
           PERFORM 1100-READ-TRANSACTION.
      *
       2100-PROCESS-RECEIPT.
           MOVE TR-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GHU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               ADD TR-QUANTITY TO PM-QTY-ON-HAND
               SUBTRACT TR-QUANTITY FROM PM-QTY-ON-ORDER
               IF PM-QTY-ON-ORDER < 0
                   MOVE 0 TO PM-QTY-ON-ORDER
               END-IF
               COMPUTE PM-WEIGHTED-AVG-COST =
                   ((PM-WEIGHTED-AVG-COST * (PM-QTY-ON-HAND
                       - TR-QUANTITY))
                   + (TR-UNIT-COST * TR-QUANTITY))
                   / PM-QTY-ON-HAND
               MOVE TR-TRAN-DATE TO PM-LAST-RECEIPT-DATE
               CALL 'CBLTDLI' USING WS-REPL DB-PCB
                   PART-MASTER-RECORD
               ADD 1 TO WS-RECEIPTS
               ADD 1 TO WS-TRANS-PROCESSED
           ELSE
               MOVE ERR-PART-NOT-FOUND TO WS-ERR-CODE
               PERFORM 2900-LOG-ERROR
           END-IF.
      *
       2200-PROCESS-ISSUE.
           MOVE TR-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GHU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               IF PM-QTY-ON-HAND >= TR-QUANTITY
                   SUBTRACT TR-QUANTITY FROM PM-QTY-ON-HAND
                   ADD TR-QUANTITY TO PM-QTY-ALLOCATED
                   MOVE TR-TRAN-DATE TO PM-LAST-ISSUE-DATE
                   CALL 'CBLTDLI' USING WS-REPL DB-PCB
                       PART-MASTER-RECORD
                   ADD 1 TO WS-ISSUES
                   ADD 1 TO WS-TRANS-PROCESSED
               ELSE
                   MOVE ERR-INSUFFICIENT-STOCK TO WS-ERR-CODE
                   PERFORM 2900-LOG-ERROR
               END-IF
           ELSE
               MOVE ERR-PART-NOT-FOUND TO WS-ERR-CODE
               PERFORM 2900-LOG-ERROR
           END-IF.
      *
       2300-PROCESS-ADJUSTMENT.
           MOVE TR-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GHU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               MOVE TR-QUANTITY TO PM-QTY-ON-HAND
               CALL 'CBLTDLI' USING WS-REPL DB-PCB
                   PART-MASTER-RECORD
               ADD 1 TO WS-ADJUSTMENTS
               ADD 1 TO WS-TRANS-PROCESSED
           ELSE
               MOVE ERR-PART-NOT-FOUND TO WS-ERR-CODE
               PERFORM 2900-LOG-ERROR
           END-IF.
      *
       2400-PROCESS-TRANSFER.
           MOVE TR-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GHU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               IF PM-QTY-ON-HAND >= TR-QUANTITY
                   SUBTRACT TR-QUANTITY FROM PM-QTY-ON-HAND
                   MOVE TR-TO-WAREHOUSE TO PM-WAREHOUSE-CODE
                   CALL 'CBLTDLI' USING WS-REPL DB-PCB
                       PART-MASTER-RECORD
                   ADD 1 TO WS-TRANSFERS
                   ADD 1 TO WS-TRANS-PROCESSED
               ELSE
                   MOVE ERR-INSUFFICIENT-STOCK TO WS-ERR-CODE
                   PERFORM 2900-LOG-ERROR
               END-IF
           ELSE
               MOVE ERR-PART-NOT-FOUND TO WS-ERR-CODE
               PERFORM 2900-LOG-ERROR
           END-IF.
      *
       2900-LOG-ERROR.
           ADD 1 TO WS-TRANS-ERRORS
           STRING 'ERROR ' WS-ERR-CODE ' PART='
               TR-PART-NUMBER ' TRAN=' TR-TRAN-TYPE
               ' REF=' TR-REFERENCE-NUM
               DELIMITED BY SIZE INTO EXCEPT-RECORD
           WRITE EXCEPT-RECORD.
      *
       3000-GENERATE-REPORT.
           CONTINUE.
      *
       9000-TERMINATE.
           CLOSE TRANS-FILE
           CLOSE REPORT-FILE
           CLOSE EXCEPT-FILE.
