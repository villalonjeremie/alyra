const Voting = artifacts.require("Voting.sol");
const { BN , expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

contract("Voting", accounts => {
  const _owner = accounts[0];
  const _genesis = "GENESIS";
  const _proposal1 = "Augmenter les salaires";
  const _proposal2 = "Avoir plus de vacances";
  const _proposal3 = "Avoir de la biere a la cantine";
  const _registeringVoters = new BN(0);
  const _proposalsRegistrationStarted = new BN(1);
  const _proposalsRegistrationEnded = new BN(2);
  const _votingSessionStarted = new BN(3);
  const _votingSessionEnded = new BN(4);
  const _votesTallied = new BN(5);

  let VotingInstance;

  describe("Testing setter/getter", function () {
    beforeEach(async function () {
      VotingInstance = await Voting.new({from: _owner});
    });

    it("should store voter in mapping structure, retrieve voter", async () => {
      await VotingInstance.addVoter(accounts[1], { from: _owner });
      const voter = await VotingInstance.getVoter(accounts[1], { from: accounts[1] });
      expect(voter.isRegistered).to.equal(true);
    });

    it("should init proposal in array structure, retrieve init proposal", async () => {
      await VotingInstance.addVoter(_owner, { from: _owner });
      await VotingInstance.startProposalsRegistering();
      const proposal = await VotingInstance.getOneProposal(0, { from: _owner });
      expect(proposal.description).to.equal(_genesis);
    });

    it("should store proposal in array structure, retrieve proposal", async () => {
      await VotingInstance.addVoter(accounts[1], { from: _owner });
      await VotingInstance.startProposalsRegistering();
      await VotingInstance.addProposal(_proposal1, { from: accounts[1] });
      const proposal = await VotingInstance.getOneProposal(1, { from: accounts[1] });
      expect(proposal.description).to.equal(_proposal1);
    });
  });

  describe("Testing status", function () {
    before(async function () {
      VotingInstance = await Voting.new({ from: _owner });
    });

    it("retrieve proposalsRegistrationStarted status", async () => {
      await VotingInstance.startProposalsRegistering();
      const status = await VotingInstance.workflowStatus.call({ from: _owner })
      expect(status).to.be.bignumber.equal(_proposalsRegistrationStarted);
    });

    it("retrieve proposalsRegistrationEnded status", async () => {
      await VotingInstance.endProposalsRegistering();
      const status = await VotingInstance.workflowStatus.call({ from: _owner })
      expect(status).to.be.bignumber.equal(_proposalsRegistrationEnded);
    });

    it("retrieve votingSessionStarted status", async () => {
      await VotingInstance.startVotingSession();
      const status = await VotingInstance.workflowStatus.call({ from: _owner })
      expect(status).to.be.bignumber.equal(_votingSessionStarted);
    });

    it("retrieve votingSessionEnded status", async () => {
      await VotingInstance.endVotingSession();
      const status = await VotingInstance.workflowStatus.call({ from: _owner })
      expect(status).to.be.bignumber.equal(_votingSessionEnded);
    });
  });

  describe("Testing setVote and tallyVote ", function () {
    beforeEach(async function () {
      VotingInstance = await Voting.new({from: _owner});
      await VotingInstance.addVoter(accounts[1], { from: _owner });
      await VotingInstance.addVoter(accounts[2], { from: _owner });
      await VotingInstance.addVoter(accounts[3], { from: _owner });
      await VotingInstance.startProposalsRegistering();
      await VotingInstance.addProposal(_proposal1, { from: accounts[1] });
      await VotingInstance.addProposal(_proposal2, { from: accounts[2] });
      await VotingInstance.addProposal(_proposal3, { from: accounts[3] });
      await VotingInstance.endProposalsRegistering();
    });

    it("should be the result proposalId at 2", async () => {
      await VotingInstance.startVotingSession();
      await VotingInstance.setVote(2, { from: accounts[1] });
      await VotingInstance.setVote(2, { from: accounts[2] });
      await VotingInstance.setVote(2, { from: accounts[3] });
      await VotingInstance.endVotingSession();
      await VotingInstance.tallyVotes();
      const winnerId = await VotingInstance.winningProposalID.call({ from: _owner });
      expect(winnerId).to.be.bignumber.equal(new BN(2));
    });

    it("should be the result proposalId at 0 with no vote done", async () => {
      await VotingInstance.startVotingSession();
      await VotingInstance.endVotingSession();
      await VotingInstance.tallyVotes();
      const winnerId = await VotingInstance.winningProposalID.call({ from: _owner });
      expect(winnerId).to.be.bignumber.equal(new BN(0));
    });
  });

  describe("Testing events", function () {
    before(async function () {
      VotingInstance = await Voting.new({ from: _owner });
    });

    it("get VoterRegistered event", async () => {
      const findEvent = await VotingInstance.addVoter(accounts[1], { from: _owner });
      expectEvent(findEvent, "VoterRegistered", { voterAddress: accounts[1] });
    });

    it("get VoterRegistered event", async () => {
      await VotingInstance.startProposalsRegistering();
      const findEvent = await VotingInstance.addProposal(_proposal1, { from: accounts[1] });
      expectEvent(findEvent, "ProposalRegistered", { proposalId: new BN(1) });
    });

    it("get WorkflowStatusChange event", async () => {
      await VotingInstance.endProposalsRegistering();
      const findEvent = await VotingInstance.startVotingSession();
      expectEvent(findEvent, "WorkflowStatusChange", { previousStatus: new BN(2), newStatus: new BN(3) });
    });

    it("get Voted event", async () => {
      const findEvent = await VotingInstance.setVote(1, { from: accounts[1] });
      expectEvent(findEvent, "Voted", { voter: accounts[1], proposalId: new BN(1) });
    });
  });

  describe("Testing revert", function () {
    before(async function () {
      VotingInstance = await Voting.new( {from: _owner} );
    });

    it("should not add an already registered voter, revert", async () => {
      await VotingInstance.addVoter(accounts[1], { from: _owner });
      await VotingInstance.addVoter(accounts[2], { from: _owner });
      await expectRevert(VotingInstance.addVoter(accounts[1], { from: _owner }), 'Already registered');
    });

    it("should not be a proposal registration session, revert", async () => {
      await expectRevert(VotingInstance.addProposal(_proposal1, { from: accounts[1] }), 'Proposals are not allowed yet');
    });

    it("should not be a voter registration session, revert", async () => {
      await VotingInstance.startProposalsRegistering();
      await expectRevert(VotingInstance.addVoter(accounts[3], { from: _owner }), 'Voters registration is not open yet');
    });

    it("should not be an empty proposal, revert", async () => {
      await expectRevert(VotingInstance.addProposal("", { from:  accounts[1] }), 'Vous ne pouvez pas ne rien proposer');
    });

    it("should not be voting session, revert", async () => {
      await expectRevert(VotingInstance.setVote(1, { from:  accounts[1] }), 'Voting session havent started yet');
    });

    it("should not be a vote already done, revert", async () => {
      await VotingInstance.addProposal(_proposal1, { from: accounts[1] });
      await VotingInstance.addProposal(_proposal2, { from: accounts[2] });
      await VotingInstance.endProposalsRegistering();
      await VotingInstance.startVotingSession();
      await VotingInstance.setVote(1, { from: accounts[1] });
      await expectRevert(VotingInstance.setVote(1, { from:  accounts[1] }), 'You have already voted');
    });

    it("should not a proposal not found, revert", async () => {
      await expectRevert(VotingInstance.setVote(10, { from:  accounts[2] }), 'Proposal not found');
    });

    it("should not a non voting session ended, revert", async () => {
      await expectRevert(VotingInstance.tallyVotes({ from:  _owner }), 'Current status is not voting session ended');
    });

    it("should not be a wining proposalId number 2 due to tie vote, first index is kept", async () => {
      await VotingInstance.setVote(2, { from: accounts[2] });
      await VotingInstance.endVotingSession();
      await VotingInstance.tallyVotes();
      const winnerId = await VotingInstance.winningProposalID.call({from: _owner});
      expect(winnerId).to.be.bignumber.equal(new BN(1));
    });
  });  
});
