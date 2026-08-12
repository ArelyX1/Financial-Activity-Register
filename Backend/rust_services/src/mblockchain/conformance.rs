use sp_core::sr25519;
use sp_core::Pair;
use parity_scale_codec::Encode;

/// Estructura simplificada de lo que se firma en JAM para un servicio
#[derive(Encode)]
struct JamSignedPayload {
    service_id: u32,       // ID del servicio en JAM
    code_hash: [u8; 32],   // Hash del código Wasm que se ejecutará
    payload: Vec<u8>,      // Los datos reales de la transacción
    nonce: u64,
    genesis_hash: [u8; 32],
}

pub fn sign_ok(message: JamSignedPayload, signature_bytes: [u8; 64], public_key: sr25519::Public) -> bool {
    let signature = sr25519::Signature::from_raw(signature_bytes);
    
    // Encode the struct into bytes before verifying
    let encoded_message = message.encode(); 
    
    sr25519::Pair::verify(&signature, &encoded_message, &public_key)
}

// Ejemplo de para validar una action dentro de JAM
pub fn can_perform_action(user_roles: Vec<u32>, required_role_id: u32) -> bool {
    user_roles.contains(&required_role_id)
}