      *================================================================*
      * PARTMSTR - PART MASTER RECORD LAYOUT                          *
      *                                                                *
      * SHARED COPYBOOK USED BY ALL PROGRAMS THAT ACCESS THE PARTS    *
      * INVENTORY SEGMENT OF THE MANUFACTURING DATABASE.               *
      *                                                                *
      * IMS SEGMENT: PARTSEG (ROOT SEGMENT IN MFGDB)                  *
      * SEGMENT LENGTH: 256 BYTES                                      *
      *================================================================*
      *
       01  PART-MASTER-RECORD.
           05  PM-PART-NUMBER            PIC X(15).
           05  PM-DESCRIPTION            PIC X(40).
           05  PM-PART-TYPE              PIC X(2).
               88  PM-RAW-MATERIAL           VALUE 'RM'.
               88  PM-PURCHASED              VALUE 'PU'.
               88  PM-MANUFACTURED           VALUE 'MF'.
               88  PM-SUBASSEMBLY            VALUE 'SA'.
           05  PM-UNIT-OF-MEASURE        PIC X(3).
               88  PM-UOM-EACH               VALUE 'EA '.
               88  PM-UOM-KILOGRAMS          VALUE 'KG '.
               88  PM-UOM-METERS             VALUE 'MTR'.
               88  PM-UOM-LITERS             VALUE 'LTR'.
           05  PM-COMMODITY-CODE         PIC X(10).
           05  PM-PLANT-CODE             PIC X(4).
           05  PM-WAREHOUSE-CODE         PIC X(4).
           05  PM-INVENTORY-DATA.
               10  PM-QTY-ON-HAND        PIC S9(9)   COMP-3.
               10  PM-QTY-ALLOCATED      PIC S9(9)   COMP-3.
               10  PM-QTY-ON-ORDER       PIC S9(9)   COMP-3.
               10  PM-REORDER-POINT      PIC S9(9)   COMP-3.
               10  PM-SAFETY-STOCK       PIC S9(9)   COMP-3.
           05  PM-COST-DATA.
               10  PM-STANDARD-COST      PIC S9(7)V99 COMP-3.
               10  PM-LAST-PURCHASE-COST PIC S9(7)V99 COMP-3.
               10  PM-WEIGHTED-AVG-COST  PIC S9(7)V99 COMP-3.
           05  PM-DATES.
               10  PM-CREATION-DATE      PIC X(8).
               10  PM-LAST-RECEIPT-DATE  PIC X(8).
               10  PM-LAST-ISSUE-DATE    PIC X(8).
           05  PM-STATUS                 PIC X(1).
               88  PM-ACTIVE                 VALUE 'A'.
               88  PM-OBSOLETE               VALUE 'O'.
               88  PM-HELD                   VALUE 'H'.
           05  PM-ABC-CLASS              PIC X(1).
               88  PM-CLASS-A                VALUE 'A'.
               88  PM-CLASS-B                VALUE 'B'.
               88  PM-CLASS-C                VALUE 'C'.
           05  PM-SUPPLIER-CODE          PIC X(10).
           05  PM-LEAD-TIME-DAYS         PIC S9(3)   COMP-3.
           05  FILLER                    PIC X(89).
