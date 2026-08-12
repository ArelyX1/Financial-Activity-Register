
use argon2::password_hash;
use sp_core::Pair;
use sp_core::sr25519;
use sp_core::crypto::Ss58Codec;

use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
pub mod validate_identity;
use parity_scale_codec::Encode;

use super::mblockchain;
use super::mcrypto;

pub fn register(psswrd: &str) -> (Vec<u8>, Vec<u8>, String, String) {
    println!("Registering user...");

    let usr_salt_obj = mcrypto::generate_random_salt(); 
    let usr_salt = usr_salt_obj.as_str(); // Ahora la referencia es válida mientras usr_salt_obj exista

    
    // 1. Derivar la llave (esto no es un PasswordHash, es una clave cruda)l
    // no debe ir a la DB
    let master_key = mcrypto::derive_key(psswrd, usr_salt);
    //println!("Master key: {:?}", master_key);
    
    let psswrd_hash = mcrypto::encrypt_data(psswrd.as_bytes(), &master_key);
    //println!("Password hash: {:?}", psswrd_hash);
    let decrypted_bytes = mcrypto::decrypt_data(&psswrd_hash, &master_key).unwrap();
    //println!("original password: {}", String::from_utf8(decrypted_bytes).expect("Invalid UTF-8"));
    let is_valid = validate_identity::crypto_conformance(&psswrd.as_bytes(), &psswrd_hash, &master_key);
    //println!("Is valid psswd: {}", is_valid);

    let wallet_info = mblockchain::wallet_gen::gen_wallet();

    let pair = wallet_info.0;
    let mnemonic_phrase = wallet_info.1;
    let mnemonic_phrase_bytes = mnemonic_phrase.as_bytes();
    let seed = wallet_info.2;
    let pair_bytes = pair.to_raw_vec();

    let encrypted_seed = mcrypto::encrypt_data(&seed, &master_key);
    let encrypted_pair = mcrypto::encrypt_data(&pair_bytes, &master_key);
    let encrypted_phrase = mcrypto::encrypt_data(mnemonic_phrase_bytes, &master_key);

    //let is_valid = validate_identity::crypto_conformance(&mnemonic_phrase_bytes, &encrypted_phrase, &master_key);
    //println!("Encrypted phrase: {:?}", encrypted_phrase);
    //println!("Decrypted phrase: {:?}", mcrypto::decrypt_data(&encrypted_phrase, &master_key).unwrap());
    //println!("Original phrase: {:?}", mnemonic_phrase);
    //println!("Is same: {}", is_valid);
    let public_key = pair.public().to_ss58check();
    (psswrd_hash, encrypted_phrase, usr_salt_obj, public_key)
}


pub fn ok_password(encrypted_password: &[u8], salt: &str, plain_password: &str) -> bool {
    let key = mcrypto::derive_key(plain_password, salt);
    if let Ok(decrypted) = mcrypto::decrypt_data(encrypted_password, &key) {
        decrypted == plain_password.as_bytes()
    } else {
        false
    }
}

pub fn assign_role (target_wallet: &[u8], key: &[u8; 32], new_role: Vec<u32>, nonce: u64, pair: &[u8]) -> Vec<u8> {
    let target_wallet_bytes = mcrypto::decrypt_data(target_wallet, key).expect("Failed to decrypt target wallet");
    let pair_bytes = mcrypto::decrypt_data(pair, key).expect("Failed to decrypt pair");
    let target_wallet_typed = sr25519::Public::from_raw(target_wallet_bytes.try_into().expect("Invalid wallet len"));
    let pair_typed = sr25519::Pair::from_seed_slice(&pair_bytes).expect("Invalid seed");
    
    mblockchain::entity::user::assign_role_in_jam(target_wallet_typed, new_role, nonce, &pair_typed)
}







