use std::env;
use std::process::ExitCode;

use fhe_bulletproofs::tiny::main_tiny;
use fhe_bulletproofs::medium::main_medium;
use fhe_bulletproofs::small::main_small;
use fhe_bulletproofs::secure_aggregation::main_secure_aggregation;

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        println!("Usage: main {{tiny|small|medium}}");
        return ExitCode::FAILURE;
    }
    let name = &args[1];
    match &name[..] {
        "tiny" => main_tiny(),
        "small" => main_small(),
        "medium" => main_medium(),
        "secure-aggregation" => main_secure_aggregation(),
        x => {
            println!("Unknown setting `{x}'");
            return ExitCode::FAILURE;
        }
    }
    ExitCode::SUCCESS
}