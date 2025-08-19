# Azure Windows VM Deployment Script

This PowerShell script deploys Windows Server VMs in Azure with optimized network performance and high availability configuration.

## Prerequisites

- Azure CLI installed and configured
- PowerShell 5.1 or later
- Valid Azure subscription

## Setup Instructions

### 1. Environment Configuration

Create a `.env` file in the same directory as the deployment script with the following format:

```
# Environment variables for Azure deployment
ADMIN_PASSWORD=YourSecurePasswordHere
```

**Important Security Notes:**
- Replace `YourSecurePasswordHere` with a strong password that meets Azure's requirements
- The password must be 12-123 characters long and contain at least 3 of the following: lowercase, uppercase, numbers, special characters
- **Never commit the `.env` file to version control**
- Add `.env` to your `.gitignore` file

### 2. Password Requirements

Your admin password must meet these Azure requirements:
- Length: 12-123 characters
- Must contain at least 3 of the following character types:
  - Lowercase letters (a-z)
  - Uppercase letters (A-Z)
  - Numbers (0-9)
  - Special characters (!@#$%^&*()_+-=[]{}|;:,.<>?)

Example of a strong password format: `MySecureP@ssw0rd2024!`

### 3. Configuration Variables

Before running the script, review and modify these variables in `deploy.ps1` as needed:

- `$subscriptionId`: Your Azure subscription ID
- `$resource_group`: Name for the resource group
- `$vnet`: Virtual network name
- `$region`: Azure region (default: eastus2)
- `$zone`: Availability zone (default: 2)
- `$sql_vm_sku`: VM size for SQL server
- `$app_vm_sku`: VM size for application server

## Usage

1. Clone or download this repository
2. Create your `.env` file with the admin password
3. Open PowerShell and navigate to the script directory
4. Run the deployment script:

```powershell
.\deploy.ps1
```

## What the Script Deploys

The script creates the following Azure resources:

1. **Resource Group**: Container for all resources
2. **Virtual Network**: Network with 10.0.0.0/16 address space
3. **Subnet**: Default subnet with 10.0.1.0/24 range
4. **Proximity Placement Group**: Ensures VMs are placed close together for low latency
5. **Two Windows Server VMs**:
   - SQL VM: For database workloads
   - App VM: For application workloads
   - Both configured with:
     - Windows Server 2022 Datacenter Azure Edition
     - Accelerated Networking enabled
     - Deployed in the same availability zone
     - Standard public IP addresses

## Security Best Practices

1. **Environment File Security**:
   ```bash
   # Add to .gitignore
   echo ".env" >> .gitignore
   ```

2. **File Permissions**: Ensure only necessary users can read the `.env` file

3. **Password Management**: Consider using Azure Key Vault for production deployments

4. **Regular Updates**: Regularly update passwords and review access

## Troubleshooting

- **"Environment file not found" error**: Ensure `.env` file exists in the same directory as the script
- **Invalid password error**: Verify your password meets Azure's complexity requirements
- **VM size not available**: Check if the specified VM sizes are available in your selected region
- **Quota exceeded**: Verify you have sufficient quota for the VM sizes in the target region

## Clean Up

To delete all resources created by this script:

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

Replace `<resource-group-name>` with the actual resource group name used in the script.
