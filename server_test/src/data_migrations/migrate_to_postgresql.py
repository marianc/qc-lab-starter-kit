import psycopg2
import os

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))

def get_source_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database="quality_control_seed",
        user=DB_USER,
        password=DB_PASS
    )

def get_target_connection():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database="quality_control",
        user=DB_USER,
        password=DB_PASS
    )

def truncate_and_reset_postgresql_tables(tables: list):
    print("Truncating PostgreSQL tables and resetting sequences...")
    with get_target_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SET session_replication_role = 'replica';")
            for table in tables:
                cur.execute(f'TRUNCATE TABLE public."{table}" RESTART IDENTITY CASCADE;')
                print(f"Truncated table: {table}")
            cur.execute("SET session_replication_role = 'origin';")

def copy_data(tables: list):
    print("Migrating data from seed to target...")
    with get_source_connection() as src_conn, get_target_connection() as tgt_conn:
        with src_conn.cursor() as src_cur, tgt_conn.cursor() as tgt_cur:
            tgt_cur.execute("SET session_replication_role = 'replica';")
            
            for table in tables:
                src_cur.execute(f'SELECT * FROM public."{table}"')
                rows = src_cur.fetchall()
                if not rows:
                    continue
                # get column names
                cols = [desc[0] for desc in src_cur.description]
                cols_str = ", ".join([f'"{c}"' for c in cols])
                
                # Check for identity columns to use OVERRIDING SYSTEM VALUE
                tgt_cur.execute(f"SELECT is_identity FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '{table}' AND is_identity = 'YES';")
                has_identity = tgt_cur.fetchone() is not None
                
                overriding = " OVERRIDING SYSTEM VALUE" if has_identity else ""
                placeholders = ", ".join(["%s"] * len(cols))
                insert_sql = f'INSERT INTO public."{table}" ({cols_str}){overriding} VALUES ({placeholders})'
                
                tgt_cur.executemany(insert_sql, rows)
                print(f"Inserted {len(rows)} rows into {table}")
            
            tgt_cur.execute("SET session_replication_role = 'origin';")

def sync_sequences(tables: list):
    print("Syncing sequences...")
    with get_target_connection() as conn:
        with conn.cursor() as cur:
            for table in tables:
                try:
                    cur.execute(f"SELECT pg_get_serial_sequence('public.\"{table}\"', 'id');")
                    res = cur.fetchone()
                    if res and res[0]:
                        seq_name = res[0]
                        cur.execute(f"SELECT setval('{seq_name}', COALESCE((SELECT MAX(id) FROM public.\"{table}\"), 0) + 1, false);")
                        print(f"Synced sequence for {table}")
                except Exception as e:
                    print(f"No sequence for {table} or error: {e}")
                    conn.rollback()

if __name__ == "__main__":
    tables_migration_order = [
        "categories", "norms", "reception_types", "units", "value_types",
        "form_groups", "users", "materials", "tests", "control_codes",
        "forms", "receptions", "form_params", "test_enums", "material_tests",
        "category_tests", "reception_tests", "specs", "measurements",
        "reports", "spec_tests", "measurement_params", "measurement_tests",
        "report_tests", "certificates", "certificate_tests", "form_evals",
        "form_eval_params", "spec_test_evals"
    ]
    truncate_and_reset_postgresql_tables(tables_migration_order)
    copy_data(tables_migration_order)
    sync_sequences(tables_migration_order)
