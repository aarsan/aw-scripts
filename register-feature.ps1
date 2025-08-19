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
Write-Host "Setting Azure subscription: $SUBSCRIPTION_ID"
az account set --subscription $SUBSCRIPTION_ID

# Check current feature registration status
Write-Host "Checking current feature registration status..."
$featureStatus = az feature show --namespace "Microsoft.Compute" --name "UseStandardSecurityType" --output json | ConvertFrom-Json

if ($featureStatus.properties.state -eq "Registered") {
    Write-Host "Feature 'Microsoft.Compute\UseStandardSecurityType' is already registered!" -ForegroundColor Green
} else {
    Write-Host "Current feature status: $($featureStatus.properties.state)" -ForegroundColor Yellow
    
    # Register the feature
    Write-Host "Registering feature 'Microsoft.Compute\UseStandardSecurityType'..."
    az feature register --namespace "Microsoft.Compute" --name "UseStandardSecurityType"
    
    Write-Host "Feature registration initiated. This may take several minutes to complete." -ForegroundColor Yellow
    Write-Host "You can check the status with:" -ForegroundColor Cyan
    Write-Host "az feature show --namespace 'Microsoft.Compute' --name 'UseStandardSecurityType'" -ForegroundColor Cyan
    
    # Wait for registration to complete
    Write-Host "Waiting for feature registration to complete..."
    do {
        Start-Sleep -Seconds 30
        $featureStatus = az feature show --namespace "Microsoft.Compute" --name "UseStandardSecurityType" --output json | ConvertFrom-Json
        Write-Host "Current status: $($featureStatus.properties.state)"
    } while ($featureStatus.properties.state -eq "Registering")
    
    if ($featureStatus.properties.state -eq "Registered") {
        Write-Host "Feature successfully registered!" -ForegroundColor Green
        
        # Re-register the resource provider to ensure the feature is available
        Write-Host "Re-registering Microsoft.Compute resource provider..."
        az provider register --namespace "Microsoft.Compute"
        Write-Host "Resource provider re-registration completed." -ForegroundColor Green
    } else {
        Write-Error "Feature registration failed. Current status: $($featureStatus.properties.state)"
        exit 1
    }
}

Write-Host "Script completed successfully!" -ForegroundColor Green
Write-Host "You can now use '--security-type Standard' in your VM deployments." -ForegroundColor Cyan
