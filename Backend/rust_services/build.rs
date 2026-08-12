use std::{env, fs, io, path::PathBuf};

fn main() -> io::Result<()> {
    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let symlink_path = out_dir.join("libpython3.14.so");
    let target = PathBuf::from("/usr/lib/x86_64-linux-gnu/libpython3.14.so.1");

    if !symlink_path.exists() {
        let _ = fs::remove_file(&symlink_path);
        std::os::unix::fs::symlink(&target, &symlink_path)?;
    }

    println!("cargo:rustc-link-search=native={}", out_dir.display());
    Ok(())
}
