use crate::mcrypto;

pub fn crypto_conformance(plain_content: &[u8], encrypted_data: &[u8], master_pass: &[u8; 32]) -> bool {
    if let Ok(decrypted_target) = mcrypto::decrypt_data(encrypted_data, master_pass) {
        return plain_content == decrypted_target;
    }
    false
}