# DB Setup y Import de GADM al Pod de PostgreSQL

## Variables de conexión del Pod `incasur-db`

```
DB_USER     = perripopo
DB_PASS     = p3rr1p0p0
DB_HOST     = incasur-db-6d5c8f9c68-br22p (o via Service)
DB_PORT     = 5432
DB_NAME     = incasur
GDB_PATH    = /home/arelyxl/Downloads/Repos/Geo/gadm_410-gdb  (local)
BATCH_SIZE  = 500
```

---

## Paso 1: Aplicar `init.sql` al Pod

Ya copiaste `init.sql` al pod con:

```bash
kubectl cp DBCONF/init.sql incasur-db-6d5c8f9c68-br22p:/tmp/init.sql
```

Aplica el init.sql directamente dentro del pod:

```bash
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'PGPASSWORD=p3rr1p0p0 psql -U perripopo -d incasur -f /tmp/init.sql -v ON_ERROR_STOP=1'
```

Verifica que las tablas se crearon:

```bash
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'PGPASSWORD=p3rr1p0p0 psql -U perripopo -d incasur -c "\dt"'
```

---

## Paso 2: Ejecutar los Scripts de Python DIRECTAMENTE en el Pod

### 2.1. Copiar los archivos al pod

Necesitas copiar el `.env`, los scripts Python, `requirements.txt` y **el GDB** al pod:

```bash
# Copia config y scripts
kubectl cp DBCONF/.env incasur-db-6d5c8f9c68-br22p:/tmp/gadm/.env
kubectl cp DBCONF/import_gadm.py incasur-db-6d5c8f9c68-br22p:/tmp/gadm/import_gadm.py
kubectl cp DBCONF/seeDetailGADM.py incasur-db-6d5c8f9c68-br22p:/tmp/gadm/seeDetailGADM.py
kubectl cp DBCONF/requirements.txt incasur-db-6d5c8f9c68-br22p:/tmp/gadm/requirements.txt

# Copia el GDB (puede ser grande)
kubectl cp /home/arelyxl/Downloads/Repos/Geo/gadm_410-gdb incasur-db-6d5c8f9c68-br22p:/tmp/gadm/gadm_410-gdb
```

> **Nota:** El pod `incasur-db` ya tiene PostgreSQL 17 con extensiones. Verifica si incluye las dependencias de Python o instálalas.

### 2.2. Instalar dependencias de Python dentro del pod

```bash
kubectl exec -it incasur-db-6d5c8f9c68-br22p -- bash
# Dentro del pod:
mkdir -p /tmp/gadm
cd /tmp/gadm
pip3 install -r requirements.txt
```

O sin entrar al pod interactivamente:

```bash
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'cd /tmp/gadm && pip3 install -r requirements.txt'
```

### 2.3. Ejecutar `import_gadm.py`

#### Opción A: Apuntando a `localhost` (dentro del pod)

Edita el `.env` para que `DB_HOST=localhost` y ejecuta:

```bash
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'cd /tmp/gadm && python3 import_gadm.py /tmp/gadm/gadm_410-gdb'
```

#### Opción B: Apuntando a otro pod/service (ej. `lidercom-db`)

Si `DB_HOST` apunta a otro host, asegúrate de que sea alcanzable desde el pod.

#### Opción C: Usar `kubectl port-forward` y ejecutar localmente

Si prefieres ejecutar el script localmente pero conectado al pod:

```bash
kubectl port-forward svc/incasur-db-svc 5432:5432 &
# Luego ejecuta localmente con DB_HOST=localhost DB_PORT=5432
python3 DBCONF/import_gadm.py /home/arelyxl/Downloads/Repos/Geo/gadm_410-gdb
```

---

## Paso 3: (Opcional) Ver detalle con `seeDetailGADM.py`

```bash
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'cd /tmp/gadm && python3 seeDetailGADM.py'
```

---

## Resumen de comandos

```bash
# 1. Aplicar init.sql
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'PGPASSWORD=p3rr1p0p0 psql -U perripopo -d incasur -f /tmp/init.sql -v ON_ERROR_STOP=1'

# 2. Copiar archivos y GDB al pod
kubectl cp DBCONF/.env incasur-db-6d5c8f9c68-br22p:/tmp/gadm/.env
kubectl cp DBCONF/import_gadm.py incasur-db-6d5c8f9c68-br22p:/tmp/gadm/import_gadm.py
kubectl cp DBCONF/requirements.txt incasur-db-6d5c8f9c68-br22p:/tmp/gadm/requirements.txt
kubectl cp /home/arelyxl/Downloads/Repos/Geo/gadm_410-gdb incasur-db-6d5c8f9c68-br22p:/tmp/gadm/gadm_410-gdb

# 3. Instalar dependencias
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'cd /tmp/gadm && pip3 install -r requirements.txt'

# 4. Ejecutar import
kubectl exec incasur-db-6d5c8f9c68-br22p -- bash -c 'cd /tmp/gadm && python3 import_gadm.py /tmp/gadm/gadm_410-gdb'
```
