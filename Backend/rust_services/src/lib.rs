use pyo3::prelude::*;

pub mod mcrypto;
pub mod mtopy;
pub mod mblockchain;

#[pyfunction]
fn register(password: String) -> PyResult<(Vec<u8>, Vec<u8>, String, String)> {
    Ok(mtopy::register(&password))
}

#[pyfunction]
fn ok_password(encrypted_password: Vec<u8>, salt: String, plain_password: String) -> PyResult<bool> {
    Ok(mtopy::ok_password(&encrypted_password, &salt, &plain_password))
}

#[pymodule]
fn rust_services(_py: Python, m: &Bound<PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(register, m)?)?;
    m.add_function(wrap_pyfunction!(ok_password, m)?)?;
    Ok(())
}
