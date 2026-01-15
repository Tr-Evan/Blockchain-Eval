// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
// Import du nouveau contrat NFT
import {VoteNFT} from "./VoteNFT.sol";

contract SimpleVotingSystem is Ownable, AccessControl {
    
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        uint fundsReceived;
    }

    WorkflowStatus public workflowStatus;
    uint public voteStartTime;
    
    // Variable pour stocker le contrat NFT
    VoteNFT public voteNft;

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event CandidateRegistered(uint id, string name);
    event Voted(address voter, uint candidateId);
    event FundReceived(address founder, uint candidateId, uint amount);
    event FundsWithdrawn(address withdrawer, uint amount);

    constructor() Ownable(msg.sender) {
        workflowStatus = WorkflowStatus.REGISTER_CANDIDATES;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // DÉPLOIEMENT AUTOMATIQUE DU NFT
        // Le VotingSystem crée le contrat NFT et en devient le propriétaire
        voteNft = new VoteNFT(address(this));
    }

    function setWorkflowStatus(WorkflowStatus _newStatus) public onlyOwner {
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _newStatus;
        
        if (_newStatus == WorkflowStatus.VOTE) {
            voteStartTime = block.timestamp;
        }

        emit WorkflowStatusChange(previousStatus, _newStatus);
    }

    function addCandidate(string memory _name) public onlyOwner {
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Candidates registration is not open");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");

        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0, 0);
        candidateIds.push(candidateId);
        
        emit CandidateRegistered(candidateId, _name);
    }

    function fundCandidate(uint _candidateId) public payable onlyRole(FOUNDER_ROLE) {
        require(workflowStatus != WorkflowStatus.COMPLETED, "Workflow is completed");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(msg.value > 0, "Amount must be greater than 0");

        candidates[_candidateId].fundsReceived += msg.value;
        emit FundReceived(msg.sender, _candidateId, msg.value);
    }

    function withdraw() public onlyRole(WITHDRAWER_ROLE) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Workflow is not completed yet");
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");

        emit FundsWithdrawn(msg.sender, balance);
    }

    function vote(uint _candidateId) public {
        require(workflowStatus == WorkflowStatus.VOTE, "Voting session is not open");
        require(block.timestamp >= voteStartTime + 1 hours, "Voting starts 1 hour after session opening");
        
        // VÉRIFICATION VIA LE NFT (Consigne 7)
        require(voteNft.balanceOf(msg.sender) == 0, "You have already voted (NFT detected)");
        
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
        
        // DISTRIBUTION DU NFT AU VOTANT
        voteNft.mint(msg.sender);
        
        emit Voted(msg.sender, _candidateId);
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }
}