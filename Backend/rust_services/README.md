# rust_services

Módulo criptográfico en Rust expuesto a Python vía PyO3. NO usa blockchain:
se encarga únicamente de cifrar contraseñas y de generar los códigos de
recuperación para el cambio de contraseña.

## Funciones expuestas a Python

```python
import rust_services

# (1) Registrar/encriptar una contraseña.
# Devuelve (encrypted_password: bytes, salt: str)
enc_pwd, salt = rust_services.register("mi_password")

# (2) Verificar una contraseña contra la cifrada almacenada.
ok = rust_services.ok_password(enc_pwd, salt, "mi_password")

# (3) Generar código de recuperación de 6 dígitos (descartable, TTL 10 min).
code = rust_services.generate_recovery_code()
```

## Compilar

```bash
cargo build --release
# Produce: target/release/librust_services.so
```

El `.so` se copia al backend Python y se importa como `rust_services`.

## Pipeline criptográfico

1. `generate_random_salt()` → 16 bytes aleatorios (hex de 32 chars).
2. `derive_key(password, salt)` → Argon2id → clave maestra de 32 bytes.
3. `encrypt_data(password_bytes, key)` → AES-256-GCM con nonce aleatorio de
   12 bytes; formato final `[nonce(12) || ciphertext(N) || tag(16)]`.

`ok_password` re-deriva la clave con el salt almacenado, descifra y compara.

## Códigos de recuperación

`generate_recovery_code()` genera un código numérico de 6 dígitos usando el
CSPRNG del sistema. El backend lo almacena en Redis con TTL de 10 minutos y lo
elimina al primer uso (descartable).
