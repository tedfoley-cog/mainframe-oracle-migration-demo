       IDENTIFICATION DIVISION.
       PROGRAM-ID. BOMEXPL.
      *================================================================*
      * BOMEXPL - BILL OF MATERIALS EXPLOSION                         *
      *                                                                *
      * BATCH PROGRAM THAT PERFORMS MULTI-LEVEL BOM EXPLOSION FOR A   *
      * GIVEN PARENT ASSEMBLY. WALKS THE IMS HIERARCHY TO RESOLVE     *
      * ALL COMPONENT PARTS DOWN TO RAW MATERIALS, CALCULATING        *
      * EXTENDED QUANTITIES AND COSTED ROLLUPS AT EACH LEVEL.         *
      *                                                                *
      * USED BY PRODUCTION PLANNING TO DETERMINE MATERIAL             *
      * REQUIREMENTS FOR A BUILD ORDER AND BY COST ACCOUNTING TO      *
      * CALCULATE STANDARD COSTS FOR FINISHED GOODS.                  *
      *                                                                *
      * INPUT:  BOM REQUEST FILE (BOMREQ DD) - PARENT PART NUMBERS    *
      * OUTPUT: BOM EXPLOSION REPORT (BOMRPT DD)                      *
      *         COSTED ROLLUP SUMMARY (COSTRPT DD)                    *
      *                                                                *
      * IMS: GU ON PARTSEG, GNP ON BOMSEG FOR CHILD RETRIEVAL        *
      * MAXIMUM BOM DEPTH: 15 LEVELS (PREVENTS INFINITE RECURSION)   *
      *================================================================*
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REQUEST-FILE ASSIGN TO BOMREQ
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-REQ-STATUS.
           SELECT BOM-REPORT  ASSIGN TO BOMRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-BOM-STATUS.
           SELECT COST-REPORT ASSIGN TO COSTRPT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-CST-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
      *
       FD  REQUEST-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS.
       01  REQUEST-RECORD.
           05  RQ-PARENT-PART            PIC X(15).
           05  RQ-BUILD-QTY              PIC S9(7) COMP-3.
           05  RQ-EFFECTIVE-DATE         PIC X(8).
           05  FILLER                    PIC X(53).
      *
       FD  BOM-REPORT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  BOM-REPORT-REC                PIC X(132).
      *
       FD  COST-REPORT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  COST-REPORT-REC               PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
           COPY PARTMSTR.
           COPY BOMREC.
           COPY ERRCODES.
      *
       01  WS-FILE-STATUS.
           05  WS-REQ-STATUS             PIC XX.
           05  WS-BOM-STATUS             PIC XX.
           05  WS-CST-STATUS             PIC XX.
      *
       01  WS-FLAGS.
           05  WS-EOF-FLAG               PIC X(1) VALUE 'N'.
               88  WS-END-OF-FILE            VALUE 'Y'.
           05  WS-CIRCULAR-FLAG          PIC X(1) VALUE 'N'.
               88  WS-CIRCULAR-FOUND         VALUE 'Y'.
      *
       01  WS-BOM-STACK.
           05  WS-MAX-LEVELS             PIC S9(2) COMP VALUE 15.
           05  WS-CURRENT-LEVEL          PIC S9(2) COMP VALUE 0.
           05  WS-LEVEL-ENTRY OCCURS 15 TIMES.
               10  WS-LVL-PART-NUM       PIC X(15).
               10  WS-LVL-QTY-PER        PIC S9(5)V9(4) COMP-3.
               10  WS-LVL-EXT-QTY        PIC S9(9)V9(4) COMP-3.
               10  WS-LVL-COST           PIC S9(9)V99   COMP-3.
      *
       01  WS-TOTALS.
           05  WS-TOTAL-MATERIAL-COST    PIC S9(11)V99 COMP-3
                                         VALUE 0.
           05  WS-TOTAL-COMPONENTS       PIC S9(7) COMP-3 VALUE 0.
           05  WS-ASSEMBLIES-PROCESSED   PIC S9(5) COMP-3 VALUE 0.
      *
       01  WS-DLI-FUNCTIONS.
           05  WS-GU                     PIC X(4) VALUE 'GU  '.
           05  WS-GNP                    PIC X(4) VALUE 'GNP '.
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
       01  WS-SSA-BOM-UNQUAL.
           05  FILLER                    PIC X(9)
               VALUE 'BOMSEG  '.
      *
       01  WS-RPT-DETAIL.
           05  WS-RPT-INDENT            PIC X(30) VALUE SPACES.
           05  WS-RPT-LVL               PIC Z9.
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-RPT-PART              PIC X(15).
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-RPT-DESC              PIC X(30).
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-RPT-QTY-PER           PIC Z(4)9.9(4)-.
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-RPT-EXT-QTY           PIC Z(8)9.9(4)-.
           05  FILLER                    PIC X(1)  VALUE SPACES.
           05  WS-RPT-EXT-COST          PIC Z(9)9.99-.
           05  FILLER                    PIC X(13) VALUE SPACES.
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
           PERFORM 2000-PROCESS-REQUESTS
               UNTIL WS-END-OF-FILE
           PERFORM 9000-TERMINATE
           GOBACK.
      *
       1000-INITIALIZE.
           OPEN INPUT  REQUEST-FILE
           OPEN OUTPUT BOM-REPORT
           OPEN OUTPUT COST-REPORT
           PERFORM 1100-READ-REQUEST.
      *
       1100-READ-REQUEST.
           READ REQUEST-FILE
               AT END
                   SET WS-END-OF-FILE TO TRUE
           END-READ.
      *
       2000-PROCESS-REQUESTS.
           MOVE 0 TO WS-CURRENT-LEVEL
           MOVE 0 TO WS-TOTAL-MATERIAL-COST
           MOVE 'N' TO WS-CIRCULAR-FLAG
           PERFORM 2100-EXPLODE-BOM
           ADD 1 TO WS-ASSEMBLIES-PROCESSED
           PERFORM 2500-WRITE-COST-SUMMARY
           PERFORM 1100-READ-REQUEST.
      *
       2100-EXPLODE-BOM.
           ADD 1 TO WS-CURRENT-LEVEL
           IF WS-CURRENT-LEVEL > WS-MAX-LEVELS
               MOVE ERR-BOM-MAX-LEVEL TO WS-ERR-CODE
               SUBTRACT 1 FROM WS-CURRENT-LEVEL
               EXIT PARAGRAPH
           END-IF
           MOVE RQ-PARENT-PART TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               PERFORM 2200-GET-CHILDREN
           END-IF
           SUBTRACT 1 FROM WS-CURRENT-LEVEL.
      *
       2200-GET-CHILDREN.
           CALL 'CBLTDLI' USING WS-GNP DB-PCB
               BOM-RECORD WS-SSA-BOM-UNQUAL
           PERFORM UNTIL DB-STATUS-CODE NOT = '  '
               PERFORM 2300-PROCESS-COMPONENT
               CALL 'CBLTDLI' USING WS-GNP DB-PCB
                   BOM-RECORD WS-SSA-BOM-UNQUAL
           END-PERFORM.
      *
       2300-PROCESS-COMPONENT.
           ADD 1 TO WS-TOTAL-COMPONENTS
           MOVE WS-CURRENT-LEVEL TO WS-RPT-LVL
           MOVE BM-COMPONENT-PART TO WS-RPT-PART
           MOVE BM-QUANTITY-PER TO WS-RPT-QTY-PER
           COMPUTE WS-LVL-EXT-QTY(WS-CURRENT-LEVEL) =
               BM-QUANTITY-PER * RQ-BUILD-QTY *
               (1 + BM-SCRAP-FACTOR)
           MOVE WS-LVL-EXT-QTY(WS-CURRENT-LEVEL)
               TO WS-RPT-EXT-QTY
           MOVE BM-COMPONENT-PART TO WS-SSA-PART-KEY
           CALL 'CBLTDLI' USING WS-GU DB-PCB
               PART-MASTER-RECORD WS-SSA-PART
           IF DB-STATUS-CODE = '  '
               MOVE PM-DESCRIPTION TO WS-RPT-DESC
               COMPUTE WS-LVL-COST(WS-CURRENT-LEVEL) =
                   WS-LVL-EXT-QTY(WS-CURRENT-LEVEL) *
                   PM-STANDARD-COST
               MOVE WS-LVL-COST(WS-CURRENT-LEVEL)
                   TO WS-RPT-EXT-COST
               ADD WS-LVL-COST(WS-CURRENT-LEVEL)
                   TO WS-TOTAL-MATERIAL-COST
               WRITE BOM-REPORT-REC FROM WS-RPT-DETAIL
               IF NOT PM-RAW-MATERIAL
                   MOVE BM-COMPONENT-PART TO RQ-PARENT-PART
                   PERFORM 2100-EXPLODE-BOM
               END-IF
           END-IF.
      *
       2500-WRITE-COST-SUMMARY.
           CONTINUE.
      *
       9000-TERMINATE.
           CLOSE REQUEST-FILE
           CLOSE BOM-REPORT
           CLOSE COST-REPORT.
