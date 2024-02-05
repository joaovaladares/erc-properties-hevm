// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OpenZeppelinERC20 is ERC20 {
    constructor() ERC20("MyToken", "MTK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}