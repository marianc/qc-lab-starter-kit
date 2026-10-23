import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASS", "Pass@word1")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
SOURCE_DB = os.getenv("SOURCE_DB", "quality_control")

def generate_dictionary():
    print(f"Connecting to database '{SOURCE_DB}' at {DB_HOST}:{DB_PORT}...")
    try:
        conn = psycopg2.connect(
            dbname=SOURCE_DB,
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST,
            port=DB_PORT
        )
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        return False

    cursor = conn.cursor()

    # 1. Fetch all public tables
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    """)
    tables = [row[0] for row in cursor.fetchall()]

    if not tables:
        print("⚠️ No tables found in public schema.")
        cursor.close()
        conn.close()
        return False

    print(f"Found {len(tables)} tables. Generating documentation...")

    # Ensure output directory exists
    docs_dir = os.path.join(os.getcwd(), "docs") if os.path.basename(os.getcwd()) != "database" else "docs"
    os.makedirs(docs_dir, exist_ok=True)
    output_path = os.path.join(docs_dir, "DATABASE_DICTIONARY.md")

    md_lines = [
        "# QC LIS Database Dictionary & Reference Manual",
        "",
        "This document is automatically generated from the live PostgreSQL database schema and comments. It provides a comprehensive reference manual of all tables, columns, data types, and functional descriptions in the QC LIS (Laboratory Information Management System).",
        "",
        "---",
        "",
        "## Table of Contents",
        ""
    ]

    for tname in tables:
        md_lines.append(f"- [{tname}](#table-{tname.replace('_', '-')})")

    md_lines.extend([
        "",
        "---",
        ""
    ])

    for tname in tables:
        # Table comment
        cursor.execute("""
            SELECT obj_description(c.oid, 'pg_class')
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname = 'public' AND c.relname = %s;
        """, (tname,))
        t_comment_row = cursor.fetchone()
        t_comment = t_comment_row[0] if t_comment_row and t_comment_row[0] else f"Table {tname} in QC LIS database."

        # Primary Key
        cursor.execute("""
            SELECT kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            WHERE tc.table_schema = 'public' 
              AND tc.table_name = %s 
              AND tc.constraint_type = 'PRIMARY KEY'
            ORDER BY kcu.ordinal_position;
        """, (tname,))
        pk_cols = [row[0] for row in cursor.fetchall()]

        # Unique Constraints
        cursor.execute("""
            SELECT tc.constraint_name, kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            WHERE tc.table_schema = 'public' 
              AND tc.table_name = %s 
              AND tc.constraint_type = 'UNIQUE'
            ORDER BY tc.constraint_name, kcu.ordinal_position;
        """, (tname,))
        unq_rows = cursor.fetchall()
        unq_map = {}
        for cname, col in unq_rows:
            if cname not in unq_map:
                unq_map[cname] = []
            unq_map[cname].append(col)

        # Foreign Keys
        cursor.execute("""
            SELECT 
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
              ON tc.constraint_name = kcu.constraint_name
             AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu 
              ON ccu.constraint_name = tc.constraint_name
             AND ccu.table_schema = tc.table_schema
            WHERE tc.table_schema = 'public' 
              AND tc.table_name = %s 
              AND tc.constraint_type = 'FOREIGN KEY';
        """, (tname,))
        fk_rows = cursor.fetchall()

        # Columns
        cursor.execute("""
            SELECT 
                c.column_name,
                c.data_type,
                c.character_maximum_length,
                c.column_default,
                c.is_nullable,
                col_description(p.oid, a.attnum) AS comment
            FROM information_schema.columns c
            JOIN pg_namespace n ON n.nspname = c.table_schema
            JOIN pg_class p ON p.relname = c.table_name AND p.relnamespace = n.oid
            JOIN pg_attribute a ON a.attrelid = p.oid AND a.attname = c.column_name
            WHERE c.table_schema = 'public' AND c.table_name = %s AND NOT a.attisdropped
            ORDER BY c.ordinal_position;
        """, (tname,))
        col_rows = cursor.fetchall()

        md_lines.append(f"## Table: `{tname}`")
        md_lines.append(f"<a id=\"table-{tname.replace('_', '-')}\"></a>")
        md_lines.append("")
        md_lines.append(f"**Description:** {t_comment}")
        md_lines.append("")

        if pk_cols:
            md_lines.append(f"**Primary Key:** `{', '.join(pk_cols)}`")
            md_lines.append("")

        if unq_map:
            unq_strs = [f"{cname}({', '.join(cols)})" for cname, cols in unq_map.items()]
            md_lines.append(f"**Unique Constraints:** `{', '.join(unq_strs)}`")
            md_lines.append("")

        if fk_rows:
            md_lines.append("**Foreign Keys:**")
            for col, f_table, f_col in fk_rows:
                md_lines.append(f"- `{col}` -> `{f_table}({f_col})`")
            md_lines.append("")

        md_lines.append("### Columns")
        md_lines.append("")
        md_lines.append("| Column Name | Data Type & Definition | Description |")
        md_lines.append("| :--- | :--- | :--- |")

        for col_name, data_type, max_len, col_def, is_nullable, col_comment in col_rows:
            # Build type definition string
            type_str = data_type
            if max_len:
                type_str += f"({max_len})"
            if is_nullable == 'NO':
                type_str += " NOT NULL"
            if col_def:
                type_str += f" DEFAULT {col_def}"

            comment_text = col_comment if col_comment else f"Column {col_name}."
            
            # Escape pipe characters for Markdown table
            type_esc = type_str.replace('|', '\\|')
            comment_esc = comment_text.replace('|', '\\|')

            md_lines.append(f"| `{col_name}` | `{type_esc}` | {comment_esc} |")

        md_lines.append("")
        md_lines.append("---")
        md_lines.append("")

    cursor.close()
    conn.close()

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(md_lines))

    print(f"✅ Successfully generated database dictionary at: {output_path}")
    return True

if __name__ == "__main__":
    # Ensure working directory is database root if run directly
    if os.path.basename(os.getcwd()) != "database":
        if os.path.exists("database"):
            os.chdir("database")
    generate_dictionary()
