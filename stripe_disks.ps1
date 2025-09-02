#Variables
$StoragePoolName = "MyStoragePool"
$VirtualDiskName = "MyVirtualDisk"


Get-PhysicalDisk | Where-Object CanPool -eq $true | Format-Table FriendlyName, OperationalStatus, Size, MediaType


$PoolDisks = Get-PhysicalDisk | Where-Object CanPool -eq $true
New-StoragePool -FriendlyName $StoragePoolName -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $PoolDisks


New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $VirtualDiskName -ResiliencySettingName Simple -ProvisioningType Fixed -UseMaximumSize


Get-VirtualDisk -FriendlyName $VirtualDiskName | Get-Disk | Initialize-Disk -PartitionStyle GPT
Get-VirtualDisk -FriendlyName $VirtualDiskName | Get-Disk | New-Partition -DriveLetter "E" -UseMaximumSize
Format-Volume -DriveLetter "E" -FileSystem NTFS -NewFileSystemLabel "DataVolume"


Get-StoragePool -FriendlyName $StoragePoolName | Get-PhysicalDisk | Select FriendlyName, HealthStatus, OperationalStatus