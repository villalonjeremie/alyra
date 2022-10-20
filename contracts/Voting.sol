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
        VotesTallieds
    }

    mapping (address => Voter) public voters;
    address[] arrayAddress;
    Proposal[] public proposals;

    uint public winningProposalId;
    WorkflowStatus public status;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voterAddress, uint proposalId);

    /**
    * @dev Change status
    * @param _newstatus new status
    */
    function changeStatus(WorkflowStatus _newstatus) public onlyOwner {
        require(uint(_newstatus) == uint(status) + 1, "The current status is wrong");
        
        emit WorkflowStatusChange(status, _newstatus);
        
        status = _newstatus;
    }

    /** 
    * @dev Insert address in whitelist
    * @param _voterAddress address' voter
    */
    function Whitelist(address _voterAddress) external onlyOwner {
        require(!voters[_voterAddress].isRegistered, "This address is already whitelisted !");
        require(_voterAddress != address(0), "You cannot transfer to the address zero");
        require(status == WorkflowStatus.RegisteringVoters, "Status is wrong");

        voters[_voterAddress].isRegistered = true;
        arrayAddress.push(_voterAddress);

        emit VoterRegistered(_voterAddress);
    }

    /** 
    * @dev Register Proposal in BC
    * @param _voterAddress address' voter
    * @param _description content of proposal
    */
    function RegisterProposal(address _voterAddress, string calldata _description) external {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Status for registration is wrong");
        require(_voterAddress != address(0), "You cannot transfer to the address zero");
        require(voters[_voterAddress].isRegistered, "Address is not in withelist");

        proposals.push(Proposal(_description, 0));
        uint proposalIndex = proposals.length-1;

        emit ProposalRegistered(proposalIndex);
    }

    /** 
    * @dev Vote by address and proposalId
    * @param _voterAddress address' voter
    * @param _proposalId proposalId
    */
    function VoteSession(address _voterAddress, uint _proposalId) external {
        require(status == WorkflowStatus.VotingSessionStarted, "Status for voting is wrong");
        require(_voterAddress != address(0), "You cannot transfer to the address zero");
        require(voters[_voterAddress].isRegistered, "Address is not in withelist");
        require(!voters[_voterAddress].hasVoted, "User has already voted");

        voters[_voterAddress].hasVoted = true;
        voters[_voterAddress].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;

        emit Voted(_voterAddress,_proposalId);
    }

    /** 
    * @dev Retrieve the winning proposalId
    * @return the proposalId's winner
    */
    function TallyVote() external onlyOwner returns (uint) {
        require(status == WorkflowStatus.VotingSessionEnded, "Status for voting is wrong");

        uint voteMax;
        uint duplicate;

        for (uint i=0; i < proposals.length; i++) {
            if (voteMax < proposals[i].voteCount) {
                voteMax = proposals[i].voteCount;
                //reset the duplicate
                duplicate = 0;
                winningProposalId = i;
                continue;
            }

            //if duplicate is found, we increment
            if (voteMax == proposals[i].voteCount && proposals.length != 1) {
                duplicate++;
            }
        }

       require(voteMax != 0, "0 votes done, please restart the voting session");
        //if duplicate exists, we throw an error
       require(duplicate == 0, "Tie votes, please restart the voting session");

       changeStatus(WorkflowStatus.VotesTallieds);
       return winningProposalId;
    }

    /** 
    * @dev Restart session if tie votes 
    */
    function RestartVoteSession() external onlyOwner {
        status = WorkflowStatus.VotingSessionStarted;

        for (uint i = 0; i < arrayAddress.length; i++) {
            voters[arrayAddress[i]].hasVoted = false;
        }

        for (uint i = 0; i < proposals.length; i++) {
            proposals[i].voteCount = 0;
        }
    }

    /** 
    * @dev Retrieve the information about winning proposal
    * @param _voterAddress address' voter
    * @return winning proposal
    */
    function GetWinner(address _voterAddress) public view returns (Proposal memory) {
        require(status == WorkflowStatus.VotesTallieds, "Status for voting is wrong");
        require(_voterAddress != address(0), "You cannot transfer to the address zero");
        require(voters[_voterAddress].isRegistered, "Address is not in withelist");

        return proposals[winningProposalId];
    }
}
