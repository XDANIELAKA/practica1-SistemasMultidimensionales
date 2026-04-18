# Práctica 1 - Sistemas Multidimensionales

---

## Royal Whisper Resorts

Este repositorio contiene el desarrollo de la Práctica 1 de la asignatura **Sistemas Multidimensionales** de la **Universidad de Granada**, centrada en el diseño completo de un sistema analítico que evoluciona desde varios sistemas **OLTP** hasta un **Data Warehouse** en arquitectura **Star Schema** y una variante **Snowflake**.

El dominio elegido para la práctica es el sector turístico, concretamente una cadena hotelera ficticia llamada **Royal Whisper Resorts**.

---

## Objetivo

Los sistemas de información modernos generan grandes volúmenes de datos transaccionales que requieren ser transformados en conocimiento estratégico para la toma de decisiones. Los Data Warehouses (DW) y los sistemas multidimensionales proporcionan la arquitectura necesaria para consolidar, organizar y analizar datos históricos de múltiples fuentes, permitiendo a los analistas y directivos responder preguntas complejas de negocio mediante operaciones OLAP (Online Analytical Processing).

Esta práctica tiene como propósito aplicar el ciclo completo de diseño e implementación de un Data Warehouse, desde la identificación de fuentes transaccionales hasta la evaluación de rendimiento de consultas analíticas. Se hace énfasis en conceptos clave como dimensiones, hechos, granularidad, jerarquías, Bus Matrix y Slowly Changing Dimensions (SCD).

---

## Contenido del proyecto

El trabajo se ha estructurado en varios hitos.

En el **Hito 1** se realiza el análisis del dominio, la identificación de preguntas de negocio, la definición de hechos y dimensiones y el diseño conceptual OLAP.

En el **Hito 2** se diseña el sistema **OLTP**, dividido en varios departamentos, con sus diagramas E/R, tablas normalizadas, claves primarias, claves foráneas, restricciones e inserciones de datos.

En el **Hito 3** se construye el **Data Warehouse** en dos variantes. Por un lado, un modelo en **estrella** dentro del esquema `olap`. Por otro lado, una variante en **copo de nieve** dentro del esquema `olap_snow`.

En el **Hito 4** se lleva a cabo el **benchmarking y la evaluación**, comparando consultas analíticas ejecutadas sobre los modelos **OLTP**, **Star** y **Snowflake** mediante un script en Python.

---

## Estructura del repositorio

```text
.
├── README.md
├── memoriaP1_SM.pdf
├── 21_benchmark.py
├── sql/
│   ├── 00_create_schemas.sql
│   ├── 01_ddl_alojamientos.sql
│   ├── 02_ddl_reservas.sql
│   ├── 03_ddl_operaciones.sql
│   ├── 04_ddl_rrhh.sql
│   ├── 05_ddl_finanzas.sql
│   ├── 06_fk_interdepartamentales.sql
│   ├── 07_dml_alojamientos.sql
│   ├── 08_dml_reservas.sql
│   ├── 09_dml_operaciones.sql
│   ├── 10_dml_rrhh.sql
│   ├── 11_dml_finanzas.sql
│   ├── 12_ddl_olap_dimensiones.sql
│   ├── 13_dml_olap_dimensiones.sql
│   ├── 14_ddl_olap_hechos.sql
│   ├── 15_etl_olap_hechos.sql
│   ├── 16_ddl_olap_snowflake.sql
│   ├── 17_etl_olap_snowflake.sql
│   ├── 18_queries_benchmark_oltp.sql
│   ├── 19_queries_benchmark_star.sql
│   ├── 20_queries_benchmark_snow.sql
├── 99_full_build.sql
└── docs/
    ├── diagrams/
    └── images/
```

---

## Tecnologías

Para ejecutar el proyecto se ha utilizado:

- **PostgreSQL**
- **Python3**
- **psycopg2-binary** para el script de benchmarking
- Sistema operativo **Ubuntu**

---

## Ejecución scripts SQL

Se ha proporcionado un archivo **99_full_build.sql** que puede construir el proyeccto en el orden lógico del desarrollo.

Una vez haya terminado correctamente, se puede ejecutar el archivo **21_benchmark.py** para la medición de tiempos, generando los resultados en un CSV.
