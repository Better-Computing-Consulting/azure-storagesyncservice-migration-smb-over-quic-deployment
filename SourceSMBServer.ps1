"Install-PackageProvider"
Install-PackageProvider -Name NuGet -Force -Confirm:$false
"Trust PSGallery"
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
"Install Az.StorageSync and Az.Storage modules"
Install-Module -Name Az.StorageSync -Confirm:$false 
Install-Module -Name Az.Storage -Confirm:$false 

"Login to Azure"
Connect-AzAccount

$region = 'westus'
$rg = 'bccDevFileShareRG'
$storageSyncName = "bccDevFileShareSync"
$syncGroupName = "Share1SyncGroup"
$storageAccountName = "bccdevfilesharesyncsa"
$shareName = "share1"
$localSharePath = "E:\share1"

"Deploy StorageSync Service to Azure"
$storageSync = New-AzStorageSyncService -ResourceGroupName $rg -Name $storageSyncName -Location $region

"Download StorageSync Agent"
Invoke-WebRequest -Uri https://aka.ms/afs/agent/Server2019 -OutFile "StorageSyncAgent.msi" 

"Install StorageSync Agent"
Start-Process -FilePath "StorageSyncAgent.msi" -ArgumentList "/quiet" -Wait

"Register Server in StorageSync Service"
$registeredServer = Register-AzStorageSyncServer -ParentObject $storageSync

"Create StorageSyncGroup"
$syncGroup = New-AzStorageSyncGroup -ParentObject $storageSync -Name $syncGroupName

"Add File Share to the Storage Account"
$fileShare = New-AzRmStorageShare -ResourceGroupName $rg -StorageAccountName $storageAccountName -Name $shareName -AccessTier Hot

"Get Storage Account Created in Ansible Playbook"
$storageAccount = Get-AzStorageAccount -ResourceGroupName $rg -Name $storageAccountName

"Create StorageSyncCloudEndpoint"
$cloudendpoint = New-AzStorageSyncCloudEndpoint `
    -Name $fileShare.Name `
    -ParentObject $syncGroup `
    -StorageAccountResourceId $storageAccount.Id `
    -AzureFileShareName $fileShare.Name
$cloudendpoint.ProvisioningState

"Create StorageSyncServerEndpoint"
$serverendpoint = New-AzStorageSyncServerEndpoint `
        -Name $registeredServer.FriendlyName `
        -SyncGroup $syncGroup `
        -ServerResourceId $registeredServer.ResourceId `
        -ServerLocalPath $localSharePath `
        -CloudTiering -VolumeFreeSpacePercent 20 
$serverendpoint.ProvisioningState

"Download Windows Admin Center"
Invoke-WebRequest 'https://aka.ms/WACDownload' -OutFile "WindowsAdminCenter.msi"

"Install Windows Admin Center"
Start-Process -FilePath "WindowsAdminCenter.msi" -ArgumentList "/quiet", "SME_PORT=443", "SSL_CERTIFICATE_OPTION=generate" -Wait