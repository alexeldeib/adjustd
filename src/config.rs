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
    pub fn new(path: &Path) -> eyre::Result<Self> {
        let is_dir = path.is_dir();
        println!("path: {:?}", &is_dir);
        let file = File::open(path)?;
        let mut buf_reader = BufReader::new(file);
        let mut contents = String::new();
        buf_reader.read_to_string(&mut contents)?;
        let config: Config = serde_yaml::from_str(&contents)?;
        Ok(config)
    }
}
