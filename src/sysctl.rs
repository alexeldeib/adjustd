use serde::{Deserialize, Serialize};

#[derive(Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Sysctl {
    pub key: String,
    pub value: String,
}

impl Sysctl {
    pub fn get(&self) -> anyhow::Result<String> {
        println!("got key: {:?}", &self.key);
        Ok(String::from("ok"))
    }
    
    pub fn set(&self) -> anyhow::Result<String> {
        println!("got key: {:?}, value: {:?}", &self.key, &self.value);
        Ok(String::from("ok"))
    }
}

