#!/usr/bin/env python3
import os
import sys
import re
from pathlib import Path
from dotenv import load_dotenv

# Load .env from same directory as script
load_dotenv(Path(__file__).parent / ".env")

DB_USER = os.getenv("DB_USER", "arelyxl")
DB_PASS = os.getenv("DB_PASS", "elmomero123")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "lidercom")
BATCH_SIZE = int(os.getenv("BATCH_SIZE", 500))

# Map GADM field names to DB column names
FIELD_MAP = {
    "GID_0": "cgid0", "NAME_0": "cname0", "VARNAME_0": "cvarname0",
    "GID_1": "cgid1", "NAME_1": "cname1", "VARNAME_1": "cvarname1",
    "NL_NAME_1": "cnlname1", "ISO_1": "ciso1", "HASC_1": "chasc1",
    "CC_1": "ccc1", "TYPE_1": "ctype1", "ENGTYPE_1": "cengtype1", "VALIDFR_1": "cvalidfr1",
    "GID_2": "cgid2", "NAME_2": "cname2", "VARNAME_2": "cvarname2",
    "NL_NAME_2": "cnlname2", "HASC_2": "chasc2", "CC_2": "ccc2",
    "TYPE_2": "ctype2", "ENGTYPE_2": "cengtype2", "VALIDFR_2": "cvalidfr2",
    "GID_3": "cgid3", "NAME_3": "cname3", "VARNAME_3": "cvarname3",
    "NL_NAME_3": "cnlname3", "HASC_3": "chasc3", "CC_3": "ccc3",
    "TYPE_3": "ctype3", "ENGTYPE_3": "cengtype3", "VALIDFR_3": "cvalidfr3",
    "GID_4": "cgid4", "NAME_4": "cname4",
    "TYPE_4": "ctype4", "ENGTYPE_4": "cengtype4",
    "GID_5": "cgid5", "NAME_5": "cname5",
    "TYPE_5": "ctype5", "ENGTYPE_5": "cengtype5",
    "SOVEREIGN": "csovereign", "GOVERNEDBY": "cgovernedby",
    "DISPUTEDBY": "cdisputedby", "REGION": "cregion",
    "CONTINENT": "ccontinent", "COUNTRY": "ccountry",
    "Shape_Length": "nshapelength", "Shape_Area": "nshapearea",
    "UID": "nuidgadm",
}

DB_COLUMNS = [
    "nuidgadm", "cgid0", "cname0", "cvarname0",
    "cgid1", "cname1", "cvarname1", "cnlname1", "ciso1", "chasc1", "ccc1",
    "ctype1", "cengtype1", "cvalidfr1",
    "cgid2", "cname2", "cvarname2", "cnlname2", "chasc2", "ccc2",
    "ctype2", "cengtype2", "cvalidfr2",
    "cgid3", "cname3", "cvarname3", "cnlname3", "chasc3", "ccc3",
    "ctype3", "cengtype3", "cvalidfr3",
    "cgid4", "cname4", "ctype4", "cengtype4",
    "cgid5", "cname5", "ctype5", "cengtype5",
    "csovereign", "cgovernedby", "cdisputedby",
    "cregion", "ccontinent", "ccountry",
    "nshapelength", "nshapearea", "ggeom",
]

def normalize(val):
    if val is None:
        return None
    if isinstance(val, (list, tuple)):
        return "|".join(str(x) for x in val) if val else None
    s = str(val).strip()
    return s if s and s.upper() != "NA" else None


def get_conn():
    from psycopg2 import connect
    conn = connect(host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASS)
    conn.autocommit = False
    return conn


def get_next_uid(conn):
    with conn.cursor() as cur:
        cur.execute('SELECT COALESCE(MAX(nuidgadm), 0) FROM "S01BOUNDARIE"')
        return cur.fetchone()[0] + 1


def make_uid_hash(gid: str, base: int) -> int:
    h = 0
    for c in gid:
        h = h * 31 + ord(c)
        h &= 0x7FFFFFFF
    return base + (h % 1000000)


def ensure_extensions(conn):
    with conn.cursor() as cur:
        cur.execute('CREATE EXTENSION IF NOT EXISTS postgis')
        cur.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"')


