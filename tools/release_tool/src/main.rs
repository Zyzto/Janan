mod summary;

use crate::summary::Summary;
use anyhow::{bail, Context, Result};
use regex::Regex;
use std::io::Write;
use std::{env, fs, io, path::PathBuf};

// TODO:
// - changelog management
// - weblate integration
// - git commits / PR-ing
// - release tagging / github publishing

fn main() -> Result<()>{
    let mut summary = Summary::default();

    summary.root = git_dir()
        .context("Couldn't find repository root")?;
    println!("Using repository at {:?}", summary.root);

    let version = get_version(&summary.root)
        .context("Couldn't read current app version")?;
    println!("Current app version is {} ({})", &version.0, &version.1);

    let (yy, month) = current_yy_month().context("Couldn't determine current year/month")?;
    let next_name = next_calver(&version.0, yy, month)?;
    let next_code = version.1 + 1;
    let bump_version = prompt_bool(
        format!(
            "Bump app version ({}+{} -> {}+{})?",
            version.0, version.1, next_name, next_code
        )
        .as_str(),
        Some(true),
    )?;
    if bump_version {
        summary.new_version_line = Some(format!("version: {next_name}+{next_code}"));
    }

    summary.update_flutter = prompt_bool("Update flutter?", Some(true))?;
    summary.update_dependencies = prompt_bool("Update dependencies?", Some(true))?;
    summary.run_tests = prompt_bool("Run tests?", Some(false))?;
    summary.build = prompt_bool("Build app?", Some(true))?;

    summary.print();
    summary.apply();

    Ok(())
}

pub fn prompt_bool(prompt: &str, default: Option<bool>) -> Result<bool> {
    let y = if default.is_some_and(|d| d) { "Y" } else { "y" };
    let n = if default.is_some_and(|d| !d) { "N" } else { "n" };
    print!("{} [{}/{}] ", prompt, y, n);
    io::stdout().flush()?;

    let mut buffer = String::new();
    io::stdin().read_line(&mut buffer)?;
    buffer = buffer.trim().to_string();

    if buffer.eq_ignore_ascii_case("y") {
        Ok(true)
    } else if buffer.eq_ignore_ascii_case("n") {
        Ok(false)
    } else if let Some(default) = default {
        Ok(default)
    } else {
        bail!("Invalid input '{buffer}', please provide either 'y' or 'n'");
    }
}


/// Get the closest ancestor dir that contains a .git folder in order to find the repository root.
pub fn git_dir() -> Result<PathBuf> {
    let mut dir = env::current_dir()
        .context("no CWD")?;

    loop {
        // find a child dir with matching name
        let child = dir.read_dir()?
            .find(|e| e.is_ok() && e.as_ref().unwrap().file_name()
                    .eq_ignore_ascii_case(".git"));
        if let Some(Ok(_)) = child {
            return Ok(dir);
        }
        if let Some(parent) = dir.parent() {
            dir = parent.to_path_buf();
        } else {
            bail!("Reached fs root")
        }
    }
}

/// Calendar version `YY.0M.MICRO` for this UTC year/month.
///
/// Same month increments `MICRO`. A new month (or a non-CalVer name) starts at `0`.
pub fn next_calver(current_name: &str, yy: u32, month: u32) -> Result<String> {
    if !(1..=12).contains(&month) {
        bail!("Month must be 1-12, got {month}");
    }
    if yy > 99 {
        bail!("Year must be two digits, got {yy}");
    }

    let regex = Regex::new(r"^(\d{2})\.(\d{1,2})\.(\d+)$")?;
    let next_micro = regex
        .captures(current_name)
        .and_then(|caps| {
            let cur_yy: u32 = caps.get(1)?.as_str().parse().ok()?;
            let cur_month: u32 = caps.get(2)?.as_str().parse().ok()?;
            let cur_micro: u32 = caps.get(3)?.as_str().parse().ok()?;
            (cur_yy == yy && cur_month == month).then_some(cur_micro + 1)
        })
        .unwrap_or(0);

    Ok(format!("{yy:02}.{month:02}.{next_micro}"))
}

/// Two-digit year and month from `date` (UTC).
fn current_yy_month() -> Result<(u32, u32)> {
    let output = std::process::Command::new("date")
        .args(["-u", "+%y-%m"])
        .output()
        .context("Failed to run date")?;
    if !output.status.success() {
        bail!("date failed: {}", String::from_utf8_lossy(&output.stderr));
    }
    let text = String::from_utf8(output.stdout).context("date output is not UTF-8")?;
    let (yy, month) = text
        .trim()
        .split_once('-')
        .context(format!("Unexpected date output: '{}'", text.trim()))?;
    Ok((
        yy.parse().context("Couldn't parse year")?,
        month.parse().context("Couldn't parse month")?,
    ))
}

/// Read current app version name and number from pubspec in `$root/pubspec.yaml`.
///
/// Example: ("26.08.0", 58)
pub fn get_version(root: &PathBuf) -> Result<(String, usize)> {
    let pubspec = root.join("pubspec.yaml");
    let pubspec = fs::read_to_string(pubspec).context("Couldn't find pubspec.yaml")?;

    // Matches the `version: ...+..` line of the file, capturing the name in 1 and the number in 2.
    let regex =  Regex::new(r"version:\s*([0-9.]*)\+([0-9]*)")?;
    let pubspec = regex.captures(&pubspec)
        .context("Can't find app version declaration in pubspec.yaml")?;
    
    let version_name = pubspec.get(1).expect("implied by regex");
    let version_num = pubspec.get(2).expect("implied by regex");
    let parsed_version_num = version_num.as_str().parse::<usize>()
        .context(format!("Extracted version string is: '{}'", version_num.as_str()))?;
    Ok((version_name.as_str().to_string(), parsed_version_num))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn increments_micro_in_same_month() {
        assert_eq!(next_calver("26.08.0", 26, 8).unwrap(), "26.08.1");
        assert_eq!(next_calver("26.08.9", 26, 8).unwrap(), "26.08.10");
    }

    #[test]
    fn resets_on_new_month() {
        assert_eq!(next_calver("26.07.3", 26, 8).unwrap(), "26.08.0");
        assert_eq!(next_calver("25.12.4", 26, 1).unwrap(), "26.01.0");
    }

    #[test]
    fn starts_fresh_from_semver() {
        assert_eq!(next_calver("1.8.15", 26, 8).unwrap(), "26.08.0");
    }
}