# V90
V90 Design is a lightweight SQL-based analytics framework for practicing modern data ingestion and layered analytics processing. It uses a separate lake database for raw and source-oriented data, and a core database for harmonisation, business-rule enrichment, consumption views, automation, metadata, and advanced analytics artefacts.

The design follows a layered flow:

**Lake / Root → Hub / Stem → Mart / Branch → Consume / Leaf**

Raw source data is first ingested into V90_Lake. The core database then exposes lake data through viewpoints, loads it into harmonised hub entities, enriches it in mart tables using business rules, and publishes accessible analytical views for reporting, modelling, and advanced analytics. The framework also includes automation and utility components for ingestion control, split-merge processing, metadata discovery, logging, and repeatable execution.

**V90_Lake** is the practice lake database. It represents the Root / Lake layer where raw source data is ingested, stored, and prepared for later processing. It contains source-oriented schemas such as APP, MISC, and AAL. The lake supports full and partial ingestion patterns, source settings, and ingestion parameters.

**V90_Core** is the core analytics processing database. It represents the Stem / Hub, Branch / Mart, and Leaf / Consume layers. Data moves from lake viewpoints into harmonised hub entities, then into business-rule-enriched mart entities, and finally into consumption-friendly analytical views, reports, models, and advanced analytics artefacts.

**V90_Power BI Template** is the universal Power BI semantic model and reporting template for V90. It standardises how analytical data, attributes, metrics, calendars, security rules, and report-ready structures are organised so Power BI solutions remain consistent, governed, scalable, and easy for business users to consume.

The framework also includes automation, utility, service, and metadata components through schemas such as AUT, UTL, SVC, and VPL. These support ingestion control, dynamic query generation, logging, metadata search, split-merge processing, and repeatable pipeline execution. Your script includes examples of Hub and Mart load / refresh / update procedures, including cleansing, deduplication, business logic updates, and logging.
