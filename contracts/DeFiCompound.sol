// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IPriceOracle.sol';
import './IComptroller.sol';
import './ICToken.sol';

contract DeFiCompound {

    // references to the Compotroller and PriceOracle
    IComptroller public comptroller;
    IPriceOracle public priceOracle;

    constructor(address _comptroller, address _priceOracle) {
        comptroller = IComptroller(_comptroller);
        priceOracle = IPriceOracle(_priceOracle);
    }

    /// @notice function to supply money collateral/lend money to protocol 
    /// @param _cToken the address of market to lend eg cDAI
    /// @param _amountUnderlying the amount of tokens to lend
    function supply(address _cToken, uint _amountUnderlying) external {
        ICToken cToken = ICToken(_cToken);
        address underlying = cToken.underlying();
        // approve underlying token to be spent by compound (cToken market)
        IERC20(underlying).approve(_cToken, _amountUnderlying);
        // give cTokens to lender
        uint success = cToken.mint(_amountUnderlying);
        require(success == 0, 'cToken minting failed -> details ErrorReporter.sol');
    }

    /// @notice function to redeem underlying asset supplied by sending back cToken
    /// @param _cToken the address of market eg cDAI
    /// @param _amountCToken the amount of cTokens to redeem
    function redeem(address _cToken, uint _amountCToken) external {
        ICToken cToken = ICToken(_cToken);
        // can use redeem() or redeemUnderlying() functions
        uint success = cToken.redeem(_amountCToken);
        require(success == 0, 'cToken minting failed -> details ErrorReporter.sol');
    }

    /// @notice function to enter a list of markets 
    /// @param _cToken the address of compound market e.g cDAI
    function enterMarket(address _cToken) external {
        address[] memory markets = new address[](1);
        markets[0] = _cToken; 
        uint[] memory results = comptroller.enterMarkets(markets);
        require(
            results[0] == 0, 
            'comptroller#enterMarket() failed. see Compound ErrorReporter.sol for details'
        ); 
    }

    /// @notice function to borrow from a specific cToken market
    /// @param _cToken the address of compound market e.g cDAI
    /// @param _borrowAmount the amount of the underlying to borrow
    function borrow(address _cToken, uint _borrowAmount) external {
        ICToken cToken = ICToken(_cToken);
        uint result = cToken.borrow(_borrowAmount);
        require(
            result == 0, 
            'cToken#borrow() failed. see Compound ErrorReporter.sol for details'
        ); 
    }
    
    /// @notice function to repay amount of underlying 
    /// @param _cToken the address of compound market e.g cDAI
    /// @param _underlyingAmount the amount of the underlying to repay
    function repayBorrow(address _cToken, uint _underlyingAmount) external {
        ICToken cToken = ICToken(_cToken);
        address underlyingAddress = cToken.underlying(); 
        // approve market to move underlying on your behalf
        IERC20(underlyingAddress).approve(_cToken, _underlyingAmount);
        uint result = cToken.repayBorrow(_underlyingAmount);
        require(
            result == 0, 
            'cToken#borrow() failed. see Compound ErrorReporter.sol for details'
        ); 
    }

    /// @notice function to get max amount you can borrow
    /// @param _cToken the address of compound market to borrow underlying e.g cDAI for DAI
    /// @return _amountMax the max number of tokens of underlying you can borrow from market
    function getMaxBorrow(address _cToken) external view returns(uint _amountMax) {
        (uint result, uint liquidity, uint shortfall) = comptroller.getAccountLiquidity(address(this));
        require(
            result == 0, 
            'comptroller#getAccountLiquidity() failed. see Compound ErrorReporter.sol for details'
        ); 
        require(shortfall == 0, 'account underwater');
        require(liquidity > 0, 'account does not have collateral');
        uint underlyingPrice = priceOracle.getUnderlyingPrice(_cToken);
        // return the max amount of underlying that you can borrow
        _amountMax = liquidity / underlyingPrice;
    }


}