def detect_format(path: str):
    p = Path(path)
    if p.is_dir():
        shp_files = list(p.glob("*.shp"))
        if shp_files:
            return "shp_dir", p
        gdb_dirs = list(p.glob("*.gdb")) + [p if p.suffix == ".gdb" else None]
        for g in gdb_dirs:
            if g and g.is_dir():
                return "gdb", g
        return None, None
    elif p.is_file():
        if p.suffix == ".gdb":
            return "gdb", p.parent / p.stem
        elif p.suffix == ".gpkg":
            return "gpkg", p
    return None, None


def get_shp_levels(shp_dir: Path):
    levels = {}
    pattern = re.compile(r".*_(\d+)\.shp$")
    for f in sorted(shp_dir.glob("*.shp")):
        m = pattern.search(str(f.name))
        if m:
            levels[int(m.group(1))] = f
    return levels


def upsert_sql():
    fields_str = ", ".join(DB_COLUMNS)
    update_cols = [c for c in DB_COLUMNS if c != "nuidgadm"]
    set_clause = ", ".join(
        f'"{c}" = COALESCE(EXCLUDED."{c}", "S01BOUNDARIE"."{c}")' for c in update_cols
    )
    return f'INSERT INTO "S01BOUNDARIE" ({fields_str}) VALUES %s ON CONFLICT (nuidgadm) DO UPDATE SET {set_clause}'


def build_gid_uid_cache(conn):
    cache = {}
    with conn.cursor() as cur:
        for level in range(6):
            cur.execute(f'SELECT cgid{level}, nuidgadm FROM "S01BOUNDARIE" WHERE cgid{level} IS NOT NULL')
            for gid, uid in cur.fetchall():
                cache[gid] = uid
    return cache


def process_layer(src, uid_counter, insert_sql, conn, batch, total, level=None, gid_cache=None):
    from shapely.geometry import shape
    from psycopg2.extras import execute_values

    for feat in src:
        props = feat.get("properties", {})
        geom_wkt = None
        if feat.get("geometry"):
            try:
                geom_wkt = shape(feat["geometry"]).wkt
            except Exception as e:
                print(f"  Geometry error: {e}")
                continue

        row = {col: None for col in DB_COLUMNS}

        # Build deepest GID for UID
        deepest_gid = None
        deepest_level = -1
        if level is not None:
            for l in reversed(range(level + 1)):
                gid_key = f"GID_{l}"
                gid_val = normalize(props.get(gid_key))
                if gid_val:
                    row[FIELD_MAP[gid_key]] = gid_val
                    if deepest_gid is None:
                        deepest_gid = gid_val
                        deepest_level = l
        else:
            for l in range(5, -1, -1):
                gid_val = normalize(props.get(f"GID_{l}"))
                if gid_val:
                    deepest_gid = gid_val
                    deepest_level = l
                    break

        # Try UID from props, then from cache, then generate
        uid_val = props.get("UID")
        if uid_val is not None:
            row["nuidgadm"] = int(uid_val)
        elif deepest_gid and gid_cache and deepest_gid in gid_cache:
            row["nuidgadm"] = gid_cache[deepest_gid]
        elif deepest_gid:
            row["nuidgadm"] = make_uid_hash(deepest_gid, uid_counter)
        else:
            row["nuidgadm"] = uid_counter

        # Map fields
        for shp_field, db_field in FIELD_MAP.items():
            if db_field in row and row[db_field] is None:
                if shp_field in props:
                    row[db_field] = normalize(props[shp_field])

        # COUNTRY -> cname0 (shapefiles often don't have NAME_0)
        country = normalize(props.get("COUNTRY"))
        if country:
            if not row["cname0"]:
                row["cname0"] = country
            row["ccountry"] = country

        row["ggeom"] = geom_wkt

        values = tuple(row[col] for col in DB_COLUMNS)
        batch.append(values)
        total += 1
        uid_counter += 1

        if len(batch) >= BATCH_SIZE:
            with conn.cursor() as cur:
                execute_values(cur, insert_sql, batch, template=None, page_size=BATCH_SIZE)
            conn.commit()
            print(f"  Inserted {total} records...")
            batch.clear()

    return uid_counter, total, batch


