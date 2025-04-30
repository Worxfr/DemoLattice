import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as vpclattice from 'aws-cdk-lib/aws-vpclattice';
import { Construct } from 'constructs';

export class VpcLatticeStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create Client1 VPC
    const client1Vpc = new ec2.Vpc(this, 'Client1VPC', {
      ipAddresses: ec2.IpAddresses.cidr('10.1.0.0/24'),
      maxAzs: 1,
      subnetConfiguration: [
        {
          cidrMask: 25,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        }
      ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Create Client2 VPC
    const client2Vpc = new ec2.Vpc(this, 'Client2VPC', {
      // amazonq-ignore-next-line
      ipAddresses: ec2.IpAddresses.cidr('10.1.0.0/24'),
      maxAzs: 1,
      subnetConfiguration: [
        {
          cidrMask: 25,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        }
      ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Create Client2 Bis VPC
    const client2BisVpc = new ec2.Vpc(this, 'Client2BisVPC', {
      ipAddresses: ec2.IpAddresses.cidr('10.101.0.0/24'),
      maxAzs: 1,
      subnetConfiguration: [
        {
          cidrMask: 25,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        }
      ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Create Provider VPC
    const providerVpc = new ec2.Vpc(this, 'ProviderVPC', {
      ipAddresses: ec2.IpAddresses.cidr('10.1.0.0/24'),
      maxAzs: 1,
      subnetConfiguration: [
        {
          cidrMask: 25,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 25,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        }
      ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Create Provider Bis VPC
    const providerBisVpc = new ec2.Vpc(this, 'ProviderBisVPC', {
      ipAddresses: ec2.IpAddresses.cidr('10.200.0.0/24'),
      maxAzs: 1,
      subnetConfiguration: [
        {
          cidrMask: 25,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 25,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        }
      ],
      enableDnsHostnames: true,
      enableDnsSupport: true,
    });

    // Create VPC Peering between Provider and Provider Bis
    const providerToBisPeering = new ec2.CfnVPCPeeringConnection(this, 'ProviderToBisPeering', {
      vpcId: providerVpc.vpcId,
      peerVpcId: providerBisVpc.vpcId,
      tags: [{
        key: 'Name',
        value: 'Provider-to-Bis-Peering'
      }]
    });

    // Create VPC Peering between Client2 and Client2 Bis
    const client2ToBisPeering = new ec2.CfnVPCPeeringConnection(this, 'Client2ToBisPeering', {
      vpcId: client2Vpc.vpcId,
      peerVpcId: client2BisVpc.vpcId,
      tags: [{
        key: 'Name',
        value: 'Client2-to-Bis-Peering'
      }]
    });

    // Create SSM IAM Role
    const ssmRole = new iam.Role(this, 'SSMRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore')
      ],
    });

    // Create Security Groups
    const providerSg = new ec2.SecurityGroup(this, 'ProviderSecurityGroup', {
      vpc: providerVpc,
      allowAllOutbound: true,
      description: 'Allow HTTP and ICMP inbound traffic'
    });

    providerSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'Allow HTTP inbound'
    );

    providerSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.icmpPing(),
      'Allow ICMP inbound'
    );

    // Create Provider Instance
    const providerInstance = new ec2.Instance(this, 'ProviderInstance', {
      vpc: providerVpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
      },
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3A, ec2.InstanceSize.MICRO),
      machineImage: new ec2.AmazonLinuxImage({
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2
      }),
      role: ssmRole,
      securityGroup: providerSg,
      userData: ec2.UserData.custom(`#!/bin/bash
yum update -y
yum install -y httpd php
systemctl start httpd
systemctl enable httpd
cat << 'PHPSCRIPT' > /var/www/html/index.php
<?php
  # Print my IP:
  echo "\\n";
  echo "███████╗███████╗██████╗ ██╗   ██╗██╗ ██████╗███████╗     ██╗\\n";
  echo "██╔════╝██╔════╝██╔══██╗██║   ██║██║██╔════╝██╔════╝    ███║\\n";
  echo "███████╗█████╗  ██████╔╝██║   ██║██║██║     █████╗      ╚██║\\n";
  echo "╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██║     ██╔══╝       ██║\\n";
  echo "███████║███████╗██║  ██║ ╚████╔╝ ██║╚██████╗███████╗     ██║\\n";
  echo "╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝╚══════╝     ╚═╝\\n";
  echo "\\n";
  echo "LOCAL SERVER IP: ";
  echo $_SERVER['SERVER_ADDR'];
  echo "\\n";
  echo "REMOTE CLIENT IP: ";
  echo $_SERVER['REMOTE_ADDR'];
  echo "\\n";
  echo "X-FORWARDED-FOR: ";
  echo isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : 'N/A';
  echo "\\n";
  echo "HOST-HEADER: ";
  echo $_SERVER['HTTP_HOST'];
  echo "\\n";
  echo "SERVER PORT: ";
  echo $_SERVER['SERVER_PORT'];
  echo "\\n";
  echo "X-AMZN-LATTICE-IDENTITY: ";
  echo isset($_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY']) ? $_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY'] : 'N/A';
  echo "\\n";
  echo "X-AMZN-LATTICE-NETWORK: ";
  echo isset($_SERVER['HTTP_X_AMZN_LATTICE_NETWORK']) ? $_SERVER['HTTP_X_AMZN_LATTICE_NETWORK'] : 'N/A';
  echo "\\n";
  echo "X-AMZN-LATTICE-TARGET: ";
  echo isset($_SERVER['HTTP_X_AMZN_LATTICE_TARGET']) ? $_SERVER['HTTP_X_AMZN_LATTICE_TARGET'] : 'N/A';
  echo "\\n\\n";
?>
PHPSCRIPT`)
    });


    const providerBisSg = new ec2.SecurityGroup(this, 'ProviderBisSecurityGroup', {
      vpc: providerBisVpc,
      allowAllOutbound: true,
      description: 'Allow HTTP and ICMP inbound traffic'
    });

    providerBisSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'Allow HTTP inbound'
    );

    providerBisSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.icmpPing(),
      'Allow ICMP inbound'
    );

    const providerBisInstance = new ec2.Instance(this, 'ProviderBisInstance', { // amazonq-ignore-line
      vpc: providerBisVpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
      },
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3A, ec2.InstanceSize.MICRO),
      machineImage: new ec2.AmazonLinuxImage({
        generation: ec2.AmazonLinuxGeneration.AMAZON_LINUX_2
      }),
      role: ssmRole,
      securityGroup: providerBisSg,
      userData: ec2.UserData.custom(`#!/bin/bash
yum update -y
yum install -y httpd php
systemctl start httpd
systemctl enable httpd
cat << 'PHPSCRIPT' > /var/www/html/index.php
<?php
  # Print my IP:
  echo "\\n";
  echo "██████╗ ███████╗███████╗ ██████╗ ██╗   ██╗██████╗  ██████╗███████╗     ██╗\\n";
  echo "██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║██╔══██╗██╔════╝██╔════╝    ███║\\n";
  echo "██████╔╝█████╗  ███████╗██║   ██║██║   ██║██████╔╝██║     █████╗      ╚██║\\n";
  echo "██╔══██╗██╔══╝  ╚════██║██║   ██║██║   ██║██╔══██╗██║     ██╔══╝       ██║\\n";
  echo "██║  ██║███████╗███████║╚██████╔╝╚██████╔╝██║  ██║╚██████╗███████╗     ██║\\n";
  echo "╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝     ╚═╝\\n";
  echo "\\n";
  echo "LOCAL SERVER IP: ";
  echo $_SERVER['SERVER_ADDR'];
  echo "\\n";
  echo "REMOTE CLIENT IP: ";
  echo $_SERVER['REMOTE_ADDR'];
  echo "\\n";
  echo "X-FORWARDED-FOR: ";
  echo isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? $_SERVER['HTTP_X_FORWARDED_FOR'] : 'N/A';
  echo "\\n";
  echo "HOST-HEADER: ";
  echo $_SERVER['HTTP_HOST'];
  echo "\\n";
  echo "SERVER PORT: ";
  echo $_SERVER['SERVER_PORT'];
  echo "\\n";
  echo "X-AMZN-LATTICE-IDENTITY: ";
  echo isset($_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY']) ? $_SERVER['HTTP_X_AMZN_LATTICE_IDENTITY'] : 'N/A';
  echo "\\n";
  echo "X-AMZN-LATTICE-NETWORK: ";
  echo isset($_SERVER['HTTP_X_AMZN_LATTICE_NETWORK']) ? $_SERVER['HTTP_X_AMZN_LATTICE_NETWORK'] : 'N/A';
  echo "\\n";
  echo "X-AMZN-LATTICE-TARGET: ";
  echo isset($_SERVER['HTTP_X_AMZN_LATTICE_TARGET']) ? $_SERVER['HTTP_X_AMZN_LATTICE_TARGET'] : 'N/A';
  echo "\\n\\n";
?>
PHPSCRIPT`)
    });
    
    // Create VPC Lattice Service Network
    const serviceNetwork = new vpclattice.CfnServiceNetwork(this, 'ServiceNetwork', {
      name: 'example-service-network',
      tags: [{
        key: 'Name',
        value: 'Example Service Network'
      }]
    });

    // Create VPC Lattice Service
    const service = new vpclattice.CfnService(this, 'Service1', {
      name: 'service1',
      authType: 'NONE',
      tags: [{
        key: 'Name',
        value: 'Example Service'
      }]
    });

    // Create Target Group
    const targetGroup = new vpclattice.CfnTargetGroup(this, 'ProviderTargetGroup', {
      name: 'provider-target-group',
      type: 'INSTANCE',
      config: {
        port: 80,
        protocol: 'HTTP',
        vpcIdentifier: providerVpc.vpcId,
        healthCheck: {
          enabled: true,
          protocol: 'HTTP',
          path: '/index.php',
          port: 80
        }      
      },
      targets: [{
        id: providerInstance.instanceId,
        port: 80
      }],
      tags: [{
        key: 'Name',
        value: 'Provider-Target-Group'
      }]
    });

    // Create Listener
    new vpclattice.CfnListener(this, 'Service1Listener', {
      name: 'example-listener',
      protocol: 'HTTP',
      port: 80,
      serviceIdentifier: service.attrId,
      defaultAction: {
        forward: {
          targetGroups: [{
            targetGroupIdentifier: targetGroup.attrId,
            weight: 100
          }]
        }
      }
    });

    // Associate Service with Service Network
    new vpclattice.CfnServiceNetworkServiceAssociation(this, 'Service1Association', {
      serviceIdentifier: service.attrId,
      serviceNetworkIdentifier: serviceNetwork.attrId,
      tags: [{
        key: 'Name',
        value: 'Service-Network-Association'
      }]
    });

    const privateSubnets = providerVpc.selectSubnets({
      subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS
    }).subnetIds

    const rg = new vpclattice.CfnResourceGateway(this, 'ProviderResourceGateway', {
      name: 'provider-resource-gateway',
      subnetIds: privateSubnets,
      vpcIdentifier: providerVpc.vpcId,
      tags: [{
        key: 'Name',
        value: 'Provider-Resource-Gateway'
      }]
    })

    const rc = new vpclattice.CfnResourceConfiguration(this, 'ResourceConfig', {
      name: 'provider-resource',
      resourceGatewayId: rg.attrArn,
      resourceConfigurationType: 'SINGLE',
      portRanges: ["80"],
      protocolType: "TCP",
      resourceConfigurationDefinition: {
        ipResource: providerBisInstance.instancePrivateIp
      },
      tags:  [{
        key: 'Name',
        value: 'Provider-Resource'
      }]

    });

    new vpclattice.CfnServiceNetworkResourceAssociation(this, "rca"
      , {
        resourceConfigurationId: rc.attrId,
        serviceNetworkId: serviceNetwork.attrId,
        tags: [{
          key: 'Name',
          value: 'Resource-Network-Association'
        }]
      }

    )

    
    // Associate Client1 VPC with Service Network
    new vpclattice.CfnServiceNetworkVpcAssociation(this, 'Client1Association', {
      vpcIdentifier: client1Vpc.vpcId,
      serviceNetworkIdentifier: serviceNetwork.attrId,
      tags: [{
        key: 'Name',
        value: 'Client1-ServiceNetwork-Association'
      }]
    });

    // Add Gateway Endpoints for S3
    client1Vpc.addGatewayEndpoint('S3GatewayEndpoint', {
      service: ec2.GatewayVpcEndpointAwsService.S3
    });

    client2Vpc.addGatewayEndpoint('S3GatewayEndpoint', {
      service: ec2.GatewayVpcEndpointAwsService.S3
    });

    client2BisVpc.addGatewayEndpoint('S3GatewayEndpoint', {
      service: ec2.GatewayVpcEndpointAwsService.S3
    });

    // Add Interface Endpoints for SSM
    const ssmEndpoints = [
      { service: ec2.InterfaceVpcEndpointAwsService.SSM },
      { service: ec2.InterfaceVpcEndpointAwsService.SSM_MESSAGES },
      { service: ec2.InterfaceVpcEndpointAwsService.EC2_MESSAGES },
      { service: ec2.InterfaceVpcEndpointAwsService.EC2 }
    ];

    ssmEndpoints.forEach(endpoint => {
      client1Vpc.addInterfaceEndpoint(`Client1${endpoint.service.shortName}Endpoint`, endpoint);
      client2Vpc.addInterfaceEndpoint(`Client2${endpoint.service.shortName}Endpoint`, endpoint);
      client2BisVpc.addInterfaceEndpoint(`Client2Bis${endpoint.service.shortName}Endpoint`, endpoint);
    });


    
    // Outputs
    new cdk.CfnOutput(this, 'Client1VpcId', { value: client1Vpc.vpcId });
    new cdk.CfnOutput(this, 'Client2VpcId', { value: client2Vpc.vpcId });
    new cdk.CfnOutput(this, 'Client2BisVpcId', { value: client2BisVpc.vpcId });
    new cdk.CfnOutput(this, 'ProviderVpcId', { value: providerVpc.vpcId });
    new cdk.CfnOutput(this, 'ProviderBisVpcId', { value: providerBisVpc.vpcId });
    new cdk.CfnOutput(this, 'Service1DnsName', { value: service.attrDnsEntryDomainName });
  }
}