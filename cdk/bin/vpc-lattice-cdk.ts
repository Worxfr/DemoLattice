#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { VpcLatticeStack } from '../lib/vpc-lattice-stack';

const app = new cdk.App();
new VpcLatticeStack(app, 'VpcLatticeStack', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION || 'us-west-1'
  },
  description: 'VPC Lattice infrastructure with multiple VPCs and services'
});