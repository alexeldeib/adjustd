mod config;
mod sysctl;

fn main() -> anyhow::Result<()> {
    let mut wd = std::env::current_exe()?;
    wd.push("../../../data/config.yaml");

    println!("path: {:?}", wd);

    let config = config::Config::new(&wd)?;

    println!("config: {:?}", config);

    for sysctl in config.sysctls {
        let old = sysctl.get();
        let new = sysctl.set();
        println!(
            "found sysctl, key: {:?}, value: {:?}",
            sysctl.key, sysctl.value
        );
    }

    Ok(())
}
