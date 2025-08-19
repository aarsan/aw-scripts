# Load environment variables from .env file
function Load-EnvFile {
    param($EnvFilePath = ".\.env")
    
    if (Test-Path $EnvFilePath) {
        Get-Content $EnvFilePath | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]*)\s*=\s*(.*)\s*$") {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                Set-Variable -Name $name -Value $value -Scope Global
            }
        }
        Write-Host "Loaded environment variables from $EnvFilePath"
    } else {
        Write-Error "Environment file $EnvFilePath not found!"
        exit 1
    }
}

# Load environment variables
Load-EnvFile

# Set Azure subscription
az account set --subscription $SUBSCRIPTION_ID

# Create Resource Group
Write-Host "Creating Resource Group: $RESOURCE_GROUP"
az group create `
    --name $RESOURCE_GROUP `
    --location $REGION

# Create Virtual Network
Write-Host "Creating Virtual Network: $VNET_NAME"
az network vnet create `
    --resource-group $RESOURCE_GROUP `
    --name $VNET_NAME `
    --location $REGION `
    --address-prefixes "10.0.0.0/16" `
    --subnet-name "default" `
    --subnet-prefixes "10.0.1.0/24"

# Create Proximity Placement Group
Write-Host "Creating Proximity Placement Group: $PPG_NAME"
az ppg create `
    --resource-group $RESOURCE_GROUP `
    --name $PPG_NAME `
    --location $REGION `
    --type Standard `
    --intent-vm-sizes $SQL_VM_SKU $APP_VM_SKU

# Create SQL VM in the PPG
Write-Host "Creating SQL VM: $SQL_VM_NAME"
az vm create `
    --resource-group $RESOURCE_GROUP `
    --name $SQL_VM_NAME `
    --image "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest" `
    --size $SQL_VM_SKU `
    --location $REGION `
    --zone $ZONE `
    --ppg $PPG_NAME `
    --vnet-name $VNET_NAME `
    --subnet "default" `
    --admin-username "azureuser" `
    --admin-password $ADMIN_PASSWORD `
    --public-ip-sku Standard `
    --accelerated-networking true `
    --security-type Standard

# Create App VM in the same PPG
Write-Host "Creating App VM: $APP_VM_NAME"
az vm create `
    --resource-group $RESOURCE_GROUP `
    --name $APP_VM_NAME `
    --image "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest" `
    --size $APP_VM_SKU `
    --location $REGION `
    --zone $ZONE `
    --ppg $PPG_NAME `
    --vnet-name $VNET_NAME `
    --subnet "default" `
    --admin-username "azureuser" `
    --admin-password $ADMIN_PASSWORD `
    --public-ip-sku Standard `
    --accelerated-networking true `
    --security-type Standard

