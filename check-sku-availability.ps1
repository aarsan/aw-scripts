# VM SKU Availability Checker Script
# This script checks if a VM SKU is available in a specific region and availability zone

param(
    [Parameter(Mandatory=$true)]
    [string]$SKU,
    
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [Parameter(Mandatory=$true)]
    [string]$AvailabilityZone
)

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\check-sku-availability.ps1 -SKU <vm-sku> -Region <azure-region> -AvailabilityZone <zone-number>"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\check-sku-availability.ps1 -SKU 'Standard_M48bds_v3' -Region 'eastus2' -AvailabilityZone '2'"
    Write-Host "  .\check-sku-availability.ps1 -SKU 'Standard_D2s_v5' -Region 'westus2' -AvailabilityZone '1'"
    Write-Host ""
}

# Validate parameters
if ([string]::IsNullOrWhiteSpace($SKU) -or [string]::IsNullOrWhiteSpace($Region) -or [string]::IsNullOrWhiteSpace($AvailabilityZone)) {
    Write-Error "All parameters are required."
    Show-Usage
    exit 1
}

# Validate availability zone is a number
if (-not ($AvailabilityZone -match "^[1-3]$")) {
    Write-Error "Availability zone must be 1, 2, or 3."
    Show-Usage
    exit 1
}

Write-Host "Checking VM SKU availability..." -ForegroundColor Cyan
Write-Host "SKU: $SKU" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Availability Zone: $AvailabilityZone" -ForegroundColor Yellow
Write-Host ""

try {
    # Check if user is logged into Azure CLI
    $accountInfo = az account show 2>$null
    if (-not $accountInfo) {
        Write-Error "Please log in to Azure CLI first using 'az login'"
        exit 1
    }

    # Get VM sizes available in the region
    Write-Host "Fetching available VM sizes in region $Region..." -ForegroundColor Gray
    $vmSizes = az vm list-skus --location $Region --output json | ConvertFrom-Json
    
    # Check if the SKU exists in the region
    $skuExists = $vmSizes | Where-Object { $_.name -eq $SKU }
    
    if (-not $skuExists) {
        Write-Host "❌ SKU '$SKU' is NOT available in region '$Region'" -ForegroundColor Red
        Write-Host ""
        Write-Host "Available SKUs in $Region that contain '$($SKU.Split('_')[1])':" -ForegroundColor Cyan
        $similarSkus = $vmSizes | Where-Object { $_.name -like "*$($SKU.Split('_')[1])*" } | Select-Object -First 10
        if ($similarSkus) {
            foreach ($sku in $similarSkus) {
                Write-Host "  - $($sku.name)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  No similar SKUs found." -ForegroundColor Gray
        }
        exit 1
    }

    Write-Host "✅ SKU '$SKU' is available in region '$Region'" -ForegroundColor Green
    
    # Display SKU details
    Write-Host ""
    Write-Host "SKU Details:" -ForegroundColor Cyan
    Write-Host "  vCPUs: $($skuExists.numberOfCores)" -ForegroundColor Gray
    Write-Host "  Memory: $([math]::Round($skuExists.memoryInMB / 1024, 2)) GB" -ForegroundColor Gray
    Write-Host "  Max Data Disks: $($skuExists.maxDataDiskCount)" -ForegroundColor Gray
    Write-Host "  OS Disk Size: $($skuExists.osDiskSizeInMB) MB" -ForegroundColor Gray
    
    # Check availability zones for the region
    Write-Host ""
    Write-Host "Checking availability zone support..." -ForegroundColor Gray
    $zoneInfo = az vm list-skus --location $Region --size $SKU --output json | ConvertFrom-Json
    
    if ($zoneInfo -and $zoneInfo.Count -gt 0) {
        $skuInfo = $zoneInfo[0]
        
        # Check if zones are supported
        if ($skuInfo.locationInfo -and $skuInfo.locationInfo[0].zones) {
            $supportedZones = $skuInfo.locationInfo[0].zones
            Write-Host "✅ Availability zones supported: $($supportedZones -join ', ')" -ForegroundColor Green
            
            if ($supportedZones -contains $AvailabilityZone) {
                Write-Host "✅ Zone '$AvailabilityZone' is supported for SKU '$SKU' in region '$Region'" -ForegroundColor Green
            } else {
                Write-Host "❌ Zone '$AvailabilityZone' is NOT supported for SKU '$SKU' in region '$Region'" -ForegroundColor Red
                Write-Host "   Supported zones: $($supportedZones -join ', ')" -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "❌ SKU '$SKU' does not support availability zones in region '$Region'" -ForegroundColor Red
            exit 1
        }
        
        # Check for any restrictions
        if ($skuInfo.restrictions -and $skuInfo.restrictions.Count -gt 0) {
            Write-Host ""
            Write-Host "⚠️  Restrictions found:" -ForegroundColor Yellow
            foreach ($restriction in $skuInfo.restrictions) {
                Write-Host "  - Type: $($restriction.type)" -ForegroundColor Red
                Write-Host "    Reason: $($restriction.reasonCode)" -ForegroundColor Red
                if ($restriction.restrictionInfo.zones) {
                    Write-Host "    Affected Zones: $($restriction.restrictionInfo.zones -join ', ')" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "❌ Could not retrieve zone information for SKU '$SKU'" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✅ All checks passed! SKU '$SKU' is available in region '$Region' zone '$AvailabilityZone'" -ForegroundColor Green
    
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
