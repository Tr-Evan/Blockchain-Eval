// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract DeploySimpleVotingSystem is Script {
    function run() external {
        // 1. Récupérer la clé privée
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 2. DÉMARRER la transaction (C'est cette ligne qui manquait !)
        vm.startBroadcast(deployerPrivateKey);

        // 3. Déployer le contrat
        new SimpleVotingSystem();

        // 4. ARRÊTER la transaction
        vm.stopBroadcast();
    }
}