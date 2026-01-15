// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;

    address public admin = makeAddr("admin");
    address public founder = makeAddr("founder");
    address public withdrawer = makeAddr("withdrawer");
    address public voter1 = makeAddr("voter1");
    address public voter2 = makeAddr("voter2");

    function setUp() public {
        // On déploie en tant qu'admin
        vm.startPrank(admin);
        votingSystem = new SimpleVotingSystem();

        // Attribution des rôles
        votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
        votingSystem.grantRole(votingSystem.WITHDRAWER_ROLE(), withdrawer);
        vm.stopPrank();

        // On donne de l'argent factice aux comptes pour les tests
        vm.deal(founder, 100 ether);
        vm.deal(voter1, 1 ether);
        vm.deal(voter2, 1 ether);
    }

    // Test du scénario complet (Workflow nominal)
    function test_FullScenario() public {
        // 1. Enregistrement des candidats (Admin)
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");

        // Changement de statut vers FOUND_CANDIDATES
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        vm.stopPrank();

        // 2. Financement d'un candidat (Founder)
        vm.startPrank(founder);
        votingSystem.fundCandidate{value: 5 ether}(1); // 5 ETH pour Alice
        vm.stopPrank();

        // Vérification
        SimpleVotingSystem.Candidate memory c1 = votingSystem.getCandidate(1);
        assertEq(c1.fundsReceived, 5 ether);

        // 3. Ouverture des votes
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);

        // 4. Tentative de vote immédiat (DOIT ECHOUER car < 1h)
        vm.startPrank(voter1);
        vm.expectRevert("Voting starts 1 hour after session opening");
        votingSystem.vote(1);
        vm.stopPrank();

        // On avance le temps de 1h et 1 seconde
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // 5. Vote valide
        vm.prank(voter1);
        votingSystem.vote(1);
        assertEq(votingSystem.getTotalVotes(1), 1);

        // 6. Clôture et Retrait des fonds
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        // Seul le withdrawer peut retirer
        vm.prank(withdrawer);
        uint256 balanceBefore = withdrawer.balance;
        votingSystem.withdraw(); // Doit récupérer les 5 ETH du contrat
        uint256 balanceAfter = withdrawer.balance;

        assertEq(balanceAfter - balanceBefore, 5 ether);
    }

    // Test de sécurité : Seul l'admin change le workflow
    function test_OnlyAdminCanChangeWorkflow() public {
        vm.prank(voter1);
        vm.expectRevert(); // Doit échouer car voter1 n'est pas owner
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
    }
}
