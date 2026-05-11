# Demo Cheat Sheet — Mainframe to Oracle Migration

## Setup (do this before joining the call)
- [ ] Open the repo in a browser tab: https://github.com/tedfoley-cog/mainframe-oracle-migration-demo
- [ ] Open `dashboard/index.html` in a second tab (shows 0% migration progress initially)
- [ ] Have a Devin session ready on this repo

## Demo Flow
1. Show the repo — walk through `mainframe_source/`: 5 COBOL programs, 5 copybooks, 3 JCL jobs, IMS DBD/PSB, DB2 schema. "This is a real automotive manufacturing mainframe — parts inventory, BOM explosion, supplier EDI, quality control, warranty claims. ~1,400 lines of COBOL, IMS hierarchical database, nightly batch orchestration via JCL."
2. Show the dashboard at 0% — point out the IMS-to-Oracle mapping table and program risk assessment. "This is what the migration team sees before Devin starts — every program catalogued with its complexity, risk level, and target Oracle package."
3. Prompt Devin: "Analyze the entire mainframe codebase — parse every COBOL program, trace all copybook data flows, map the IMS database hierarchy and JCL job dependencies, then generate the complete Oracle migration: DDL schemas, PL/SQL packages, SQL*Loader control files, and Oracle Scheduler jobs. Update the migration dashboard as you go."
4. While Devin works, narrate: it's parsing COBOL column-by-column, resolving COPY statements to shared data layouts, mapping IMS GHU/REPL calls to Oracle SELECT FOR UPDATE/UPDATE, converting COMP-3 packed decimals to Oracle NUMBER types, translating JCL COND codes to Oracle Scheduler chain dependencies. "A top 10 global auto OEM used this same approach to migrate a 25,000-line customs workflow — 73% cost reduction."
5. Open the generated Oracle artifacts and the updated dashboard — show the completed PL/SQL packages, the SQL*Loader CTL files, the Oracle Scheduler jobs. Refresh the dashboard to show migration progress. "Devin just did what would take a migration team weeks — and it can run hundreds of these in parallel across the full COBOL estate."
