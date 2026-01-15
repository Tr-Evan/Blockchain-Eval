// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract DeploySimpleVotingSystem is Script {
    function run() external {
        // Récupération de la clé privée depuis le fichier .env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Début de la transaction (tout ce qui suit est envoyé on-chain)
        vm.startBroadcast(deployerPrivateKey);

        // Déploiement du contrat
        SimpleVotingSystem votingSystem = new SimpleVotingSystem();

        vm.stopBroadcast();
    }
}