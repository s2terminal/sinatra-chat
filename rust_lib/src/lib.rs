extern crate libc;
use libc::*;
use std::ffi::{CStr, CString};

#[no_mangle]
pub extern fn add_suffix(s: *const c_char) -> CString {
    let not_c_s = unsafe { CStr::from_ptr(s) }.to_str().unwrap();
    let not_c_message = format!("{}も", not_c_s);
    CString::new(not_c_message).unwrap()
}
