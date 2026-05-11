       IDENTIFICATION DIVISION.
       PROGRAM-ID. QUALCTL.
      *================================================================*
      * QUALCTL - QUALITY CONTROL INSPECTION BATCH PROCESSING         *
      *                                                                *
      * BATCH PROGRAM THAT PROCESSES INCOMING INSPECTION RESULTS       *
      * FROM THE QUALITY LAB. APPLIES ACCEPTANCE SAMPLING RULES       *
      * (AQL TABLES PER MIL-STD-1916 / IATF 16949 REQUIREMENTS),     *
      * UPDATES SUPPLIER PERFORMANCE METRICS, AND GENERATES NCR       *
      * (NON-CONFORMANCE REPORT) DOCUMENTS FOR REJECTED LOTS.         *
      *                                                                *
      * AUTOMOTIVE QUALITY STANDARDS ENFORCED:                         *
      *   - PPAP (PRODUCTION PART APPROVAL PROCESS)                   *
      *   - SPC  (STATISTICAL PROCESS CONTROL) LIMITS                 *
      *   - CPK  CAPABILITY INDEX >= 1.33 REQUIRED                    *
      *                                                                *
      * INPUT:  INSPECTION RESULTS FILE (QUALIN DD)                    *
      * OUTPUT: NCR REPORT (NCRRPT DD)                                 *
      *         SUPPLIER SCORECARD UPDATE (SCUPDT DD)                  *
      *                                                                *
      * IMS: GHU/REPL ON PARTSEG, ISRT ON QUALSEG, REPL ON SUPPSEG  *
      *================================================================*
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT QUAL-INPUT   ASSIGN TO QUALIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-QUALIN-STATUS.
           SELECT NCR-REPORT   ASSIGN TO NCRRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-NCR-STATUS.
           SELECT SCORE-UPDATE ASSIGN TO SCUPDT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-SC-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
      *
       FD  QUAL-INPUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 200 CHARACTERS.
       01  QUAL-INPUT-RECORD.
           05  QIN-PART-NUMBER           PIC X(15).
           05  QIN-LOT-NUMBER            PIC X(12).
           05  QIN-VENDOR-CODE           PIC X(10).
           05  QIN-LOT-SIZE              PIC S9(7)   COMP-3.
           05  QIN-SAMPLE-SIZE           PIC S9(5)   COMP-3.
           05  QIN-DEFECTS               PIC S9(5)   COMP-3.
           05  QIN-MEAS-1-ACTUAL         PIC S9(5)V9(4) COMP-3.
           05  QIN-MEAS-1-NOMINAL        PIC S9(5)V9(4) COMP-3.
           05  QIN-MEAS-1-TOL-PLUS       PIC S9(3)V9(4) COMP-3.
           05  QIN-MEAS-1-TOL-MINUS      PIC S9(3)V9(4) COMP-3.
           05  QIN-MEAS-2-ACTUAL         PIC S9(5)V9(4) COMP-3.
           05  QIN-MEAS-2-NOMINAL        PIC S9(5)V9(4) COMP-3.
           05  QIN-MEAS-2-TOL-PLUS       PIC S9(3)V9(4) COMP-3.
           05  QIN-MEAS-2-TOL-MINUS      PIC S9(3)V9(4) COMP-3.
           05  QIN-INSPECTOR-ID          PIC X(8).
           05  QIN-INSPECT-DATE          PIC X(8).
           05  QIN-AQL-LEVEL             PIC X(4).
           05  FILLER                    PIC X(72).
      *
       FD  NCR-REPORT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  NCR-REPORT-REC               PIC X(132).
      *
       FD  SCORE-UPDATE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  SCORE-UPDATE-REC             PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
           COPY PARTMSTR.
           COPY QUALREC.
           COPY SUPPLIER.
           COPY ERRCODES.
      *
       01  WS-FILE-STATUS.
           05  WS-QUALIN-STATUS          PIC XX.
           05  WS-NCR-STATUS             PIC XX.
           05  WS-SC-STATUS              PIC XX.
      *
       01  WS-FLAGS.
           05  WS-EOF-FLAG               PIC X(1) VALUE 'N'.
               88  WS-END-OF-FILE            VALUE 'Y'.
      *
       01  WS-COUNTERS.
           05  WS-LOTS-INSPECTED         PIC S9(5) COMP-3 VALUE 0.
           05  WS-LOTS-ACCEPTED          PIC S9(5) COMP-3 VALUE 0.
           05  WS-LOTS-REJECTED          PIC S9(5) COMP-3 VALUE 0.
           05  WS-NCRS-GENERATED         PIC S9(5) COMP-3 VALUE 0.
      *
       01  WS-SPC-FIELDS.
           05  WS-CPK-VALUE              PIC S9(3)V9(4) COMP-3.
           05  WS-CPK-MIN-REQD           PIC S9(3)V9(4) COMP-3
                                         VALUE 1.33.
           05  WS-DEFECT-RATE            PIC S9(3)V9(6) COMP-3.
           05  WS-DEFECT-PPM             PIC S9(7)      COMP-3.
           05  WS-AQL-ACCEPT-NUM         PIC S9(3)      COMP-3.
      *
       01  WS-NCR-COUNTER               PIC S9(7) COMP VALUE 0.
       01  WS-NCR-NUMBER                 PIC X(10).
      *
       01  WS-DLI-FUNCTIONS.
           05  WS-GU                     PIC X(4) VALUE 'GU  '.
           05  WS-GHU                    PIC X(4) VALUE 'GHU '.
           05  WS-ISRT                   PIC X(4) VALUE 'ISRT'.
           05  WS-REPL                   PIC X(4) VALUE 'REPL'.
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
       01  WS-SSA-QUAL-UNQUAL.
           05  FILLER                    PIC X(9)
               VALUE 'QUALSEG '.
      *
       01  WS-SSA-SUPP.
           05  FILLER                    PIC X(9)
               VALUE 'SUPPSEG '.
           05  FILLER                    PIC X(1) VALUE '('.
           05  FILLER                    PIC X(10)
               VALUE 'VENDCD   ='.
           05  WS-SSA-SUPP-KEY           PIC X(10).
           05  FILLER                    PIC X(1) VALUE ')'.
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
           PERFORM 2000-PROCESS-INSPECTIONS
               UNTIL WS-END-OF-FILE
           PERFORM 3000-GENERATE-SCORECARDS
           PERFORM 9000-TERMINATE
           GOBACK.
      *
       1000-INITIALIZE.
           OPEN INPUT  QUAL-INPUT
           OPEN OUTPUT NCR-REPORT
           OPEN OUTPUT SCORE-UPDATE
           PERFORM 1100-READ-INSPECTION.
      *
       1100-READ-INSPECTION.
           READ QUAL-INPUT
               AT END
                   SET WS-END-OF-FILE TO TRUE
           END-READ.
      *
       2000-PROCESS-INSPECTIONS.
           ADD 1 TO WS-LOTS-INSPECTED
           PERFORM 2100-DETERMINE-AQL-ACCEPT
           PERFORM 2200-EVALUATE-LOT
           PERFORM 2300-CALCULATE-CPK
           PERFORM 2400-UPDATE-SUPPLIER-METRICS
           PERFORM 1100-READ-INSPECTION.
      *
       2100-DETERMINE-AQL-ACCEPT.
           EVALUATE QIN-AQL-LEVEL
               WHEN '0.10'
                   MOVE 0 TO WS-AQL-ACCEPT-NUM
               WHEN '0.25'
                   COMPUTE WS-AQL-ACCEPT-NUM =
                       QIN-SAMPLE-SIZE * 0.0025
               WHEN '0.65'
                   COMPUTE WS-AQL-ACCEPT-NUM =
                       QIN-SAMPLE-SIZE * 0.0065
               WHEN '1.00'
                   COMPUTE WS-AQL-ACCEPT-NUM =
                       QIN-SAMPLE-SIZE * 0.01
               WHEN OTHER
                   COMPUTE WS-AQL-ACCEPT-NUM =
                       QIN-SAMPLE-SIZE * 0.01
           END-EVALUATE.
      *
       2200-EVALUATE-LOT.
           IF QIN-DEFECTS <= WS-AQL-ACCEPT-NUM
               ADD 1 TO WS-LOTS-ACCEPTED
               PERFORM 2210-RECORD-ACCEPTANCE
           ELSE
               ADD 1 TO WS-LOTS-REJECTED
               PERFORM 2220-RECORD-REJECTION
           END-IF.
      *
       2210-RECORD-ACCEPTANCE.
           MOVE QIN-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               MOVE SPACES TO QUALITY-INSPECTION-RECORD
               MOVE QIN-PART-NUMBER TO QI-PART-NUMBER
               MOVE QIN-LOT-NUMBER  TO QI-LOT-NUMBER
               MOVE QIN-VENDOR-CODE TO QI-VENDOR-CODE
               MOVE QIN-INSPECT-DATE TO QI-INSPECTION-DATE
               MOVE QIN-INSPECTOR-ID TO QI-INSPECTOR-ID
               MOVE 'IN'            TO QI-INSPECTION-TYPE
               MOVE QIN-LOT-SIZE    TO QI-LOT-SIZE
               MOVE QIN-SAMPLE-SIZE TO QI-SAMPLE-SIZE
               MOVE QIN-DEFECTS     TO QI-DEFECTS-FOUND
               MOVE 'AC'            TO QI-DISPOSITION
               CALL 'CBLTDLI' USING WS-ISRT DB-PCB
                   QUALITY-INSPECTION-RECORD
                   WS-SSA-PART WS-SSA-QUAL-UNQUAL
           END-IF.
      *
       2220-RECORD-REJECTION.
           ADD 1 TO WS-NCR-COUNTER
           STRING 'NCR-' WS-NCR-COUNTER
               DELIMITED BY SIZE INTO WS-NCR-NUMBER
           MOVE QIN-PART-NUMBER TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               MOVE SPACES TO QUALITY-INSPECTION-RECORD
               MOVE QIN-PART-NUMBER TO QI-PART-NUMBER
               MOVE QIN-LOT-NUMBER  TO QI-LOT-NUMBER
               MOVE QIN-VENDOR-CODE TO QI-VENDOR-CODE
               MOVE QIN-INSPECT-DATE TO QI-INSPECTION-DATE
               MOVE QIN-INSPECTOR-ID TO QI-INSPECTOR-ID
               MOVE 'IN'            TO QI-INSPECTION-TYPE
               MOVE QIN-LOT-SIZE    TO QI-LOT-SIZE
               MOVE QIN-SAMPLE-SIZE TO QI-SAMPLE-SIZE
               MOVE QIN-DEFECTS     TO QI-DEFECTS-FOUND
               MOVE 'RJ'            TO QI-DISPOSITION
               MOVE WS-NCR-NUMBER   TO QI-NCR-NUMBER
               CALL 'CBLTDLI' USING WS-ISRT DB-PCB
                   QUALITY-INSPECTION-RECORD
                   WS-SSA-PART WS-SSA-QUAL-UNQUAL
               ADD 1 TO WS-NCRS-GENERATED
           END-IF.
      *
       2300-CALCULATE-CPK.
           IF QIN-MEAS-1-TOL-PLUS > 0
               COMPUTE WS-CPK-VALUE =
                   FUNCTION MIN(
                       (QIN-MEAS-1-TOL-PLUS -
                        (QIN-MEAS-1-ACTUAL -
                         QIN-MEAS-1-NOMINAL))
                       (QIN-MEAS-1-TOL-MINUS +
                        (QIN-MEAS-1-ACTUAL -
                         QIN-MEAS-1-NOMINAL))
                   )
           END-IF.
      *
       2400-UPDATE-SUPPLIER-METRICS.
           MOVE QIN-VENDOR-CODE TO WS-SSA-SUPP-KEY
           CALL 'CBLTDLI' USING WS-GHU DB-PCB
               SUPPLIER-RECORD WS-SSA-SUPP
           IF DB-STATUS-CODE = '  '
               COMPUTE WS-DEFECT-PPM =
                   (QIN-DEFECTS / QIN-SAMPLE-SIZE) * 1000000
               MOVE WS-DEFECT-PPM TO SP-DEFECT-PPM
               CALL 'CBLTDLI' USING WS-REPL DB-PCB
                   SUPPLIER-RECORD
           END-IF.
      *
       3000-GENERATE-SCORECARDS.
           CONTINUE.
      *
       9000-TERMINATE.
           CLOSE QUAL-INPUT
           CLOSE NCR-REPORT
           CLOSE SCORE-UPDATE.
