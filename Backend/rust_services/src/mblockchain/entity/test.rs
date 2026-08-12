#[cfg(test)]
mod tests {
    use super::*;
    use sp_core::{sr25519, Pair};

    #[test]
    fn test_assign_role_signature_is_valid() {
        // 1. Creamos un Admin y un Usuario de prueba
        let (admin_pair, _) = sr25519::Pair::generate();
        let (user_pair, _) = sr25519::Pair::generate();
        let target_wallet = user_pair.public();
        
        let new_role = vec![1, 2, 3];
        let nonce = 1;

        // 2. Ejecutamos tu función
        let result_packet = assign_role_in_jam(target_wallet, new_role.clone(), nonce, &admin_pair);

        // 3. LA PRUEBA DE FUEGO: ¿Podemos verificarlo?
        // Separamos el payload de la firma (la firma sr25519 siempre son los últimos 64 bytes)
        let signature_offset = result_packet.len() - 64;
        let payload = &result_packet[..signature_offset];
        let signature_bytes = &result_packet[signature_offset..];
        
        let signature = sr25519::Signature::from_raw(signature_bytes.try_into().unwrap());

        // 4. Verificación criptográfica
        let is_valid = sr25519::Pair::verify(&signature, payload, &admin_pair.public());

        assert!(is_valid, "La firma generada por assign_role_in_jam no es válida");
        println!("✅ ¡La firma es auténtica y el paquete es íntegro!");
    }
}