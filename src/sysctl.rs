use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Sysctl {
    pub key: String,
    pub value: String,
}

impl Sysctl {
    pub fn get(&self) -> eyre::Result<String> {
        let result = Command::new("sysctl").arg("-n").arg(&self.key).output()?;

        let mut out = String::from_utf8(result.stdout)?;
        out.truncate(out.trim_end().len());

        Ok(out)
    }

    pub fn set(&self) -> eyre::Result<String> {
        let result = Command::new("sysctl")
            .arg("-w")
            .arg(format!("{}={}", &self.key, &self.value))
            .output()?;

        if !result.status.success() {
            let mut msg = String::from_utf8(result.stderr)?;
            msg.truncate(msg.trim_end().len());
            eyre::bail!(msg)
        }

        let mut out = String::from_utf8(result.stdout)?;
        out.truncate(out.trim_end().len());

        Ok(out)
    }
}
