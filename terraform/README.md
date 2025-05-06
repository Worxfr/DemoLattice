# DemoLattice - Terraform Implementation

> [!WARNING]  
> ## ⚠️ Important Disclaimer
>
> **This project is for testing and demonstration purposes only.**
>
> Please be aware of the following:
>
> - The infrastructure deployed by this project is not intended for production use.
> - Security measures may not be comprehensive or up to date.
> - Performance and reliability have not been thoroughly tested at scale.
> - The project may not comply with all best practices or organizational standards.
>
> Before using any part of this project in a production environment:
>
> 1. Thoroughly review and understand all code and configurations.
> 2. Conduct a comprehensive security audit.
> 3. Test extensively in a safe, isolated environment.
> 4. Adapt and modify the code to meet your specific requirements and security standards.
> 5. Ensure compliance with your organization's policies and any relevant regulations.
>
> The maintainers of this project are not responsible for any issues that may arise from the use of this code in production environments.
---

This directory contains the Terraform implementation of the DemoLattice project, which demonstrates AWS VPC Lattice for service networking across multiple VPCs.

## Architecture Diagram

![DemoLattice Architecture](../img/demolattice.drawio.png)

## Test Scenario

This project specifically tests the following scenarios:

- **Overlapping CIDR Blocks**: Client1, Client2, and Provider VPCs intentionally use the same CIDR block (10.1.0.0/24) to demonstrate VPC Lattice's ability to handle overlapping IP address spaces.

- **On-Premises Connectivity Simulation**: 
  - Client2Bis VPC simulates an on-premises environment connected to Client2 VPC through VPC Peering.
  - ProviderBis VPC simulates an on-premises service connected to Provider VPC through VPC Peering.

- **Hybrid Service Access**: The Provider offers two services:
  - A service running in AWS (Provider VPC)
  - A service running in the simulated on-premises environment (ProviderBis VPC)

## Architecture Overview

The Terraform code provisions the following resources:

- **VPCs**:
  - Client1 VPC (10.1.0.0/24)
  - Client2 VPC (10.1.0.0/24)
  - Client2Bis VPC (10.101.0.0/24) - Simulates on-premises environment
  - Provider VPC (10.1.0.0/24)
  - ProviderBis VPC (10.200.0.0/24) - Simulates on-premises service

- **VPC Peering**:
  - Provider to ProviderBis (AWS to simulated on-premises service)
  - Client2 to Client2Bis (AWS to simulated on-premises client)

- **EC2 Instances**:
  - Client instances in each VPC
  - Provider instances with web servers

- **VPC Lattice Components**:
  - Service Network
  - Service with HTTP listener
  - Target Group for Provider instance
  - Resource Gateway for ProviderBis instance

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform v1.0.0 or newer
- S3 bucket for Terraform state (optional, for remote state)

## Configuration

### 1. Variables Configuration

Create or modify `terraform.tfvars` with your specific values:

```hcl
region             = "us-east-1"  # Change to your preferred region
availability_zones = ["us-east-1a", "us-east-1b"]  # Change to AZs in your region
name               = "demolattice"  # Project name prefix
```

### 2. Backend Configuration (Optional)

If you want to use S3 for remote state storage, update `config.s3.tfbackend`:

```hcl
bucket         = "your-terraform-state-bucket"
key            = "demolattice/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"  # Optional, for state locking
```

### 3. Network Configuration

**Important Note**: The current configuration intentionally uses overlapping CIDR blocks (10.1.0.0/24) for Client1, Client2, and Provider VPCs. This is by design for this demo to showcase specific networking scenarios with VPC Lattice. **Do not modify these CIDR blocks** as it may break the intended demonstration.

The CIDR blocks are:
- Client1 VPC: 10.1.0.0/24
- Client2 VPC: 10.1.0.0/24
- Client2Bis VPC: 10.101.0.0/24 (simulated on-premises)
- Provider VPC: 10.1.0.0/24
- ProviderBis VPC: 10.200.0.0/24 (simulated on-premises)

## Deployment Instructions

### Initialize Terraform

```bash
terraform init
```

If using S3 backend:

```bash
terraform init -backend-config=config.s3.tfbackend
```

### Plan the Deployment

```bash
terraform plan -out=tfplan
```

### Apply the Configuration

```bash
terraform apply tfplan
```

Or directly:

```bash
terraform apply
```

## Testing the Setup

After deployment, you can test the VPC Lattice setup using different access methods:

### From Client1 VPC

Client1 VPC is directly associated with the Service Network, so you can access both services using the VPC Lattice service FQDN:

```bash
# Connect to Client1 instance using AWS Systems Manager Session Manager
aws ssm start-session --target <client1-instance-id>

# Access the AWS service
curl http://service1.<generated-id>.vpc-lattice-svcs.<region>.amazonaws.com

# Access the simulated on-premises service (via Resource Gateway)
curl http://service1.<generated-id>.vpc-lattice-svcs.<region>.amazonaws.com
```

### From Client2 VPC

Client2 VPC uses a VPC Endpoint to connect to the Service Network, so you must access services through the Service Network Endpoint FQDN:

```bash
# Connect to Client2 instance using AWS Systems Manager Session Manager
aws ssm start-session --target <client2-instance-id>

# Access services through the Service Network Endpoint
curl http://<service-network-endpoint-dns-name>
```

### From Client2Bis VPC (Simulated On-Premises)

Client2Bis VPC is connected to Client2 VPC via VPC Peering, demonstrating how on-premises environments can access VPC Lattice services:

```bash
# Connect to Client2Bis instance using AWS Systems Manager Session Manager
aws ssm start-session --target <client2bis-instance-id>

# Access services through Client2's VPC Endpoint (via VPC Peering)
curl http://<service-network-endpoint-dns-name>
```

The web servers will display connection information including:
- Server IP
- Client IP
- VPC Lattice headers
- Connection path information

## Troubleshooting

### Common Issues

1. **Deployment Failures**:
   - Check that your AWS credentials have sufficient permissions
   - Verify that the specified region supports all required services

2. **Connectivity Issues**:
   - Ensure security groups allow necessary traffic
   - Verify route tables have correct routes for VPC peering
   - Check that VPC Lattice associations are properly configured

3. **Resource Limits**:
   - You might hit service limits for VPCs, endpoints, or other resources
   - Request limit increases if needed

## Cleanup

To avoid incurring charges, destroy all resources when done:

```bash
terraform destroy
```

## File Structure

- `main.tf` - Main infrastructure definition
- `variables.tf` - Variable declarations
- `terraform.tfvars` - Variable values
- `provider_bis_nat.tf` - NAT gateway configuration for Provider VPCs
- `network_changes.tf` - Additional network configurations
- `.terraform.lock.hcl` - Terraform provider lock file
- `config.s3.tfbackend` - Backend configuration

## Customization

To customize this implementation:

1. Adjust instance types or AMIs in the EC2 instance resources
2. Add additional services or target groups to the VPC Lattice setup
3. Extend security groups for more granular access control

**Note**: Do not modify the CIDR ranges as they are intentionally configured for this demo.