def import_from_shp(shp_dir: Path):
    import fiona
    from psycopg2.extras import execute_values

    levels = get_shp_levels(shp_dir)
    if not levels:
        print("No shapefiles found")
        return

    print(f"Found shapefile levels: {sorted(levels.keys())}")

    conn = get_conn()
    ensure_extensions(conn)
    next_uid = get_next_uid(conn)
    print(f"Starting UID: {next_uid}")

    gid_cache = build_gid_uid_cache(conn)
    print(f"Loaded {len(gid_cache)} existing GID mappings")

    insert_sql = upsert_sql()
    total = 0
    uid_counter = next_uid

    for level in sorted(levels.keys()):
        shp_path = levels[level]
        print(f"\nProcessing level {level}: {shp_path.name}")
        batch = []

        with fiona.open(str(shp_path)) as src:
            uid_counter, total, batch = process_layer(src, uid_counter, insert_sql, conn, batch, total, level, gid_cache)

        if batch:
            with conn.cursor() as cur:
                execute_values(cur, insert_sql, batch, template=None, page_size=len(batch))
            conn.commit()
            print(f"  Level {level} done. Total so far: {total}")

    conn.close()
    print(f"\nImport complete: {total} records")


def import_from_gdb(gdb_path: Path):
    import fiona
    from psycopg2.extras import execute_values

    layers = fiona.listlayers(str(gdb_path))
    print(f"Available layers: {layers}")
    adm_layers = [l for l in layers if "ADM" in l.upper()]
    if not adm_layers:
        print("No ADM layers found in GDB")
        return

    conn = get_conn()
    ensure_extensions(conn)
    next_uid = get_next_uid(conn)
    print(f"Starting UID: {next_uid}")

    gid_cache = build_gid_uid_cache(conn)
    print(f"Loaded {len(gid_cache)} existing GID mappings")

    insert_sql = upsert_sql()
    total = 0
    uid_counter = next_uid

    for layer in adm_layers:
        print(f"\nProcessing layer: {layer}")
        batch = []

        with fiona.open(str(gdb_path), layer=layer) as src:
            uid_counter, total, batch = process_layer(src, uid_counter, insert_sql, conn, batch, total, gid_cache=gid_cache)

        if batch:
            with conn.cursor() as cur:
                execute_values(cur, insert_sql, batch, template=None, page_size=len(batch))
            conn.commit()
            print(f"  Layer {layer} done. Total so far: {total}")

    conn.close()
    print(f"\nImport complete: {total} records")


def import_from_gpkg(gpkg_path: Path):
    import fiona
    from psycopg2.extras import execute_values

    layers = fiona.listlayers(str(gpkg_path))
    print(f"Available layers: {layers}")
    adm_layers = [l for l in layers if "ADM" in l.upper()]
    if not adm_layers:
        print("No ADM layers found in GPKG")
        return

    conn = get_conn()
    ensure_extensions(conn)
    next_uid = get_next_uid(conn)
    print(f"Starting UID: {next_uid}")

    gid_cache = build_gid_uid_cache(conn)
    print(f"Loaded {len(gid_cache)} existing GID mappings")

    insert_sql = upsert_sql()
    total = 0
    uid_counter = next_uid

    for layer in adm_layers:
        print(f"\nProcessing layer: {layer}")
        batch = []

        with fiona.open(str(gpkg_path), layer=layer) as src:
            uid_counter, total, batch = process_layer(src, uid_counter, insert_sql, conn, batch, total, gid_cache=gid_cache)

        if batch:
            with conn.cursor() as cur:
                execute_values(cur, insert_sql, batch, template=None, page_size=len(batch))
            conn.commit()
            print(f"  Layer {layer} done. Total so far: {total}")

    conn.close()
    print(f"\nImport complete: {total} records")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Import GADM data into S01BOUNDARIE")
    parser.add_argument("path", nargs="?", help="Path to GADM data (GDB, GPKG, or shapefile directory)")
    args = parser.parse_args()

    source = args.path or os.path.expanduser(os.getenv("GDB_PATH", ""))
    if not source or not os.path.exists(source):
        print(f"Path not found: {source}")
        print("Usage: python import_gadm.py <path_to_gadm_data>")
        print("Or set GDB_PATH in .env")
        sys.exit(1)

    fmt, resolved = detect_format(source)
    if fmt == "shp_dir":
        import_from_shp(resolved)
    elif fmt == "gdb":
        import_from_gdb(resolved)
    elif fmt == "gpkg":
        import_from_gpkg(resolved)
    else:
        print(f"Unknown format: {source}")
        sys.exit(1)


if __name__ == "__main__":
    main()
