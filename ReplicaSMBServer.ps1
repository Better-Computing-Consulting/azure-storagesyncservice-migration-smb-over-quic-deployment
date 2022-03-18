#
# W202202
#

$domain = "smbdemo.dev"
$rg = "bccDevFileShareRG"
$syncservicename = "bccDevFileShareSync"
$sharename = "share1"
$sshuser = "vpndemo"
$sshserver = "ubuntuagent1"
$pfx_cert_path = ":~\w202202.bcc.bz.pfx"

"Check if domain joined"
if ( $env:USERDNSDomain -ne $domain ){ 
    Add-Computer -DomainName smbdemo.dev -Restart 
} else {
    "Setup data disk as drive F"
    $disk = Get-Disk | where-object PartitionStyle -eq "RAW"  
    $disk | Initialize-Disk -PartitionStyle GPT  
    $partition = $disk | New-Partition -UseMaximumSize -DriveLetter F  
    $partition | Format-Volume -Confirm:$false -Force  

    "Create directory for share"
    new-item -path F: -name $sharename -itemtype "directory"

    "Share directory"
    New-SmbShare -Name "share1" -Path F:\share1 -FolderEnumerationMode AccessBased -FullAccess "smbdemo\Share1Admins" -ChangeAccess "smbdemo\Share1Users"

    "Download StorageSyncAgent.msi"
    Invoke-WebRequest -Uri https://aka.ms/afs/agent/Server2022 -OutFile "StorageSyncAgent.msi" 

    "Install StorageSyncAgent.msi"
    Start-Process -FilePath "StorageSyncAgent.msi" -ArgumentList "/quiet" -Wait

    "Install-PackageProvider NuGet"
    Install-PackageProvider -Name NuGet -Force -Confirm:$false

    "Trust PSGallery"
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

    "Install Az.StorageSync module"
    Install-Module -Name Az.StorageSync -Confirm:$false   

    "Login to Azure"
    Connect-AzAccount -DeviceCode

    "Register Server in StorageSync Service"
    $registeredServer = Register-AzStorageSyncServer -ResourceGroupName $rg -StorageSyncServiceName $syncservicename

    "Get the StorageSyncGroup created in SourceSMBServer"
    $syncGroup = Get-AzStorageSyncGroup -ResourceGroupName $rg -StorageSyncServiceName $syncservicename

    "Create StorageSyncServerEndpoint"
    $serverendpoint = New-AzStorageSyncServerEndpoint `
            -Name $registeredServer.FriendlyName `
            -SyncGroup $syncGroup `
            -ServerResourceId $registeredServer.ResourceId `
            -ServerLocalPath "F:\share1" `
            -CloudTiering -VolumeFreeSpacePercent 20 
    $serverendpoint.ProvisioningState

    "Get SSL Certificate as pfx file from SSH server"
    $scpcommand = "scp -oStrictHostKeyChecking=no $sshuser@$sshserver$pfx_cert_path ." 
    Invoke-Expression $scpcommand

    "Get certificate password"
    $mypwd = Get-Credential -UserName 'Enter Cert password' -Message 'Enter Cert password'

    "Install certificate"
    Import-PfxCertificate -FilePath .\w202202.bcc.bz.pfx -CertStoreLocation Cert:\LocalMachine\My -Password $mypwd.Password
}
