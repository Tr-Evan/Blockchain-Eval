// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
import {VoteNFT} from "../src/VoteNFT.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem public votingSystem;
    VoteNFT public voteNft; // On récupérera l'instance du NFT ici

    address public admin = makeAddr("admin");
    address public founder = makeAddr("founder");
    address public withdrawer = makeAddr("withdrawer");
    address public voter1 = makeAddr("voter1");

    function setUp() public {
        vm.startPrank(admin);
        votingSystem = new SimpleVotingSystem();
        
        // On récupère l'adresse du NFT créé par le VotingSystem
        voteNft = votingSystem.voteNft();

        votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
        votingSystem.grantRole(votingSystem.WITHDRAWER_ROLE(), withdrawer);
        vm.stopPrank();

        vm.deal(founder, 100 ether);
        vm.deal(voter1, 1 ether);
    }

    function test_VoteMintsNFT() public {
        // Setup Workflow
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // Vérif avant vote : pas de NFT
        assertEq(voteNft.balanceOf(voter1), 0);

        // Vote
        vm.prank(voter1);
        votingSystem.vote(1);

        // Vérif après vote : 1 NFT reçu
        assertEq(voteNft.balanceOf(voter1), 1);
        assertEq(votingSystem.getTotalVotes(1), 1);
    }

    function test_CannotVoteTwiceWithNFT() public {
        // Setup
        vm.startPrank(admin);
        votingSystem.addCandidate("Alice");
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();
        vm.warp(block.timestamp + 1 hours + 1 seconds);

        // Premier vote
        vm.prank(voter1);
        votingSystem.vote(1);

        // Deuxième tentative
        vm.prank(voter1);
        vm.expectRevert("You have already voted (NFT detected)");
        votingSystem.vote(1);
    }
}