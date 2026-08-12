Requeriments:
REDIS - CELERY queue & processing - Rust
ML processing module - Python
GraphQL - IDK xd i would use Rust and Python
I need make Certificates - blockchain?
Aproach the DB processing - Timescale
Account security - Rust

Independent Modules:
ML
QUEUE
LIDERCOM-APIS
ACCOUNT SIGN UP
CERTIFICATES

Now for backend i need add this: Blockchain wallets for share info about accounts, like:

El padre entra a la app (Login tradicional).

Tu backend mira la tabla Relacion_Familiar y confirma: "Sí, este UUID es el padre de este otro UUID".

Aquí viene el truco: El backend toma la wallet_address del padre y la del hijo y le pregunta a la Blockchain: "Dame los registros firmados para la wallet 0xHijo que la wallet 0xPadre tiene permiso de ver".

I mean the superior account can see the transactions that participant has been realized.

## Redis

El sistema usa Redis para cachear permisos de usuarios. Necesitas tener Redis corriendo:

### Iniciar Redis

**Opción 1 — Docker** (recomendado):
```bash
docker run -d --name redis -p 6379:6379 redis:7
```

**Opción 2 — Instalación directa (Ubuntu/Debian)**:
```bash
sudo apt update && sudo apt install redis-server -y
sudo systemctl start redis
```

**Opción 3 — macOS**:
```bash
brew install redis && brew services start redis
```

### Verificar
```bash
redis-cli ping
# Debe responder: PONG
```

### Configuración
Sin cambios, el `.env` ya apunta a `redis://localhost:6379/0`.
Si Redis no está disponible, la app cae a DB directa sin cache.
