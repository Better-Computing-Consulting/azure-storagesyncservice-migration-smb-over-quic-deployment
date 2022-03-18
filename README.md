# azure-storagesyncservice-migration-smb-over-quic-deployment
Ansible playbook to deploy the resources for a Windows Server 2022 Datacenter Azure Edition with a virtual network gateway connected to a Cisco ASA Firewall on premises and a secured storage account.  Two PowerShell scripts: one to deploy a StorageSyncService in azure to replicate a local share to the new storage account, and another script to setup the new Windows Server 2022 VM as a file server with a replica of the share and an SSL certificate to enable SMB over QUIC access on the public network for remote users without a VPN. 

To replicate clone your copy of the repository onto a linux server with Ansible and the azure.azcollection and cisco.asa collections, then execute the azresources.yml playblook.

This plabook is based on the one for the https://bcc.bz/post/azure-devops-ci-ansible-vpn-deployment-between-virtual-network-gateway-and-cisco-asa repository, please thake a look at this repository for more details.

After the playbook finishes, on the server containing the share you wish to migrate to azure, run the SourceSMBServer.ps1 script.

Lastly, on the new VM deployed by the Ansible Playbook run the ReplicaSMBServer.ps1 script.

For the playbook and the scripts make sure to update the variables to fit your environment.

These are the steps taken by the playbook and the scripts:

__azresources.yml__

1.  Retrieve the playbook secrets from an Azure Key Vault
2.  Deploy an Azure Resource Group
3.  Deploy a Virtual Network
4.  Deploy a Subnet with a service enpoint to Azure Storage
5.  Deploy a Gateway subnet
6.  Get the public IP of the on-prem network
7.  Deploy a storage account that allows access only to the on-prem public IP and the new subnet with the service point
8.  Deploy a public IP for a new VM
9.  Register the new public IP in DNS
10.  Deploy a new Network Security Group that restricts access to only UDP port 443 (for SMB over QUIC access)
11.  Deploy a virtual Network Interface with the address of the on-prem domain controller as its DNS server
12.  Deploy a Windows 2022 Datacenter Azure Edition Core Smalldisk Virtual Machine, to subnet with service endpoint, with new public IP and Network Security Group, and an additional data disk to host the replicated share.
13.  Deploy a Virtual Network Gateway
14.  Configure the on-prem ASA Firewall for site-to-site vpn connection to the Virtual Network Gateway.

__SourceSMBServer.ps1 (run on source file server)__

1.  Install the NuGet Package Provider
2.  Set Powershell installation policy to trust the PSGallery
3.  Install the Az.StorageSync and Az.Storage modules
4.  Login to Azure
5.  Deploy a new StorageSyncService
6.  Download and install the StorageSync agent
7.  Register the local host in the StorageSyncService
8.  Create a StorageSyncGroup under in the StorageSyncService
9.  Add a File Share to the Storage Account deployed by the Ansible playbook
10.  Create a StorageSyncCloudEndpoint for the File Share in the StorageSyncGroup
11.  Create a StorageSyncServerEndpoint for the local host in the StorageSyncGroup
12.  Download and install Windows Admin Center to enable SMB over QUIC on the Windows 2022 VM deployed by the Ansible Playbook

__ReplicaSMBServer.ps1 (run on new Windows 2022 VM)__

1. Join server to NT Domain
2. Partition and Format the additional data disk
3. Create a new directory for the share in the new drive
4. Share the folder with restricted access and FolderEnumerationMode set to AccessBased
5. Download and install the StorageSync agent
6. Install the NuGet Package Provider
7. Set Powershell installation policy to trust the PSGallery
8. Install the Az.StorageSync module
9. Login to Azure
10. Register the local host in the StorageSyncService
11. Create a StorageSyncServerEndpoint for the local host in the StorageSyncGroup
12. Download a SSL Certificate as pfx file from a SSH server (SMB over QUIC requires a 
13. 
