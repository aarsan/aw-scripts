az vm get-instance-view `
  --resource-group amwins-test11 `
  --name sql-vm `
  --query "instanceView.disks" `
  --output json

az vm get-instance-view `
  --resource-group amwins-test11 `
  --name app-vm `
  --query "instanceView.disks" `
  --output json
