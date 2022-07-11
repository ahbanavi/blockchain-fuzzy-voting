//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract Voting {
    enum VoteBlockType {
        UpVote,
        DownVote
    }

    struct VoteBlock {
        uint256 id;
        uint256 createdAt;
        VoteBlockType blockType;
        address agent;
    }

    struct FeedbackBlock {
        uint256 id;
        uint256 createdAt;
        string feedback;
        address agent;
    }

    struct Decision {
        string context;
        address agent;
        uint256 createdAt;
        VoteBlock[] votes;
        FeedbackBlock[] feedbacks;
    }

    struct AgentBlock {
        string name;
    }

    /// decision mappings
    mapping(uint256 => Decision) public decisions;

    /// agent mappings
    mapping(address => AgentBlock) public agents;

    /// current decision id
    uint256 public currentDecisionID = 0;

    modifier OnlyAgents() {
        require(bytes(agents[msg.sender].name).length != 0, "Only agents can call this function");
        _;
    }

    constructor(string memory ownerName) {
        require(bytes(ownerName).length != 0, "Owner name cannot be empty");
        agents[msg.sender].name = ownerName;
    }

    /// create a new decision
    function createDecision(string calldata context_) public OnlyAgents returns (uint256) {
        currentDecisionID++;
        Decision storage decision = decisions[currentDecisionID];
        decision.context = context_;
        decision.agent = msg.sender;
        decision.createdAt = block.timestamp;

        return currentDecisionID;
    }

    /// vote for a decision
    function vote(uint256 _decisionID, VoteBlockType _blockType) public OnlyAgents returns (uint256) {
        Decision storage decision = decisions[_decisionID];
        // abort if decision does not exist
        require(bytes(decision.context).length != 0, "Decision does not exist");

        // abort if agent has already voted
        for (uint256 i = 0; i < decision.votes.length; i++) {
            if (decision.votes[i].agent == msg.sender) {
                revert("Agent has already voted");
            }
        }

        uint256 voteID = decision.votes.length;
        VoteBlock memory newVote = VoteBlock({
            id: voteID,
            createdAt: block.timestamp,
            blockType: _blockType,
            agent: msg.sender
        });
        decision.votes.push(newVote);

        return voteID;
    }

    /// get votes
    function getVotes(uint256 _decisionID) public view returns (VoteBlock[] memory) {
        Decision storage decision = decisions[_decisionID];
        return decision.votes;
    }

    /// feedback for a decision
    function feedback(uint256 _decisionID, string calldata _feedback) public OnlyAgents returns (uint256) {
        Decision storage decision = decisions[_decisionID];
        // abort if decision does not exist
        require(bytes(decision.context).length != 0, "Decision does not exist");

        // abort if agent has already voted
        for (uint256 i = 0; i < decision.feedbacks.length; i++) {
            if (decision.feedbacks[i].agent == msg.sender) {
                revert("Agent has already voted");
            }
        }

        uint256 feedbackID = decision.feedbacks.length;
        FeedbackBlock memory newFeedback = FeedbackBlock({
            id: feedbackID,
            createdAt: block.timestamp,
            feedback: _feedback,
            agent: msg.sender
        });
        decision.feedbacks.push(newFeedback);

        return feedbackID;
    }

    /// get decision rank
    function getDecisionRank(uint256 _decisionID) public view returns (int256) {
        Decision memory decision = decisions[_decisionID];
        // abort if decision does not exist
        require(bytes(decision.context).length != 0, "Decision does not exist");

        // up vote - down vote
        int256 upVote = 0;
        int256 downVote = 0;
        for (uint256 i = 0; i < decision.votes.length; i++) {
            if (decision.votes[i].blockType == VoteBlockType.UpVote) {
                upVote++;
            } else {
                downVote++;
            }
        }

        return upVote - downVote;
    }

    /// register an agent
    function registerAgent(address agent_, string calldata name_) public OnlyAgents {
        // abort if agent_ is zero
        require(agent_ != address(0), "Agent is zero");
        // abort if name_ is empty
        require(bytes(name_).length != 0, "Name is empty");
        // abort if agent_ is already registered
        require(bytes(agents[agent_].name).length == 0, "Agent is already registered");

        agents[agent_].name = name_;
    }
}
