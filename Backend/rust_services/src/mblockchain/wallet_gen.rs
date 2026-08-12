use sp_core::{sr25519, Pair};

pub fn gen_wallet() -> (sr25519::Pair, String, [u8; 32]) {
    sr25519::Pair::generate_with_phrase(None)
}

pub fn recover_wallet_from_phrase(phrase: &str) -> (sr25519::Pair, String, [u8; 32]) {
    // from_phrase devuelve Result<(Pair, Seed), Error>
    let (pair, seed) = sr25519::Pair::from_phrase(phrase, None)
        .expect("Error recuperando wallet desde frase");
    
    (pair, phrase.to_string(), seed)
}

//pub fn recover_wallet_from_seed(seed: &[u8; 32]) -> sr25519::Pair {
//    sr25519::Pair::from_seed(seed)
//}

//pub fn recover_wallet_from_pair(pair_bytes: &[u8]) -> sr25519::Pair {
//    sr25519::Pair::from_seed_slice(pair_bytes).expect("Error recuperando wallet desde par")
//}
