# VPC Lattice CDK Project

This directory contains an AWS CDK project written in TypeScript for managing VPC Lattice resources.

## Prerequisites

Before you begin, ensure you have the following installed:
- Node.js (v14.x or later)
- AWS CDK CLI (`npm install -g aws-cdk`)
- AWS CLI configured with appropriate credentials

## Installation

1. Install project dependencies:
```bash
npm install
```

## Available Scripts

The following npm scripts are available:

- `npm run build` - Compiles the TypeScript code
- `npm run watch` - Watches for changes and compiles TypeScript in real-time
- `npm run test` - Runs the test suite using Jest
- `npm run cdk` - Executes CDK commands

## Deployment Steps

1. Build the TypeScript code:
```bash
npm run build
```

2. (Optional) Synthesize the CloudFormation template:
```bash
npm run cdk synth
```

3. Deploy the stack:
```bash
npm run cdk deploy
```

To deploy to a specific AWS account and region:
```bash
npm run cdk deploy --profile [profile_name]
```

## Project Structure

- `bin/` - Contains the entry point for the CDK app
- `lib/` - Contains the stack definition
- `package.json` - Project dependencies and scripts
- `tsconfig.json` - TypeScript configuration

## Useful CDK Commands

* `cdk diff`        - Compare deployed stack with current state
* `cdk synth`       - Emits the synthesized CloudFormation template
* `cdk deploy`      - Deploy this stack to your default AWS account/region
* `cdk destroy`     - Destroy the stack in your AWS account

## Security

Remember to review the generated CloudFormation template before deployment and ensure you have the necessary AWS permissions.