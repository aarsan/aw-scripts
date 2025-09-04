#Variables
$StoragePoolName = "MyStoragePool"
$LogsVirtualDiskName = "LogsVirtualDisk"
$DataVirtualDiskName = "DataVirtualDisk"

# Disk size configuration (adjust as needed)
$LogsDiskSizeGB = 8  # Size for F drive (logs) in GB - minimum appears to be 8GB
$DataDiskSizeGB = 0  # Size for G drive (data) in GB - 0 means use remaining space

# Convert to exact bytes to avoid rounding issues
$LogsDiskSizeBytes = [int64]($LogsDiskSizeGB * 1073741824)  # 1GB = 1073741824 bytes


Get-PhysicalDisk | Where-Object CanPool -eq $true | Format-Table FriendlyName, OperationalStatus, Size, MediaType


# Cleanup existing virtual disks and storage pools
Write-Host "Cleaning up existing virtual disks and storage pools..." -ForegroundColor Yellow

# Remove existing virtual disks if they exist
try {
    $existingLogsVD = Get-VirtualDisk -FriendlyName $LogsVirtualDiskName -ErrorAction SilentlyContinue
    if ($existingLogsVD) {
        Write-Host "Removing existing virtual disk: $LogsVirtualDiskName" -ForegroundColor Yellow
        Remove-VirtualDisk -FriendlyName $LogsVirtualDiskName -Confirm:$false
    }
} catch {
    Write-Host "No existing logs virtual disk found or error removing it: $($_.Exception.Message)" -ForegroundColor Gray
}

try {
    $existingDataVD = Get-VirtualDisk -FriendlyName $DataVirtualDiskName -ErrorAction SilentlyContinue
    if ($existingDataVD) {
        Write-Host "Removing existing virtual disk: $DataVirtualDiskName" -ForegroundColor Yellow
        Remove-VirtualDisk -FriendlyName $DataVirtualDiskName -Confirm:$false
    }
} catch {
    Write-Host "No existing data virtual disk found or error removing it: $($_.Exception.Message)" -ForegroundColor Gray
}

# Remove existing storage pool if it exists
try {
    $existingPool = Get-StoragePool -FriendlyName $StoragePoolName -ErrorAction SilentlyContinue
    if ($existingPool -and $existingPool.IsPrimordial -eq $false) {
        Write-Host "Removing existing storage pool: $StoragePoolName" -ForegroundColor Yellow
        Remove-StoragePool -FriendlyName $StoragePoolName -Confirm:$false
    }
} catch {
    Write-Host "No existing storage pool found or error removing it: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host "Cleanup completed. Creating new storage pool and virtual disks..." -ForegroundColor Green


$PoolDisks = Get-PhysicalDisk | Where-Object CanPool -eq $true
New-StoragePool -FriendlyName $StoragePoolName -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $PoolDisks


# Create Logs Virtual Disk (F drive)
if ($LogsDiskSizeGB -gt 0) {
    Write-Host "Creating logs virtual disk with size: $LogsDiskSizeGB GB ($LogsDiskSizeBytes bytes)" -ForegroundColor Cyan
    New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $LogsVirtualDiskName -ResiliencySettingName Simple -ProvisioningType Fixed -Size $LogsDiskSizeBytes
    
    # Display actual size created
    $createdLogsVD = Get-VirtualDisk -FriendlyName $LogsVirtualDiskName
    $actualSizeGB = [math]::Round($createdLogsVD.Size / 1GB, 2)
    Write-Host "Logs virtual disk created with actual size: $actualSizeGB GB" -ForegroundColor Cyan
} else {
    Write-Error "Logs disk size must be greater than 0 GB"
    exit 1
}

# Create Data Virtual Disk (G drive) - use remaining space
if ($DataDiskSizeGB -gt 0) {
    $DataDiskSizeBytes = $DataDiskSizeGB * 1GB
    Write-Host "Creating data virtual disk with size: $DataDiskSizeGB GB ($DataDiskSizeBytes bytes)" -ForegroundColor Cyan
    New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $DataVirtualDiskName -ResiliencySettingName Simple -ProvisioningType Fixed -Size $DataDiskSizeBytes
} else {
    # Use maximum remaining size
    Write-Host "Creating data virtual disk using maximum remaining size" -ForegroundColor Cyan
    New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $DataVirtualDiskName -ResiliencySettingName Simple -ProvisioningType Fixed -UseMaximumSize
}

# Display actual size created for data disk
$createdDataVD = Get-VirtualDisk -FriendlyName $DataVirtualDiskName
$actualDataSizeGB = [math]::Round($createdDataVD.Size / 1GB, 2)
Write-Host "Data virtual disk created with actual size: $actualDataSizeGB GB" -ForegroundColor Cyan


# Initialize and format Logs disk (F drive)
Get-VirtualDisk -FriendlyName $LogsVirtualDiskName | Get-Disk | Initialize-Disk -PartitionStyle GPT
Get-VirtualDisk -FriendlyName $LogsVirtualDiskName | Get-Disk | New-Partition -DriveLetter "F" -UseMaximumSize
Format-Volume -DriveLetter "F" -FileSystem NTFS -NewFileSystemLabel "LogsVolume"

# Initialize and format Data disk (G drive)
Get-VirtualDisk -FriendlyName $DataVirtualDiskName | Get-Disk | Initialize-Disk -PartitionStyle GPT
Get-VirtualDisk -FriendlyName $DataVirtualDiskName | Get-Disk | New-Partition -DriveLetter "G" -UseMaximumSize
Format-Volume -DriveLetter "G" -FileSystem NTFS -NewFileSystemLabel "DataVolume"


Get-StoragePool -FriendlyName $StoragePoolName | Get-PhysicalDisk | Select FriendlyName, HealthStatus, OperationalStatus