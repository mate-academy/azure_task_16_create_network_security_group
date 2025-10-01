$location = "uksouth"
$resourceGroupName = "mate-azure-task-16"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

$storageName   = "storageac88"
$sku           = "Standard_LRS"


Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location




Write-Host "Creating web network security group..."
# Allow VNet internal traffic
$allowVnet = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet" -Description "Allow all VNet traffic" `
  -Access Allow -Protocol * -Direction Inbound -Priority 100 `
  -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
  -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

# Allow HTTP from Internet
$allowHttp = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTP" -Description "Allow HTTP" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 80

# Allow HTTPS from Internet
$allowHttps = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTPS" -Description "Allow HTTPS" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 210 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 443

$webnsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$webSubnetName-nsg" -SecurityRules $allowVnet,$allowHttp,$allowHttps




Write-Host "Creating mngSubnet network security group..."
# Allow VNet internal traffic
$allowVnet = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet" -Description "Allow all VNet traffic" `
  -Access Allow -Protocol * -Direction Inbound -Priority 100 `
  -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
  -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

# Allow SSH from Internet
$allowSsh = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" -Description "Allow SSH" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 22

$mngnsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$mngSubnetName-nsg" -SecurityRules $allowVnet,$allowSsh




Write-Host "Creating dbSubnet network security group..."
# Allow VNet internal traffic
$allowVnet = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet" -Description "Allow all VNet traffic" `
  -Access Allow -Protocol * -Direction Inbound -Priority 100 `
  -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
  -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$dbnsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$dbSubnetName-nsg" -SecurityRules $allowVnet




Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webnsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbnsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngnsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet

New-AzStorageAccount `
  -ResourceGroupName $resourceGroupName `
  -Name $storageName `
  -Location $location `
  -SkuName $sku `
  -Kind StorageV2

$storageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageName)[0].Value
$ctx = New-AzStorageContext -StorageAccountName $storageName -StorageAccountKey $storageKey
New-AzStorageContainer -Name "task-artifacts" -Context $ctx -Permission Off