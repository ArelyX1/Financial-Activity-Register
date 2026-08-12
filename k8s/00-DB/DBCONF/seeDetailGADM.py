#!/usr/bin/env python3
import sys
import os
from pathlib import Path
from dotenv import load_dotenv

# Load .env from same directory as script
load_dotenv(Path(__file__).parent / ".env")

def main():
    if len(sys.argv) > 1:
        gdb_path = sys.argv[1]
    else:
        gdb_path = os.path.expanduser(os.getenv("GDB_PATH", ""))
    
    if not gdb_path or not os.path.exists(gdb_path):
        print(f"Path not found: {gdb_path}")
        print("Usage: python seeDetailGADM.py <path_to_gdb>")
        print("Or set GDB_PATH in .env")
        sys.exit(1)
    
    import fiona
    layers = fiona.listlayers(gdb_path)
    
    for layer_name in layers:
        print(f"\n--- Capa: {layer_name} ---")
        with fiona.open(gdb_path, layer=layer_name) as layer:
            for field_name, field_type in layer.schema['properties'].items():
                print(f"Campo: {field_name} | Tipo: {field_type}")

if __name__ == "__main__":
    main()
