// Voting.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Voting is Ownable {  
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    mapping (address => Voter) public voters;
    mapping (address => uint[]) public proposalIds;
    Proposal[] public proposals;
    uint public winningProposalId;
    WorkflowStatus status;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);



    function RegisteringVotersStatus() public onlyOwner {
        status = WorkflowStatus.RegisteringVoters;
    }

    function ProposalsRegistrationStartedStatus() public onlyOwner {
        status = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function ProposalsRegistrationEndedStatus() public onlyOwner {
        status = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function VotingSessionStartedStatus() public onlyOwner {
        status = WorkflowStatus.VotingSessionStarted;
    }

    function VotingSessionEndedStatus() public onlyOwner {
        status = WorkflowStatus.VotingSessionEnded;
    }

    function VotesTalliedStatus() public onlyOwner {
        status = WorkflowStatus.VotesTallied;
    }




    function GetProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    function GetProposalIds(address _address) public view returns (uint[] memory) {
        return proposalIds[_address];
    }



    function whitelist(address voterAddress) public onlyOwner {
        require(!voters[voterAddress].isRegistered, "This address is already whitelisted !");
        require(voterAddress != address(0), "You cannot transfer to the address zero");
        require(status == WorkflowStatus.RegisteringVoters, "Status is wrong");
        voters[voterAddress] = Voter(true,false,0);
        emit VoterRegistered(voterAddress);
    }


    function RegisterProposal(address voterAddress, string memory description) public {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Status for registration is wrong");
        require(voters[voterAddress].isRegistered, "Address is not in withelist");
        proposals.push(Proposal(description, 0));
        uint proposalIndex = proposals.length-1;
        proposalIds[voterAddress].push(proposalIndex);
        emit ProposalRegistered(proposalIndex);
    }

    function VoteSession(address voterAddress, uint _proposalId) public {
        require(status == WorkflowStatus.VotingSessionStarted, "Status for voting is wrong");
        require(voters[voterAddress].isRegistered, "Address is not in withelist");
        require(!voters[voterAddress].hasVoted, "User has already voted");
        voters[voterAddress] = Voter(true,true,_proposalId);
        proposals[_proposalId].voteCount++; 
        emit Voted(voterAddress,_proposalId);
    }

    function TallyVote() public returns (uint) {
        require(status == WorkflowStatus.VotingSessionEnded, "Status for voting is wrong");
        uint arrayLength = proposals.length;
        uint voteMax;

        for (uint i=0; i < arrayLength; i++) {
            if (voteMax <= proposals[i].voteCount) {
                voteMax = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        return winningProposalId;
    }

    function WinningProposal(address _address) public view returns (Proposal memory){
        require(status == WorkflowStatus.VotesTallied, "Status for voting is wrong");
        require(voters[_address].isRegistered, "Address is not in withelist");
        return proposals[winningProposalId];
    }

}
