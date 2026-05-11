      *================================================================*
      * ERRCODES - SHARED ERROR CODE DEFINITIONS                      *
      *                                                                *
      * STANDARD ERROR CODES AND MESSAGES USED ACROSS ALL PROGRAMS    *
      * IN THE MANUFACTURING SYSTEM.                                   *
      *================================================================*
      *
       01  ERR-CODE-TABLE.
           05  ERR-SUCCESS               PIC X(4)  VALUE '0000'.
           05  ERR-PART-NOT-FOUND        PIC X(4)  VALUE 'E001'.
           05  ERR-INVALID-QTY           PIC X(4)  VALUE 'E002'.
           05  ERR-INSUFFICIENT-STOCK    PIC X(4)  VALUE 'E003'.
           05  ERR-DUPLICATE-KEY         PIC X(4)  VALUE 'E004'.
           05  ERR-DB-ACCESS-FAIL        PIC X(4)  VALUE 'E005'.
           05  ERR-INVALID-DATE          PIC X(4)  VALUE 'E006'.
           05  ERR-VENDOR-NOT-FOUND      PIC X(4)  VALUE 'E007'.
           05  ERR-EDI-PARSE-FAIL        PIC X(4)  VALUE 'E008'.
           05  ERR-BOM-CIRCULAR          PIC X(4)  VALUE 'E009'.
           05  ERR-BOM-MAX-LEVEL         PIC X(4)  VALUE 'E010'.
           05  ERR-INSPECTION-FAIL       PIC X(4)  VALUE 'E011'.
           05  ERR-WARRANTY-EXPIRED      PIC X(4)  VALUE 'E012'.
           05  ERR-INVALID-CLAIM         PIC X(4)  VALUE 'E013'.
           05  ERR-SYSTEM-ERROR          PIC X(4)  VALUE 'E099'.
      *
       01  ERR-MESSAGE-TABLE.
           05  ERR-MSG-SUCCESS           PIC X(40)
               VALUE 'PROCESSING COMPLETED SUCCESSFULLY       '.
           05  ERR-MSG-PART-NOT-FOUND    PIC X(40)
               VALUE 'PART NUMBER NOT FOUND IN DATABASE        '.
           05  ERR-MSG-INVALID-QTY       PIC X(40)
               VALUE 'QUANTITY VALUE IS INVALID OR NEGATIVE    '.
           05  ERR-MSG-INSUFF-STOCK      PIC X(40)
               VALUE 'INSUFFICIENT STOCK FOR REQUESTED QTY     '.
           05  ERR-MSG-DUPLICATE         PIC X(40)
               VALUE 'DUPLICATE KEY - RECORD ALREADY EXISTS    '.
           05  ERR-MSG-DB-FAIL           PIC X(40)
               VALUE 'DATABASE ACCESS FAILURE - CHECK PCB      '.
           05  ERR-MSG-INVALID-DATE      PIC X(40)
               VALUE 'DATE FORMAT INVALID - USE YYYYMMDD       '.
           05  ERR-MSG-VENDOR-NF         PIC X(40)
               VALUE 'VENDOR CODE NOT FOUND IN SUPPLIER FILE   '.
           05  ERR-MSG-EDI-FAIL          PIC X(40)
               VALUE 'EDI DOCUMENT PARSING ERROR               '.
           05  ERR-MSG-BOM-CIRC          PIC X(40)
               VALUE 'CIRCULAR REFERENCE DETECTED IN BOM       '.
           05  ERR-MSG-BOM-MAX           PIC X(40)
               VALUE 'BOM EXCEEDS MAXIMUM NESTING LEVEL OF 15  '.
           05  ERR-MSG-INSP-FAIL         PIC X(40)
               VALUE 'INSPECTION CRITERIA NOT MET              '.
           05  ERR-MSG-WARR-EXP          PIC X(40)
               VALUE 'WARRANTY PERIOD HAS EXPIRED              '.
           05  ERR-MSG-INV-CLAIM         PIC X(40)
               VALUE 'CLAIM DATA INCOMPLETE OR INVALID         '.
           05  ERR-MSG-SYSTEM            PIC X(40)
               VALUE 'SYSTEM ERROR - CONTACT SUPPORT           '.
      *
       01  WS-ERROR-FIELDS.
           05  WS-ERR-CODE              PIC X(4).
           05  WS-ERR-MESSAGE           PIC X(40).
           05  WS-ERR-PROGRAM           PIC X(8).
           05  WS-ERR-PARAGRAPH         PIC X(30).
