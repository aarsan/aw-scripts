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
SUBSCRIPTION_ID=your-azure-subscription-id-here
ADMIN_PASSWORD=YourSecurePasswordHere
RESOURCE_GROUP=your-resource-group-name
VNET_NAME=your-vnet-name
SQL_VM_NAME=your-sql-vm-name
APP_VM_NAME=your-app-vm-name
SQL_VM_SKU=Standard_M176bds_4_v3
APP_VM_SKU=Standard_M176bds_4_v3
REGION=eastus2
PPG_NAME=sql-app
ZONE=2
```

**Required Variables:**
- `SUBSCRIPTION_ID`: Your Azure subscription ID (GUID format)
- `ADMIN_PASSWORD`: Strong password for VM admin accounts
- `RESOURCE_GROUP`: Name for the Azure resource group
- `VNET_NAME`: Name for the virtual network
- `SQL_VM_NAME`: Name for the SQL server VM
- `APP_VM_NAME`: Name for the application server VM
- `SQL_VM_SKU`: VM size for the SQL server (e.g., Standard_M176bds_4_v3)
- `APP_VM_SKU`: VM size for the application server (e.g., Standard_M176bds_4_v3)
- `REGION`: Azure region for deployment (e.g., eastus2, westus2)
- `PPG_NAME`: Name for the proximity placement group
- `ZONE`: Availability zone number (1, 2, or 3)

**Important Security Notes:**
- Replace all placeholder values with your actual configuration
- The password must be 12-123 characters long and contain at least 3 of the following: lowercase, uppercase, numbers, special characters
- **Never commit the `.env` file to version control**
- The `.env` file is already included in `.gitignore` for your protection

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

All configuration variables are now managed through the `.env` file:

**Infrastructure Configuration:**
- `SUBSCRIPTION_ID`: Your Azure subscription ID
- `RESOURCE_GROUP`: Name for the resource group
- `REGION`: Azure region for deployment
- `ZONE`: Availability zone number

**Network Configuration:**
- `VNET_NAME`: Virtual network name
- `PPG_NAME`: Proximity placement group name

**Virtual Machine Configuration:**
- `SQL_VM_NAME`: Name for the SQL server VM
- `APP_VM_NAME`: Name for the application server VM
- `SQL_VM_SKU`: VM size for SQL server
- `APP_VM_SKU`: VM size for application server
- `ADMIN_PASSWORD`: Admin password for both VMs

**Note:** The script no longer contains any hard-coded configuration values. All customization is done through the `.env` file, making it easy to manage different environments and deployments.

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
