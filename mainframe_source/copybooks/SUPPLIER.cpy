      *================================================================*
      * SUPPLIER - SUPPLIER/VENDOR RECORD LAYOUT                      *
      *                                                                *
      * SHARED COPYBOOK FOR SUPPLIER EDI PROCESSING AND PROCUREMENT.  *
      * TRACKS VENDOR MASTER DATA, PERFORMANCE METRICS, AND EDI       *
      * TRADING PARTNER CONFIGURATION.                                 *
      *                                                                *
      * IMS SEGMENT: SUPPSEG (ROOT SEGMENT IN MFGDB)                  *
      * SEGMENT LENGTH: 320 BYTES                                      *
      *================================================================*
      *
       01  SUPPLIER-RECORD.
           05  SP-VENDOR-CODE            PIC X(10).
           05  SP-VENDOR-NAME            PIC X(40).
           05  SP-ADDRESS.
               10  SP-ADDR-LINE-1        PIC X(35).
               10  SP-ADDR-LINE-2        PIC X(35).
               10  SP-CITY               PIC X(25).
               10  SP-STATE              PIC X(2).
               10  SP-ZIP-CODE           PIC X(10).
               10  SP-COUNTRY-CODE       PIC X(3).
           05  SP-CONTACT-INFO.
               10  SP-CONTACT-NAME       PIC X(30).
               10  SP-PHONE              PIC X(15).
               10  SP-EMAIL              PIC X(40).
           05  SP-EDI-CONFIG.
               10  SP-EDI-PARTNER-ID     PIC X(15).
               10  SP-EDI-QUALIFIER      PIC X(2).
                   88  SP-EDI-DUNS           VALUE '01'.
                   88  SP-EDI-MUTUALLY       VALUE 'ZZ'.
               10  SP-EDI-CAPABILITY     PIC X(4).
                   88  SP-CAN-850            VALUE '0850'.
                   88  SP-CAN-856            VALUE '0856'.
                   88  SP-CAN-BOTH           VALUE '0ALL'.
           05  SP-PERFORMANCE.
               10  SP-ON-TIME-PCT        PIC S9(3)V99 COMP-3.
               10  SP-QUALITY-RATING     PIC S9(1)V99 COMP-3.
               10  SP-DEFECT-PPM         PIC S9(7)   COMP-3.
               10  SP-AVG-LEAD-DAYS      PIC S9(3)   COMP-3.
           05  SP-FINANCIAL.
               10  SP-PAYMENT-TERMS      PIC X(6).
               10  SP-CURRENCY-CODE      PIC X(3).
               10  SP-YTD-PURCHASES      PIC S9(11)V99 COMP-3.
           05  SP-STATUS                 PIC X(1).
               88  SP-ACTIVE                 VALUE 'A'.
               88  SP-PROBATION              VALUE 'P'.
               88  SP-SUSPENDED              VALUE 'S'.
               88  SP-DISQUALIFIED           VALUE 'D'.
           05  SP-LAST-EVAL-DATE         PIC X(8).
           05  FILLER                    PIC X(11).
