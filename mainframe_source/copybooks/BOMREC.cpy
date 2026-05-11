      *================================================================*
      * BOMREC - BILL OF MATERIALS RECORD LAYOUT                      *
      *                                                                *
      * SHARED COPYBOOK FOR BOM PROCESSING. EACH RECORD REPRESENTS    *
      * ONE PARENT-CHILD RELATIONSHIP IN THE PRODUCT STRUCTURE.        *
      *                                                                *
      * IMS SEGMENT: BOMSEG (CHILD OF PARTSEG IN MFGDB)               *
      * SEGMENT LENGTH: 128 BYTES                                      *
      *================================================================*
      *
       01  BOM-RECORD.
           05  BM-PARENT-PART            PIC X(15).
           05  BM-COMPONENT-PART         PIC X(15).
           05  BM-QUANTITY-PER           PIC S9(5)V9(4) COMP-3.
           05  BM-UNIT-OF-MEASURE        PIC X(3).
           05  BM-FIND-NUMBER            PIC X(6).
           05  BM-REFERENCE-DESIGNATOR   PIC X(10).
           05  BM-BOM-LEVEL              PIC S9(2)   COMP-3.
           05  BM-EFFECTIVITY.
               10  BM-EFF-START-DATE     PIC X(8).
               10  BM-EFF-END-DATE       PIC X(8).
           05  BM-ENGINEERING-CHANGE     PIC X(12).
           05  BM-ITEM-TYPE             PIC X(1).
               88  BM-STANDARD              VALUE 'S'.
               88  BM-OPTIONAL              VALUE 'O'.
               88  BM-ALTERNATE             VALUE 'A'.
           05  BM-SCRAP-FACTOR           PIC S9(1)V9(4) COMP-3.
           05  BM-LEAD-TIME-OFFSET       PIC S9(3)   COMP-3.
           05  BM-OPERATION-SEQ          PIC S9(4)   COMP-3.
           05  FILLER                    PIC X(30).
