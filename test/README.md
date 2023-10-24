# Tests for circuits

This folder contains a collection of unit tests for the circuits.

The files `*_test.circom` contain the templates with the tests.

The script `test.sh` compiles and runs the tests.

## Usage

The script `test.sh` receives as an argument the name of the file with the tests without the ending `_test.circom`.

For instance:

```
./test.sh array_access
```