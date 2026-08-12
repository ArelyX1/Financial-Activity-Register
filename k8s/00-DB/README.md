# DB Setup y Import de GADM al Pod de PostgreSQL

## Variables de conexión del Pod `incasur-db`

```
DB_USER     = perripopo
DB_PASS     = p3rr1p0p0
DB_HOST     = localhost (dentro del propio pod)
DB_PORT     = 5432
DB_NAME     = incasur
BATCH_SIZE  = 100
GDB_PATH    = /tmp/gadm/gadm_410-gdb (dentro del pod)
```

---

## Paso 0: Aumentar recursos del pod (importante para evitar OOM)

El pod necesita al menos 3-4Gi de RAM para procesar el GDB de 1.5GB con `fiona`.

```bash
kubectl patch deployment incasur-db -n 2023241041 \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","resources":{"limits":{"memory":"4Gi","cpu":"1000m"},"requests":{"memory":"512Mi","cpu":"200m"}}}]}}}}'

# Reinicia el pod
kubectl delete pod $(kubectl get pods -n 2023241041 | grep incasur-db | awk '{print $1}') -n 2023241041
```

---

## Paso 1: Aplicar `init.sql` al Pod

Ya copiaste `init.sql` al pod con:

```bash
kubectl cp DBCONF/init.sql <pod-name>:/tmp/init.sql -n 2023241041
```

Aplica el init.sql:

```bash
kubectl exec <pod-name> -n 2023241041 -- bash -c 'PGPASSWORD=p3rr1p0p0 psql -U perripopo -d incasur -f /tmp/init.sql -v ON_ERROR_STOP=1'
```

Verifica tablas:

```bash
kubectl exec <pod-name> -n 2023241041 -- bash -c 'PGPASSWORD=p3rr1p0p0 psql -U perripopo -d incasur -c "\dt"'
```

---

## Paso 2: Ejecutar los Scripts de Python DIRECTAMENTE en el Pod

### 2.1. Crear directorio y copiar archivos

```bash
# 1. Crear directorio
kubectl exec <pod-name> -n 2023241041 -- mkdir -p /tmp/gadm

# 2. Copiar .env, scripts y requirements
kubectl cp DBCONF/.env <pod-name>:/tmp/gadm/.env -n 2023241041
kubectl cp DBCONF/import_gadm.py <pod-name>:/tmp/gadm/import_gadm.py -n 2023241041
kubectl cp DBCONF/requirements.txt <pod-name>:/tmp/gadm/requirements.txt -n 2023241041
```

### 2.2. Corregir .env para el pod

Sobrescribe el `.env` dentro del pod con las credenciales correctas:

```bash
kubectl exec <pod-name> -n 2023241041 -- bash -c 'cd /tmp/gadm && cat > .env << '\''EOF'\''
DB_USER=perripopo
DB_PASS=p3rr1p0p0
DB_HOST=localhost
DB_PORT=5432
DB_NAME=incasur
GDB_PATH=/tmp/gadm/gadm_410-gdb
BATCH_SIZE=100
EOF'
```

### 2.3. Instalar dependencias

```bash
kubectl exec <pod-name> -n 2023241041 -- bash -c 'cd /tmp/gadm && pip3 install -r requirements.txt'
```

### 2.4. Copiar el GDB al pod (1.5GB - puede tardar varios minutos)

```bash
kubectl cp /home/arelyxl/Downloads/Repos/Geo/gadm_410-gdb <pod-name>:/tmp/gadm/gadm_410-gdb -n 2023241041
```

### 2.5. Ejecutar import_gadm.py

```bash
kubectl exec <pod-name> -n 2023241041 -- bash -c 'cd /tmp/gadm && python3 -u import_gadm.py /tmp/gadm/gadm_410-gdb'
```

---

## Paso 3: (Opcional) Ver detalle con `seeDetailGADM.py`

```bash
kubectl exec <pod-name> -n 2023241041 -- bash -c 'cd /tmp/gadm && python3 seeDetailGADM.py'
```

---

## Paso 4: Conectar desde DBeaver (o cualquier cliente externo)

### Opción A: Usando kubectl port-forward (recomendado)

```bash
# Port-forward del service al localhost
# El puerto 5433 no interfiere con lidercom-db (5432)
kubectl port-forward svc/incasur-psql-service 5433:5433 -n 2023241041
```

En DBeaver:
- **Host**: `localhost`
- **Port**: `5433`
- **Database**: `incasur`
- **Username**: `perripopo`
- **Password**: `p3rr1p0p0`

### Opción B: Conectar desde otra máquina (NodePort)

Cambia el service a NodePort:

```bash
kubectl patch svc incasur-psql-service -n 2023241041 \
  -p '{"spec":{"type":"NodePort","ports":[{"port":5433,"targetPort":5433,"nodePort":30090}]}}'
```

Obtén la IP del nodo:

```bash
kubectl get nodes -o wide
```

En DBeaver:
- **Host**: IP del nodo (ej: `10.0.0.1`)
- **Port**: `30090`
- **Database**: `incasur`
- **Username**: `perripopo`
- **Password**: `p3rr1p0p0`

---

## Resumen completo (todo en un comando)

```bash
POD=$(kubectl get pods -n 2023241041 | grep incasur-db | head -1 | awk '{print $1}')

# Init SQL
kubectl exec $POD -n 2023241041 -- bash -c 'PGPASSWORD=p3rr1p0p0 psql -U perripopo -d incasur -f /tmp/init.sql -v ON_ERROR_STOP=1'

# Setup
kubectl exec $POD -n 2023241041 -- mkdir -p /tmp/gadm
kubectl cp DBCONF/.env $POD:/tmp/gadm/.env -n 2023241041
kubectl cp DBCONF/import_gadm.py $POD:/tmp/gadm/import_gadm.py -n 2023241041
kubectl cp DBCONF/requirements.txt $POD:/tmp/gadm/requirements.txt -n 2023241041

# Fix .env
kubectl exec $POD -n 2023241041 -- bash -c 'cat > /tmp/gadm/.env << '\''EOF'\''
DB_USER=perripopo
DB_PASS=p3rr1p0p0
DB_HOST=localhost
DB_PORT=5432
DB_NAME=incasur
GDB_PATH=/tmp/gadm/gadm_410-gdb
BATCH_SIZE=100
EOF'

# Install deps
kubectl exec $POD -n 2023241041 -- bash -c 'cd /tmp/gadm && pip3 install -r requirements.txt'

# Copy GDB
kubectl cp /home/arelyxl/Downloads/Repos/Geo/gadm_410-gdb $POD:/tmp/gadm/gadm_410-gdb -n 2023241041

# Run import
kubectl exec $POD -n 2023241041 -- bash -c 'cd /tmp/gadm && python3 -u import_gadm.py /tmp/gadm/gadm_410-gdb'
```
