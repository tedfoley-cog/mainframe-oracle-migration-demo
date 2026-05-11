# Implementation Plan — Mainframe-to-Oracle Migration Demo

## 1. What the Demo Proves

A large automotive manufacturer runs critical manufacturing systems on IBM mainframes — parts inventory, bill of materials (BOM) explosion, supplier EDI processing, quality control, and warranty claims. These COBOL/IMS/DB2 systems are stable but increasingly expensive to maintain as COBOL expertise retires. This demo shows how Devin can analyze the entire legacy estate, map every dependency and data flow, and generate Oracle Database migration artifacts (PL/SQL packages, DDL schemas, SQL\*Loader control files, Oracle Scheduler jobs) — producing a complete, traceable migration plan with an interactive dashboard.

## 2. What Devin Does Live

Devin analyzes the mainframe codebase end-to-end — parsing COBOL programs, tracing copybook data flows, mapping IMS database hierarchies, reverse-engineering JCL job streams — then generates Oracle equivalents and an interactive migration dashboard showing program-by-program status, risk assessment, and data lineage.

## 3. Stack and Rationale

| Component | Technology | Source / Rationale |
|---|---|---|
| Legacy programs | COBOL-85, column-based format | IBM COBOL Language Reference; matches `cobol-ims-demo` conventions |
| Legacy database | IMS DL/I with DBD/PSB | IBM IMS documentation; hierarchical segments with SSAs |
| Legacy batch control | JCL (Job Control Language) | IBM z/OS JCL Reference; realistic EXEC PGM, DD statements |
| Legacy relational DB | DB2 for z/OS DDL | IBM DB2 SQL Reference; CREATE TABLE with CCSID, COMPRESS |
| Target database | Oracle Database 23ai | Oracle SQL Reference; PL/SQL packages, SQL\*Loader CTL |
| Dashboard | Vanilla HTML + CSS + JS | No build step; opens locally; consistent with prior demos |
| CI | GitHub Actions | YAML lint + COBOL column checks; consistent with prior demos |

## 4. Repo Layout

```
mainframe-oracle-migration-demo/
├── README.md                              # Project overview + flowchart + case studies
├── DEMO_NOTES.md                          # 5–8 bullet presenter cheat sheet
├── docs/
│   ├── IMPLEMENTATION_PLAN.md             # This file
│   ├── flowchart.html                     # Interactive demo flow diagram
│   └── flowchart.png                      # Rasterized fallback
├── .github/workflows/ci.yml              # Lint + structure validation
│
├── mainframe_source/                      # ── Legacy "before" state ──
│   ├── copybooks/
│   │   ├── PARTMSTR.cpy                   # Part master record layout
│   │   ├── BOMREC.cpy                     # Bill of Materials record
│   │   ├── SUPPLIER.cpy                   # Supplier/vendor record
│   │   ├── QUALREC.cpy                    # Quality inspection record
│   │   └── ERRCODES.cpy                   # Shared error code definitions
│   ├── programs/
│   │   ├── PARTINV.cbl                    # Parts inventory batch processing
│   │   ├── BOMEXPL.cbl                    # BOM explosion and costed rollup
│   │   ├── SUPPEDI.cbl                    # Supplier EDI 850/856 processing
│   │   ├── QUALCTL.cbl                    # Quality control inspection batch
│   │   └── WARRCLS.cbl                    # Warranty claims settlement
│   ├── jcl/
│   │   ├── PARTJOB.jcl                    # Parts inventory batch JCL
│   │   ├── BOMJOB.jcl                     # BOM processing JCL
│   │   └── NIGHTRUN.jcl                   # Nightly batch orchestrator
│   ├── dbd/
│   │   └── MFGDB.dbd                      # IMS database descriptor
│   ├── psb/
│   │   └── MFGPSB.psb                     # Program specification block
│   └── db2/
│       └── MFGSCHEMA.sql                  # DB2 table definitions
│
├── oracle_target/                         # ── Empty scaffolding ──
│   ├── schema/
│   │   └── .gitkeep                       # Devin generates Oracle DDL here
│   ├── packages/
│   │   └── .gitkeep                       # Devin generates PL/SQL here
│   ├── loader/
│   │   └── .gitkeep                       # Devin generates SQL*Loader CTL here
│   └── scheduler/
│       └── .gitkeep                       # Devin generates Oracle Scheduler here
│
└── dashboard/
    ├── index.html                         # Migration progress dashboard
    └── migration_state.json               # Initial state data (pre-migration)
```

**File count**: 22 source files + 4 `.gitkeep` placeholders = 26 total

## 5. Flowchart Outline

**Nodes** (top to bottom):
1. REPO → Legacy mainframe codebase
2. PROMPT → Prompt Devin with migration task
3. ANALYZE → Parse COBOL + trace copybooks
4. MAP_IMS → Map IMS DB hierarchy
5. MAP_JCL → Reverse-engineer JCL job streams
6. MAP_DB2 → Analyze DB2 schema
7. GEN_DDL → Generate Oracle DDL
8. GEN_PLSQL → Generate PL/SQL packages
9. GEN_LOADER → Generate SQL*Loader CTL files
10. GEN_SCHED → Generate Oracle Scheduler jobs
11. DASHBOARD → Produce migration dashboard
12. PR → Open PR with all artifacts

**Edges**: Linear flow with a parallel subgraph for the four "Generate" steps.

## 6. Runtime Plan

**"Appears runnable" via dashboard.** The real Oracle Database and mainframe runtime are unreachable from a demo VM. The dashboard (`dashboard/index.html`) loads `migration_state.json` to show migration progress, risk heatmap, and data lineage. During the live demo, Devin updates `migration_state.json` as it generates artifacts, and the dashboard reflects real-time progress.

**Commands**:
- View dashboard: open `dashboard/index.html` in browser
- View flowchart: open `docs/flowchart.html` in browser

## 7. CI Plan

Single workflow (`.github/workflows/ci.yml`):
- Checkout repo
- Validate COBOL column formatting (cols 7–72 for code, col 7 for comments)
- Validate JCL syntax basics (// prefix, EXEC, DD)
- Validate DB2 SQL well-formedness
- Check repo structure (required directories exist)
- Check dashboard HTML loads without errors

## 8. Risks and Unknowns

- **Oracle SQL\*Loader CTL syntax**: confirmed from Oracle 23ai documentation. CTL files use `LOAD DATA`, `INFILE`, `INTO TABLE`, `FIELDS TERMINATED BY` directives.
- **IMS DBD/PSB syntax**: confirmed from IBM IMS documentation. DBD uses `DBD NAME=`, `DATASET`, `SEGM`, `FIELD` macros. PSB uses `PCB TYPE=DB`, `SENSEG`.
- **JCL syntax**: confirmed from IBM z/OS JCL Reference. `//jobname JOB`, `//stepname EXEC PGM=`, `//ddname DD` format.
- **DB2 DDL**: standard SQL with DB2 extensions (`CCSID`, `COMPRESS YES`, `IN database.tablespace`).
- **No live Oracle or mainframe**: dashboard uses canned JSON data. Called out in README and PR description.
