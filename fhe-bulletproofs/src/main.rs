#![feature(test)]

mod tiny;
mod range_proof;
mod values;
mod signed_integer;
mod gadgets;
mod small;
mod utils;
mod medium;

use std::env;
use std::io::Error;
use std::process::ExitCode;
use tiny::main_tiny;
use crate::medium::main_medium;
use crate::small::main_small;


fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        println!("Usage: main {{tiny|small|medium}}");
        return ExitCode::FAILURE
    }
    let name = &args[1];
    match &name[..] {
        "tiny" => main_tiny(),
        "small" => main_small(),
        "medium" => main_medium(),
        x => {
            println!("Unknown setting `{x}'");
            return ExitCode::FAILURE
        }
    }
    ExitCode::SUCCESS
}