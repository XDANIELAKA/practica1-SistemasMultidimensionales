\set ON_ERROR_STOP on

\i sql/00_create_schemas.sql

\i sql/01_ddl_alojamientos.sql
\i sql/02_ddl_reservas.sql
\i sql/03_ddl_operaciones.sql
\i sql/04_ddl_rrhh.sql
\i sql/05_ddl_finanzas.sql
\i sql/06_fk_interdepartamentales.sql

\i sql/07_dml_alojamientos.sql
\i sql/08_dml_reservas.sql
\i sql/09_dml_operaciones.sql
\i sql/10_dml_rrhh.sql
\i sql/11_dml_finanzas.sql

\i sql/12_ddl_olap_dimensiones.sql
\i sql/13_dml_olap_dimensiones.sql

\i sql/14_ddl_olap_hechos.sql
\i sql/15_etl_olap_hechos.sql

\i sql/16_ddl_olap_snowflake.sql
\i sql/17_etl_olap_snowflake.sql

\i sql/18_queries_benchmark_oltp.sql
\i sql/19_queries_benchmark_star.sql
\i sql/20_queries_benchmark_snow.sql
