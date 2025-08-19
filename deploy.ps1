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

$sql_vm_sku = "Standard_L8s_v3"
$app_vm_sku = "Standard_L8s_v3"
$region = "eastus2"
$ppg_name = "sql-app"
$zone = 2

# Create Resource Group
Write-Host "Creating Resource Group: $RESOURCE_GROUP"
az group create `
    --name $RESOURCE_GROUP `
    --location $region

# Create Virtual Network
Write-Host "Creating Virtual Network: $VNET_NAME"
az network vnet create `
    --resource-group $RESOURCE_GROUP `
    --name $VNET_NAME `
    --location $region `
    --address-prefixes "10.0.0.0/16" `
    --subnet-name "default" `
    --subnet-prefixes "10.0.1.0/24"

# Create Proximity Placement Group
Write-Host "Creating Proximity Placement Group: $ppg_name"
az ppg create `
    --resource-group $RESOURCE_GROUP `
    --name $ppg_name `
    --location $region `
    --type Standard

# Create SQL VM in the PPG
Write-Host "Creating SQL VM: $SQL_VM_NAME"
az vm create `
    --resource-group $RESOURCE_GROUP `
    --name $SQL_VM_NAME `
    --image "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest" `
    --size $sql_vm_sku `
    --location $region `
    --zone $zone `
    --ppg $ppg_name `
    --vnet-name $VNET_NAME `
    --subnet "default" `
    --admin-username "azureuser" `
    --admin-password $ADMIN_PASSWORD `
    --public-ip-sku Standard `
    --accelerated-networking true

# Create App VM in the same PPG
Write-Host "Creating App VM: $APP_VM_NAME"
az vm create `
    --resource-group $RESOURCE_GROUP `
    --name $APP_VM_NAME `
    --image "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest" `
    --size $app_vm_sku `
    --location $region `
    --zone $zone `
    --ppg $ppg_name `
    --vnet-name $VNET_NAME `
    --subnet "default" `
    --admin-username "azureuser" `
    --admin-password $ADMIN_PASSWORD `
    --public-ip-sku Standard `
    --accelerated-networking true

