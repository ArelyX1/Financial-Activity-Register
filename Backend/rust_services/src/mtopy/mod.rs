
use super::mcrypto;
pub mod validate_identity;

pub fn register(psswrd: &str) -> (Vec<u8>, String) {
    let usr_salt_obj = mcrypto::generate_random_salt();
    let usr_salt = usr_salt_obj.as_str();

    // 1. Derivar la llave (esto no es un PasswordHash, es una clave cruda)
    //    no debe ir a la DB
    let master_key = mcrypto::derive_key(psswrd, usr_salt);

    let psswrd_hash = mcrypto::encrypt_data(psswrd.as_bytes(), &master_key);

    (psswrd_hash, usr_salt_obj)
}

pub fn ok_password(encrypted_password: &[u8], salt: &str, plain_password: &str) -> bool {
    let key = mcrypto::derive_key(plain_password, salt);
    if let Ok(decrypted) = mcrypto::decrypt_data(encrypted_password, &key) {
        decrypted == plain_password.as_bytes()
    } else {
        false
    }
}

pub fn generate_recovery_code() -> String {
    mcrypto::generate_numeric_code(6)
}
