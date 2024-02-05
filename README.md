# Properties hevm

This repository contains implementation of several properties of the Ethereum Token Standards for formal verification using hevm as a tool.

- [ERC-20 Properties](https://github.com/0xRalts/properties-hevm/blob/main/PROPERTIES.md#erc-20-token-standard-properties)

## Installation

To run the tests you need to install the following dependencies:

- [foundry](https://github.com/foundry-rs/foundry#installation) (for compiling and easier managment of libs)
- [hevm](https://github.com/ethereum/hevm?tab=readme-ov-file#installation) (to formally verify our properties)

## Usage

Consider you are using this repository to test your ERC-20 implementation, you should do the following:

First, create your ERC-20 token under `src/contracts/ERC-20/`:

```Solidity
// Example ERC-20 Token for OpenZeppelin
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OpenZeppelinERC20 is ERC20 {
    constructor() ERC20("MyToken", "MTK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
```

Then you can simply set your token on `test/ERC20PropertiesTest.t.sol` (this is temporary while hevm solve an issue I submitted)

```Solidity
// Properties tests file
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OpenZeppelinERC20} from "src/contracts/ERC-20/OpenZeppelinERC20.sol";

contract ERC20PropertiesTest is Test {
    OpenZeppelinERC20 token; // <--- For now you can simply set your token here

    function setUp() public {
        token = new OpenZeppelinERC20(); // <--- Don't forget to correctly create it
    }

    // ERC-20 properties implementation below
```

Then you simply do

- `forge build` to compile your files
- `hevm test` to run your prove tests

### Example output for a successful test

```
Running 1 tests for test/ERC20PropertiesTest.t.sol:ERC20PropertiesTest
Exploring contract
Simplifying expression
Explored contract (36 branches)
Checking for reachability of 25 potential property violation(s)
[PASS] prove_transferSuccessReturnsTrue(address,address,uint256)
```

#### Example output for a fail test (it returns a counterexample)

```
Running 1 tests for test/ERC20PropertiesTest.t.sol:ERC20PropertiesTest
Exploring contract
Simplifying expression
Explored contract (6 branches)
Checking for reachability of 1 potential property violation(s)
[FAIL] proveFail_transferToZeroAddress(uint256,uint256)

Failure: proveFail_transferToZeroAddress(uint256,uint256)

  Counterexample:
  
    result:   Successful execution
    calldata: proveFail_transferToZeroAddress(115792089237316195423570985008687907853269984665640564037096400766478308081662,1048576)
```

## How to Contribute?

**Important:** always open an issue before opening a Pull Request to discuss about what you want to include in this repo

To contribute you can consider the following scenarios:

- Propose new properties for an already implemented token standard (e.g. ERC-20)
- Include properties implementation for new  token standards
- Optimization or change of already implemented properties
- Documentation

Please make sure that if you are implementing new properties it succeeds for OpenZeppelin's implementation as it's our baseline for this repo.

## License

[MIT](https://github.com/0xRalts/properties-hevm/blob/main/LICENSE)
