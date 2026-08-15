mod mtopy;
mod mcrypto;

fn main() {
    let (encrypted, salt) = mtopy::register("Admin123");
    let ok = mtopy::ok_password(&encrypted, &salt, "Admin123");
    let code = mtopy::generate_recovery_code();
    println!("password ok: {:?}", ok);
    println!("recovery code: {}", code);
}
