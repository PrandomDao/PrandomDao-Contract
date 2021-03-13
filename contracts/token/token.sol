// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    address public minter;

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol) 
    {

    }

    // mint with max supply
    function mint(address _to, uint256 _amount) public onlyMinter returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function setMinter(address _newMinter) external onlyOwner {
        require(minter == address(0), "has set up");
        require(_newMinter != address(0), "is zero address");
        minter = _newMinter;
    }
    // modifier for mint function
    modifier onlyMinter() {
        require(msg.sender == minter, "caller is not the minter");
        _;
    }
}
