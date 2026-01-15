// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
import {VoteNFT} from "../src/VoteNFT.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;
    VoteNFT public voteNft;

    address public admin = makeAddr("admin");
    address public founder = makeAddr("founder");
    address public withdrawer = makeAddr("withdrawer");
    address public voter1 = makeAddr("voter1");
    address public voter2 = makeAddr("voter2");

    function setUp() public {
        vm.startPrank(admin);
        votingSystem = new SimpleVotingSystem();
        voteNft = votingSystem.voteNft();
        votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
        votingSystem.grantRole(votingSystem.WITHDRAWER_ROLE(), withdrawer);
        vm.stopPrank();

        vm.deal(founder, 100 ether);
        vm.deal(voter1, 1 ether);
        vm.deal(voter2, 1 ether);
    }

    function test_VoteMintsNFT() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(voter1);
        votingSystem.vote(1);

        assertEq(voteNft.balanceOf(voter1), 1);
        assertEq(votingSystem.getTotalVotes(1), 1);
    }

    function test_CannotVoteTwiceWithNFT() public {
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        vm.prank(voter1);
        votingSystem.vote(1);

        vm.prank(voter1);
        vm.expectRevert("You have already voted (NFT detected)");
        votingSystem.vote(1);
    }

    // --- NOUVEAU TEST POUR LE VAINQUEUR ---
    function test_GetWinner() public {
        // 1. Setup : 2 candidats
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // 2. Votes
        vm.prank(voter1);
        votingSystem.vote(1);

        // 3. Voir le vainqueur AVANT la fin (doit échouer)
        vm.expectRevert("Voting session not completed");
        votingSystem.getWinner();

        // 4. Clôture du vote
        vm.prank(admin);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        // 5. Vérification du vainqueur
        (string memory name, uint count) = votingSystem.getWinner();
        assertEq(name, "Alice");
        assertEq(count, 1);
    }
}