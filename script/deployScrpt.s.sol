// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;



import {Script} from "forge-std/Script.sol";
import {Bons} from "../src/sorceCode.sol";

contract Deploybons is Script {


    function run() external returns (Bons) {
        vm.startBroadcast();
        Bons bons = new Bons();
        vm.stopBroadcast();
        return bons;
    }
}