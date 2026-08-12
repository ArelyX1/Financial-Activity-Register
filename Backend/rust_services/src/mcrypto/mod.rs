use argon2::{
    password_hash::{SaltString},
    Argon2, PasswordHasher
};
use aes_gcm::{Aes256Gcm, aead::{KeyInit, Aead}, Nonce};
use rand::{RngExt, rng};


pub fn derive_key(master_password: &str, salt: &str) -> [u8; 32] {
    let config = Argon2::default();
    let mut key = [0u8; 32];
    
    let salt_bytes = salt.as_bytes();

    config.hash_password_into(master_password.as_bytes(), salt_bytes, &mut key)
        .expect("Error derivando clave");
    
    key
}

pub fn encrypt_data(content: &[u8], master_pass: &[u8; 32]) -> Vec<u8> {
    let cipher = Aes256Gcm::new(master_pass.into());

    let mut nonce_bytes = [0u8; 12];
    rng().fill(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    let ciphertext = cipher.encrypt(nonce, content).expect("Cifrado fallido");

    [nonce_bytes.as_slice(), &ciphertext].concat()
}

pub fn decrypt_data(ciphertext: &[u8], key: &[u8; 32]) -> Result<Vec<u8>, aes_gcm::Error> {
    let cipher = Aes256Gcm::new(key.into());

    if ciphertext.len() < 12 {
        return Err(aes_gcm::Error);
    }

    let (nonce_bytes, actual_ciphertext) = ciphertext.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);

    cipher.decrypt(nonce, actual_ciphertext)
}

pub fn generate_random_salt() -> String {
    let mut salt_bytes = [0u8; 16];
    // Usamos rng() aquí también para consistencia
    rng().fill(&mut salt_bytes);
    hex::encode(salt_bytes)
}

pub fn decrypt_to_string(vec_data: Vec<u8>) -> String {
    String::from_utf8(vec_data).unwrap_or_else(|_| "Error converting to string".into())
}
