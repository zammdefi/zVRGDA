// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Tester} from "../src/ERC6909VRGDALinear.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract ERC6909VRGDALinearTest is Test {
    ERC6909VRGDALinear internal vrgda;

    function setUp() public payable {
        // vm.createSelectFork(vm.rpcUrl('main')); // Ethereum mainnet fork.
        // vm.createSelectFork(vm.rpcUrl('base')); // Base OptimismL2 fork.
        // vm.createSelectFork(vm.rpcUrl('poly')); // Polygon network fork.
        // vm.createSelectFork(vm.rpcUrl('opti')); // Optimism EthL2 fork.
        // vm.createSelectFork(vm.rpcUrl('arbi')); // Arbitrum EthL2 fork.
        //tester = new ERC6909VRGDALinear();
    }
}
