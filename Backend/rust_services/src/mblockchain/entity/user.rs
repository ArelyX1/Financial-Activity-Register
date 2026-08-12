use parity_scale_codec::{Encode, Decode};
use sp_core::{sr25519, Pair, ByteArray};

use serde::Deserialize;
use std::collections::HashMap;
use std::fs;

use crate::mcrypto;


// Estructura para el estado que JAM almacenará
#[derive(Encode, Decode)]
pub struct UserAccount {
    pub roles: Vec<u32>,
    pub nonce: u64,
}


#[derive(Deserialize)]
pub struct RoleConfig {
    pub roles: HashMap<String, u32>,
}

impl RoleConfig {
    // Carga el archivo JSON
    pub fn load() -> Self {
        let data = fs::read_to_string("roles.json").expect("No se pudo leer el config de roles");
        let roles: HashMap<String, u32> = serde_json::from_str(&data).expect("Error al parsear JSON");
        Self { roles }
    }

    pub fn get_id(&self, name: &str) -> u32 {
        *self.roles.get(name).unwrap_or(&2) // Por defecto User (2) si no existe
    }

    pub fn is_valid_role(&self, role_id: u32) -> bool {
        self.roles.values().any(|&id| id == role_id)
    }

    pub fn is_superior_role(&self, role_id: u32, superior_role: u32) -> bool {
        role_id < superior_role
    }   
}

pub fn get_phrase_from_wallet(wallet: Vec<u8>, password: &str, salt: &str) -> String {
    let wallet_decrypted = mcrypto::decrypt_data(&wallet, &mcrypto::derive_key(password, salt));
    String::from_utf8(wallet_decrypted.unwrap()).expect("Invalid UTF-8")

}

pub fn assign_role_in_jam(
    target_wallet: sr25519::Public,
    new_role: Vec<u32>,
    nonce: u64,
    admin_pair: &sr25519::Pair
) -> Vec<u8> {

    

    
    let payload = (target_wallet, new_role, nonce).encode();
    
    // 2. Firmamos el conjunto completo
    let signature = admin_pair.sign(&payload);
    
    // 3. Empaquetamos todo para el servicio de JAM
    [payload, signature.to_raw_vec()].concat()
}


