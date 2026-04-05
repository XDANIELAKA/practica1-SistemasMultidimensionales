#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import csv
import os
import re
import statistics
import time
from pathlib import Path

import psycopg2


BASE_DIR = Path(__file__).resolve().parent
DEFAULT_SQL_DIR = BASE_DIR / "sql"


def cargar_consultas(ruta_sql: Path):
    texto = ruta_sql.read_text(encoding="utf-8")
    partes = re.split(r"(?m)^\\echo\s+'(.*?)'\s*$", texto)

    consultas = []
    for i in range(1, len(partes), 2):
        nombre = partes[i].strip()
        sql = partes[i + 1].strip()

        lineas = []
        for linea in sql.splitlines():
            if linea.strip().startswith("--"):
                continue
            lineas.append(linea)
        sql_limpio = "\n".join(lineas).strip()

        if sql_limpio.endswith(";"):
            sql_limpio = sql_limpio[:-1].strip()

        if sql_limpio:
            consultas.append((nombre, sql_limpio))

    if not consultas:
        bloques = [b.strip() for b in texto.split(";") if b.strip()]
        for idx, bloque in enumerate(bloques, start=1):
            lineas = []
            for linea in bloque.splitlines():
                if linea.strip().startswith("--"):
                    continue
                if linea.strip().startswith("\\"):
                    continue
                lineas.append(linea)
            sql_limpio = "\n".join(lineas).strip()
            if sql_limpio:
                consultas.append((f"Q{idx}", sql_limpio))

    return consultas


def medir(cur, query: str, repeticiones: int = 50):
    tiempos = []
    n_filas = None

    for _ in range(repeticiones):
        inicio = time.perf_counter()
        cur.execute(query)
        filas = cur.fetchall()
        fin = time.perf_counter()

        tiempos.append(fin - inicio)

        if n_filas is None:
            n_filas = len(filas)

    media = statistics.mean(tiempos)
    desv = statistics.stdev(tiempos) if len(tiempos) > 1 else 0.0

    return {
        "media_s": media,
        "desv_s": desv,
        "min_s": min(tiempos),
        "max_s": max(tiempos),
        "filas": n_filas,
    }


def main():
    parser = argparse.ArgumentParser(description="Benchmark OLTP vs Star vs Snowflake")
    parser.add_argument("--host", default=os.getenv("PGHOST", "localhost"))
    parser.add_argument("--port", type=int, default=int(os.getenv("PGPORT", "5432")))
    parser.add_argument("--database", default=os.getenv("PGDATABASE", "royal_whisper_sm"))
    parser.add_argument("--user", default=os.getenv("PGUSER", "postgres"))
    parser.add_argument("--password", default=os.getenv("PGPASSWORD", ""))
    parser.add_argument("--repeticiones", type=int, default=20)
    parser.add_argument("--sql-dir", default=str(DEFAULT_SQL_DIR))
    parser.add_argument("--out-csv", default="benchmark_resultados.csv")
    args = parser.parse_args()

    sql_dir = Path(args.sql_dir)

    archivos = {
        "OLTP": sql_dir / "18_queries_benchmark_oltp.sql",
        "STAR": sql_dir / "19_queries_benchmark_star.sql",
        "SNOW": sql_dir / "20_queries_benchmark_snow.sql",
    }

    for etiqueta, ruta in archivos.items():
        if not ruta.exists():
            raise FileNotFoundError(f"No existe el archivo para {etiqueta}: {ruta}")

    conn = psycopg2.connect(
        host=args.host,
        port=args.port,
        database=args.database,
        user=args.user,
        password=args.password,
    )
    conn.autocommit = True
    cur = conn.cursor()

    try:
        consultas = {etiqueta: cargar_consultas(ruta) for etiqueta, ruta in archivos.items()}

        n_oltp = len(consultas["OLTP"])
        n_star = len(consultas["STAR"])
        n_snow = len(consultas["SNOW"])

        if not (n_oltp == n_star == n_snow):
            raise ValueError(
                f"Los archivos no tienen el mismo número de consultas: "
                f"OLTP={n_oltp}, STAR={n_star}, SNOW={n_snow}"
            )

        resultados = []

        print(f"Conectado a {args.database} en {args.host}:{args.port}")
        print(f"Repeticiones por consulta: {args.repeticiones}")
        print()

        for i in range(n_oltp):
            nombre_oltp, query_oltp = consultas["OLTP"][i]
            _, query_star = consultas["STAR"][i]
            _, query_snow = consultas["SNOW"][i]

            nombre = nombre_oltp or f"Q{i+1}"

            print(f"=== {nombre} ===")

            print("Ejecutando OLTP...")
            r_oltp = medir(cur, query_oltp, args.repeticiones)

            print("Ejecutando STAR...")
            r_star = medir(cur, query_star, args.repeticiones)

            print("Ejecutando SNOW...")
            r_snow = medir(cur, query_snow, args.repeticiones)

            mejora_star_vs_oltp = (
                ((r_oltp["media_s"] - r_star["media_s"]) / r_oltp["media_s"]) * 100
                if r_oltp["media_s"] > 0 else 0.0
            )

            penalizacion_snow_vs_star = (
                ((r_snow["media_s"] - r_star["media_s"]) / r_star["media_s"]) * 100
                if r_star["media_s"] > 0 else 0.0
            )

            resultados.append({
                "consulta": nombre,
                "filas_oltp": r_oltp["filas"],
                "filas_star": r_star["filas"],
                "filas_snow": r_snow["filas"],
                "oltp_media_ms": r_oltp["media_s"] * 1000,
                "star_media_ms": r_star["media_s"] * 1000,
                "snow_media_ms": r_snow["media_s"] * 1000,
                "oltp_desv_ms": r_oltp["desv_s"] * 1000,
                "star_desv_ms": r_star["desv_s"] * 1000,
                "snow_desv_ms": r_snow["desv_s"] * 1000,
                "mejora_star_vs_oltp_pct": mejora_star_vs_oltp,
                "penalizacion_snow_vs_star_pct": penalizacion_snow_vs_star,
            })

            print(f"OLTP  -> media: {r_oltp['media_s']*1000:.3f} ms | filas: {r_oltp['filas']}")
            print(f"STAR  -> media: {r_star['media_s']*1000:.3f} ms | filas: {r_star['filas']}")
            print(f"SNOW  -> media: {r_snow['media_s']*1000:.3f} ms | filas: {r_snow['filas']}")
            print(f"Mejora STAR vs OLTP: {mejora_star_vs_oltp:+.2f}%")
            print(f"Penalización SNOW vs STAR: {penalizacion_snow_vs_star:+.2f}%")
            print()

        out_csv = Path(args.out_csv)
        with out_csv.open("w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "consulta",
                "filas_oltp",
                "filas_star",
                "filas_snow",
                "oltp_media_ms",
                "star_media_ms",
                "snow_media_ms",
                "oltp_desv_ms",
                "star_desv_ms",
                "snow_desv_ms",
                "mejora_star_vs_oltp_pct",
                "penalizacion_snow_vs_star_pct",
            ])
            writer.writeheader()
            writer.writerows(resultados)

        print(f"Resultados guardados en: {out_csv.resolve()}")

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
