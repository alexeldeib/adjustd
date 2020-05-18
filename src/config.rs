use std::fs::File;
use std::io::prelude::*;
use std::io::{BufReader, Error, ErrorKind};
use std::path::Path;

use serde::{Deserialize, Serialize};

use super::sysctl::Sysctl;

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub struct Config {
    pub sysctls: Vec<Sysctl>,
}


impl Config {
    pub fn new(path: &Path) -> std::io::Result<Self> {
        let file = File::open(path)?;
        let mut buf_reader = BufReader::new(file);
        let mut contents = String::new();
        buf_reader.read_to_string(&mut contents)?;
        match serde_yaml::from_str(&contents) {
            Err(e) => Err(Error::new(ErrorKind::Other, e)),
            Ok(d) => Ok(d),
        }
    }
}
