Requeriments:
REDIS - CELERY queue & processing - Rust
ML processing module - Python
GraphQL - IDK xd i would use Rust and Python
Account security - Rust (encryption de contraseñas + códigos de recuperación)

Independent Modules:
ML
QUEUE
LIDERCOM-APIS
ACCOUNT SIGN UP
CERTIFICATES

## Seguridad de cuentas (Rust)

El módulo `rust_services` (PyO3) NO usa blockchain. Su único propósito es:

- `register(password)` → devuelve `(encrypted_password, salt)` cifrando la
  contraseña con Argon2id + AES-256-GCM.
- `ok_password(encrypted, salt, plain)` → verifica una contraseña.
- `generate_recovery_code()` → código de 6 dígitos para recuperación.

## Cambio de contraseña (flujo de recuperación)

1. `generate_recovery_code(identification_number)` → genera un código único de
   6 dígitos, se guarda en Redis con TTL de 10 minutos (600 s).
2. `change_password(identification_number, code, new_password)` → valida el
   código (descartable: se elimina al primer uso válido), re-encripta la nueva
   contraseña con `rust_services.register()` y actualiza `S02USER`
   (`chashedpassword` + `csalt`).

## Redis

El sistema usa Redis para cachear permisos de usuarios y para los códigos de
recuperación de contraseña. Necesitas tener Redis corriendo:

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

## APIs GraphQL activas

Por el momento solo están expuestas las APIs de registro y sus relaciones:
- `user_account` (registro de usuario), `person` (personas/registro),
  `identification_type`, `account_provider`, `boundaries` (geo) y `auth`
  (login/logout/refresh).
- `password_recovery` (generar código + cambiar contraseña).

El resto de módulos (`role`, `questionnaire`, `dashboard`) permanecen en el
código pero desactivados del schema GraphQL (ver `graphql/schema/index.py`).
