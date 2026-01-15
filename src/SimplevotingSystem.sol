// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is Ownable, AccessControl {
    // --- ROLES ---
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // --- WORKFLOW ---
    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        uint256 fundsReceived;
    }

    WorkflowStatus public workflowStatus;
    uint256 public voteStartTime;

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint256[] private candidateIds;

    // --- EVENTS ---
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event CandidateRegistered(uint256 id, string name);
    event Voted(address voter, uint256 candidateId);
    event FundReceived(address founder, uint256 candidateId, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);

    constructor() Ownable(msg.sender) {
        workflowStatus = WorkflowStatus.REGISTER_CANDIDATES;
        // On donne le rôle d'admin global au déployeur
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // --- ADMINISTRATION DU WORKFLOW ---

    function setWorkflowStatus(WorkflowStatus _newStatus) public onlyOwner {
        WorkflowStatus previousStatus = workflowStatus;
        workflowStatus = _newStatus;

        if (_newStatus == WorkflowStatus.VOTE) {
            voteStartTime = block.timestamp;
        }

        emit WorkflowStatusChange(previousStatus, _newStatus);
    }

    // --- GESTION DES CANDIDATS ---

    function addCandidate(string memory _name) public onlyOwner {
        require(workflowStatus == WorkflowStatus.REGISTER_CANDIDATES, "Candidates registration is not open");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");

        uint256 candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0, 0);
        candidateIds.push(candidateId);

        emit CandidateRegistered(candidateId, _name);
    }

    // --- FONCTIONNALITÉS FINANCIÈRES (FOUNDER & WITHDRAWER) ---

    function fundCandidate(uint256 _candidateId) public payable onlyRole(FOUNDER_ROLE) {
        require(workflowStatus != WorkflowStatus.COMPLETED, "Workflow is completed");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        require(msg.value > 0, "Amount must be greater than 0");

        candidates[_candidateId].fundsReceived += msg.value;
        emit FundReceived(msg.sender, _candidateId, msg.value);
    }

    function withdraw() public onlyRole(WITHDRAWER_ROLE) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Workflow is not completed yet");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool sent,) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");

        emit FundsWithdrawn(msg.sender, balance);
    }

    // --- VOTE ---

    function vote(uint256 _candidateId) public {
        require(workflowStatus == WorkflowStatus.VOTE, "Voting session is not open");
        require(block.timestamp >= voteStartTime + 1 hours, "Voting starts 1 hour after session opening");
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;

        emit Voted(msg.sender, _candidateId);
    }

    // --- VIEW FUNCTIONS ---

    function getTotalVotes(uint256 _candidateId) public view returns (uint256) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint256) {
        return candidateIds.length;
    }

    function getCandidate(uint256 _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }
}

