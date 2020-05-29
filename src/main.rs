use std::path::Path;

mod config;
mod sysctl;

fn main() -> eyre::Result<()> {
    let wd = Path::new("./data/config.yaml");

    println!("path: {:?}", wd);

    let config = config::Config::new(&wd)?;

    println!("config: {:?}", config);

    for sysctl in config.sysctls {
        let old = sysctl.get()?;
        // let new = sysctl.set()?;
        println!("found sysctl, key: {:?}, value: {:?}", sysctl.key, old);
        // println!("found sysctl, key: {:?}, value: {:?}", sysctl.key, new);
    }

    Ok(())
}
