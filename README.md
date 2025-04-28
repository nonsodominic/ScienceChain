# ScienceChain

A decentralized platform for scientific research funding built on Stacks blockchain.

## Overview

ScienceChain is a smart contract-based solution designed to democratize and decentralize scientific research funding. The platform allows researchers to submit proposals, which are then reviewed by a panel of qualified reviewers. If approved, projects become open for funding by contributors. The system includes mechanisms for fund management, withdrawals, and refunds to ensure transparency and accountability throughout the research funding process.

## Features

- **Decentralized Research Submission**: Researchers can submit proposals with details about their scientific projects
- **Peer Review System**: Qualified reviewers evaluate and vote on research proposals
- **Transparent Funding**: Contributors can fund approved projects directly through the blockchain
- **Automated Fund Management**: Smart contract handles fund allocation, milestone tracking, and withdrawals
- **Refund Mechanism**: Contributors can request refunds for projects that don't meet funding goals or deadlines
- **Governance Controls**: Contract administrator can manage reviewers and adjust system parameters

## Contract Functions

### For Researchers

- `submit-research`: Submit a new research proposal with title, description, and funding goal
- `withdraw-funds`: Claim funds for a fully funded project (restricted to the researcher who submitted the proposal)

### For Reviewers

- `review-research`: Vote to approve or reject a research proposal

### For Contributors

- `fund-research`: Contribute STX tokens to an approved research project
- `request-refund`: Request a refund if a project fails to meet its goals or is eligible for refunds

### For Administrators

- `add-reviewer`: Add a new qualified reviewer to the system
- `remove-reviewer`: Remove a reviewer from the system
- `set-minimum-reviews`: Update the minimum number of reviews required for a decision
- `set-funding-period`: Update the funding window duration
- `update-research-status`: Update the status of a research project

### Read-only Functions

- `get-research-details`: View details of a specific research project
- `get-research-count`: View the total number of research projects
- `get-contribution`: Check contribution amount for a specific contributor and project
- `get-research-status`: Check the current status of a research project
- `is-active-reviewer`: Verify if an account is an active reviewer
- `get-minimum-reviews`: Get the current minimum reviews required
- `get-funding-period`: Get the current funding period duration
- `check-refund-eligibility`: Check if a project is eligible for refund

## Status Definitions

- `SUBMITTED (0)`: Project has been submitted but not yet under review
- `UNDER_REVIEW (1)`: Project is currently being reviewed by qualified reviewers
- `APPROVED (2)`: Project has been approved by reviewers
- `REJECTED (3)`: Project has been rejected by reviewers
- `OPEN (4)`: Project is open for funding
- `FUNDED (5)`: Project has reached its funding goal
- `COMPLETED (6)`: Project funds have been withdrawn by the researcher
- `REFUNDABLE (7)`: Project is eligible for refunds

## How to Use

1. Deploy the contract to the Stacks blockchain
2. The contract deployer becomes the administrator
3. The administrator adds qualified reviewers
4. Researchers submit their proposals
5. Reviewers evaluate proposals
6. Approved projects become open for funding
7. Contributors fund interesting projects
8. Researchers withdraw funds to conduct their research

## Getting Started

To deploy this contract, you'll need:

- A Stacks wallet with sufficient STX for deployment
- [Clarinet](https://github.com/hirosystems/clarinet) for local testing
- Basic knowledge of the Stacks blockchain

## Development

To set up a local development environment:

```bash
# Install Clarinet
curl -sL https://github.com/hirosystems/clarinet/releases/latest | grep -E 'clarinet-.*-$ARCH.tar.gz' | cut -d : -f 2,3 | tr -d \" | wget -qi -

# Create a new project
clarinet new science-chain

# Replace the default contract with ScienceChain
cp sciencechain.clar science-chain/contracts/

# Test locally
cd science-chain
clarinet test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.