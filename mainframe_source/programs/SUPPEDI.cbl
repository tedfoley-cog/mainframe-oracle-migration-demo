       IDENTIFICATION DIVISION.
       PROGRAM-ID. SUPPEDI.
      *================================================================*
      * SUPPEDI - SUPPLIER EDI DOCUMENT PROCESSING                    *
      *                                                                *
      * BATCH PROGRAM THAT PROCESSES INBOUND EDI DOCUMENTS FROM       *
      * SUPPLIERS. HANDLES ASN (ADVANCE SHIP NOTICE - EDI 856)        *
      * DOCUMENTS TO UPDATE EXPECTED RECEIPTS AND TRIGGER QUALITY     *
      * INSPECTION SCHEDULING.                                         *
      *                                                                *
      * ALSO GENERATES OUTBOUND PURCHASE ORDER (EDI 850) DOCUMENTS    *
      * FOR PARTS THAT HAVE FALLEN BELOW REORDER POINTS.              *
      *                                                                *
      * EDI STANDARDS: ANSI X12 VERSION 4010                           *
      *                                                                *
      * INPUT:  INBOUND EDI FILE (EDIIN DD)                            *
      * OUTPUT: OUTBOUND EDI FILE (EDIOUT DD)                          *
      *         EDI PROCESSING LOG (EDILOG DD)                         *
      *                                                                *
      * IMS: GHU/REPL ON PARTSEG AND SUPPSEG VIA MFGDB               *
      *================================================================*
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EDI-INBOUND  ASSIGN TO EDIIN
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-EDIIN-STATUS.
           SELECT EDI-OUTBOUND ASSIGN TO EDIOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-EDIOUT-STATUS.
           SELECT EDI-LOG      ASSIGN TO EDILOG
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-EDILOG-STATUS.
      *
       DATA DIVISION.
       FILE SECTION.
      *
       FD  EDI-INBOUND
           RECORDING MODE IS V
           RECORD CONTAINS 10 TO 1024 CHARACTERS.
       01  EDI-IN-RECORD                 PIC X(1024).
      *
       FD  EDI-OUTBOUND
           RECORDING MODE IS V
           RECORD CONTAINS 10 TO 1024 CHARACTERS.
       01  EDI-OUT-RECORD                PIC X(1024).
      *
       FD  EDI-LOG
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 132 CHARACTERS.
       01  EDI-LOG-RECORD                PIC X(132).
      *
       WORKING-STORAGE SECTION.
      *
           COPY PARTMSTR.
           COPY SUPPLIER.
           COPY ERRCODES.
      *
       01  WS-FILE-STATUS.
           05  WS-EDIIN-STATUS           PIC XX.
           05  WS-EDIOUT-STATUS          PIC XX.
           05  WS-EDILOG-STATUS          PIC XX.
      *
       01  WS-FLAGS.
           05  WS-EOF-FLAG               PIC X(1) VALUE 'N'.
               88  WS-END-OF-FILE            VALUE 'Y'.
           05  WS-IN-TRANSACTION         PIC X(1) VALUE 'N'.
               88  WS-TRAN-ACTIVE            VALUE 'Y'.
      *
       01  WS-EDI-FIELDS.
           05  WS-SEGMENT-ID             PIC X(3).
           05  WS-ELEMENT-SEP            PIC X(1) VALUE '*'.
           05  WS-SEGMENT-TERM           PIC X(1) VALUE '~'.
      *
       01  WS-856-DATA.
           05  WS-856-SHIPMENT-ID        PIC X(20).
           05  WS-856-SHIP-DATE          PIC X(8).
           05  WS-856-CARRIER            PIC X(4).
           05  WS-856-TRACKING           PIC X(30).
           05  WS-856-ITEMS OCCURS 50 TIMES.
               10  WS-856-PART-NUM       PIC X(15).
               10  WS-856-QTY-SHIPPED    PIC S9(7)   COMP-3.
               10  WS-856-PO-NUMBER      PIC X(12).
           05  WS-856-ITEM-COUNT         PIC S9(3) COMP VALUE 0.
      *
       01  WS-850-DATA.
           05  WS-850-PO-NUMBER          PIC X(12).
           05  WS-850-VENDOR             PIC X(10).
           05  WS-850-ORDER-DATE         PIC X(8).
           05  WS-850-ITEMS OCCURS 20 TIMES.
               10  WS-850-PART-NUM       PIC X(15).
               10  WS-850-QTY-ORDERED    PIC S9(7)   COMP-3.
               10  WS-850-UNIT-PRICE     PIC S9(7)V99 COMP-3.
               10  WS-850-NEED-DATE      PIC X(8).
           05  WS-850-ITEM-COUNT         PIC S9(3) COMP VALUE 0.
      *
       01  WS-COUNTERS.
           05  WS-856-PROCESSED          PIC S9(5) COMP-3 VALUE 0.
           05  WS-850-GENERATED          PIC S9(5) COMP-3 VALUE 0.
           05  WS-ERRORS                 PIC S9(5) COMP-3 VALUE 0.
      *
       01  WS-DLI-FUNCTIONS.
           05  WS-GU                     PIC X(4) VALUE 'GU  '.
           05  WS-GHU                    PIC X(4) VALUE 'GHU '.
           05  WS-GNP                    PIC X(4) VALUE 'GNP '.
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
       01  WS-SSA-SUPP.
           05  FILLER                    PIC X(9)
               VALUE 'SUPPSEG '.
           05  FILLER                    PIC X(1) VALUE '('.
           05  FILLER                    PIC X(10)
               VALUE 'VENDCD   ='.
           05  WS-SSA-SUPP-KEY           PIC X(10).
           05  FILLER                    PIC X(1) VALUE ')'.
      *
       01  WS-PO-COUNTER                PIC S9(7) COMP VALUE 0.
      *
       LINKAGE SECTION.
      *
       01  IO-PCB.
           05  IO-LTERM-NAME            PIC X(8).
           05  IO-RESERVE               PIC XX.
           05  IO-STATUS-CODE           PIC XX.
      *
       01  DB-PCB-PART.
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
       01  DB-PCB-SUPP.
           05  DBS-DBD-NAME             PIC X(8).
           05  DBS-SEG-LEVEL            PIC XX.
           05  DBS-STATUS-CODE          PIC XX.
           05  DBS-PROC-OPTIONS         PIC X(4).
           05  DBS-RESERVE-DLI          PIC S9(5) COMP.
           05  DBS-SEG-NAME             PIC X(8).
           05  DBS-LENGTH-FB-KEY        PIC S9(5) COMP.
           05  DBS-NUM-SENS-SEGS        PIC S9(5) COMP.
           05  DBS-KEY-FB-AREA          PIC X(30).
      *
       PROCEDURE DIVISION USING IO-PCB DB-PCB-PART DB-PCB-SUPP.
      *
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-INBOUND
               UNTIL WS-END-OF-FILE
           PERFORM 3000-GENERATE-REORDERS
           PERFORM 9000-TERMINATE
           GOBACK.
      *
       1000-INITIALIZE.
           OPEN INPUT  EDI-INBOUND
           OPEN OUTPUT EDI-OUTBOUND
           OPEN OUTPUT EDI-LOG
           PERFORM 1100-READ-EDI-RECORD.
      *
       1100-READ-EDI-RECORD.
           READ EDI-INBOUND
               AT END
                   SET WS-END-OF-FILE TO TRUE
           END-READ.
      *
       2000-PROCESS-INBOUND.
           MOVE EDI-IN-RECORD(1:3) TO WS-SEGMENT-ID
           EVALUATE WS-SEGMENT-ID
               WHEN 'ISA'
                   PERFORM 2100-PROCESS-ISA
               WHEN 'GS '
                   CONTINUE
               WHEN 'ST '
                   PERFORM 2200-PROCESS-ST
               WHEN 'BSN'
                   PERFORM 2300-PROCESS-BSN
               WHEN 'HL '
                   PERFORM 2400-PROCESS-HL
               WHEN 'SN1'
                   PERFORM 2500-PROCESS-SN1
               WHEN 'SE '
                   PERFORM 2600-PROCESS-SE
               WHEN 'GE '
                   CONTINUE
               WHEN 'IEA'
                   CONTINUE
               WHEN OTHER
                   CONTINUE
           END-EVALUATE
           PERFORM 1100-READ-EDI-RECORD.
      *
       2100-PROCESS-ISA.
           CONTINUE.
      *
       2200-PROCESS-ST.
           SET WS-TRAN-ACTIVE TO TRUE
           MOVE 0 TO WS-856-ITEM-COUNT.
      *
       2300-PROCESS-BSN.
           MOVE EDI-IN-RECORD(5:20) TO WS-856-SHIPMENT-ID
           MOVE EDI-IN-RECORD(26:8) TO WS-856-SHIP-DATE.
      *
       2400-PROCESS-HL.
           CONTINUE.
      *
       2500-PROCESS-SN1.
           ADD 1 TO WS-856-ITEM-COUNT
           IF WS-856-ITEM-COUNT <= 50
               MOVE EDI-IN-RECORD(5:15)
                   TO WS-856-PART-NUM(WS-856-ITEM-COUNT)
           END-IF.
      *
       2600-PROCESS-SE.
           PERFORM 2700-UPDATE-INVENTORY
           ADD 1 TO WS-856-PROCESSED
           MOVE 'N' TO WS-IN-TRANSACTION.
      *
       2700-UPDATE-INVENTORY.
           PERFORM VARYING WS-856-ITEM-COUNT
               FROM 1 BY 1
               UNTIL WS-856-ITEM-COUNT > 50
               OR WS-856-PART-NUM(WS-856-ITEM-COUNT) = SPACES
               MOVE WS-856-PART-NUM(WS-856-ITEM-COUNT)
                   TO WS-SSA-PART-KEY
               CALL 'CBLTDLI' USING WS-GHU DB-PCB-PART
                   PART-MASTER-RECORD WS-SSA-PART
               IF DB-STATUS-CODE = '  '
                   ADD WS-856-QTY-SHIPPED(WS-856-ITEM-COUNT)
                       TO PM-QTY-ON-HAND
                   CALL 'CBLTDLI' USING WS-REPL DB-PCB-PART
                       PART-MASTER-RECORD
               END-IF
           END-PERFORM.
      *
       3000-GENERATE-REORDERS.
           CONTINUE.
      *
       9000-TERMINATE.
           CLOSE EDI-INBOUND
           CLOSE EDI-OUTBOUND
           CLOSE EDI-LOG.
