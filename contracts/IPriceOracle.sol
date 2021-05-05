// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IPriceOracle {
    function getUnderlyingPrice(address asset) external view returns (uint);
}