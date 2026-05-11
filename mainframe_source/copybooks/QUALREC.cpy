      *================================================================*
      * QUALREC - QUALITY INSPECTION RECORD LAYOUT                    *
      *                                                                *
      * SHARED COPYBOOK FOR QUALITY CONTROL PROGRAMS. EACH RECORD     *
      * REPRESENTS ONE INSPECTION EVENT AGAINST A RECEIVED LOT.       *
      *                                                                *
      * IMS SEGMENT: QUALSEG (CHILD OF PARTSEG IN MFGDB)              *
      * SEGMENT LENGTH: 192 BYTES                                      *
      *================================================================*
      *
       01  QUALITY-INSPECTION-RECORD.
           05  QI-INSPECTION-ID          PIC X(12).
           05  QI-PART-NUMBER            PIC X(15).
           05  QI-LOT-NUMBER             PIC X(12).
           05  QI-VENDOR-CODE            PIC X(10).
           05  QI-RECEIPT-DATE           PIC X(8).
           05  QI-INSPECTION-DATE        PIC X(8).
           05  QI-INSPECTOR-ID           PIC X(8).
           05  QI-INSPECTION-TYPE        PIC X(2).
               88  QI-INCOMING               VALUE 'IN'.
               88  QI-IN-PROCESS             VALUE 'IP'.
               88  QI-FINAL                  VALUE 'FN'.
           05  QI-SAMPLE-DATA.
               10  QI-LOT-SIZE           PIC S9(7)   COMP-3.
               10  QI-SAMPLE-SIZE        PIC S9(5)   COMP-3.
               10  QI-DEFECTS-FOUND      PIC S9(5)   COMP-3.
               10  QI-AQL-LEVEL          PIC X(4).
           05  QI-MEASUREMENTS.
               10  QI-MEAS-1-NOMINAL     PIC S9(5)V9(4) COMP-3.
               10  QI-MEAS-1-ACTUAL      PIC S9(5)V9(4) COMP-3.
               10  QI-MEAS-1-TOL-PLUS    PIC S9(3)V9(4) COMP-3.
               10  QI-MEAS-1-TOL-MINUS   PIC S9(3)V9(4) COMP-3.
               10  QI-MEAS-2-NOMINAL     PIC S9(5)V9(4) COMP-3.
               10  QI-MEAS-2-ACTUAL      PIC S9(5)V9(4) COMP-3.
               10  QI-MEAS-2-TOL-PLUS    PIC S9(3)V9(4) COMP-3.
               10  QI-MEAS-2-TOL-MINUS   PIC S9(3)V9(4) COMP-3.
           05  QI-DISPOSITION            PIC X(2).
               88  QI-ACCEPT                 VALUE 'AC'.
               88  QI-REJECT                 VALUE 'RJ'.
               88  QI-CONDITIONAL            VALUE 'CN'.
               88  QI-REWORK                 VALUE 'RW'.
               88  QI-USE-AS-IS              VALUE 'UA'.
           05  QI-NCR-NUMBER             PIC X(10).
           05  QI-COMMENTS               PIC X(40).
           05  FILLER                    PIC X(11).
