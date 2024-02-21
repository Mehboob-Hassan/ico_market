// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract icoProject is ERC20 {
    address payable public  owner;
    uint256 public PRICE_IN_CENTS; // Initial price Cents
    uint256 public priceIncreaseRate; // Rate at which the price increases over time (in wei per second)
    uint256 public lastPriceUpdateTime;
    uint256 public tokenPool; // Total tokens available for purchase


    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _initialPrice,
        uint256 _priceIncreaseRate
    ) ERC20(_name, _symbol) {
        owner = payable (msg.sender);
        _mint(msg.sender, _initialSupply * 10 ** uint256(decimals())); // Mint tokens to contract
        tokenPool = _initialSupply * 10 ** uint256(decimals()); // Set token pool
        PRICE_IN_CENTS = _initialPrice;
        priceIncreaseRate = _priceIncreaseRate;
        lastPriceUpdateTime = block.timestamp;
    }


    function mint(uint256 _amount) external  {
        require(msg.sender == owner, "Only owner can mint tokens");
        _mint(msg.sender, _amount * 10 ** uint256(decimals()));
        tokenPool = tokenPool + _amount * 10 ** uint256(decimals());
    }

    function buyTokens(uint256 _amount) external payable {
        uint256 totalPrice = getCurrentPrice() * _amount;
        bool sent = payable(owner).send((totalPrice *  10 ** 16));
        require(sent, "Could not pay amount");
        require(_amount <= tokenPool, "Not enough tokens available for purchase");
        _approve(owner, msg.sender, _amount);
        transferFrom(owner, msg.sender, _amount); // Transfer tokens from contract to buyer
        tokenPool = tokenPool-_amount; // Update token pool
    }

    function transferToken(address recipient, uint256 amount) public  returns (bool) {
        require(msg.sender == owner, "Only owner can transfer token");
        transfer(recipient,  amount * 10 ** uint256(decimals()));
        tokenPool = tokenPool-amount; // Update token pool
        return true;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 timePassed = (block.timestamp - lastPriceUpdateTime) / 3600; // Convert seconds to hours
        uint256 currentPrice = PRICE_IN_CENTS + (timePassed * priceIncreaseRate);
        return currentPrice;
    }

    function updatePriceIncreaseRate(uint256 _newRate) external {
        require(msg.sender == owner, "Only owner can update price increase rate");
        priceIncreaseRate = _newRate;
        lastPriceUpdateTime = block.timestamp;
    }
}
