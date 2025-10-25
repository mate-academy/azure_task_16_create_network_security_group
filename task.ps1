$location = "uksouth"
$resourceGroupName = "mate-resources"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"

$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"

$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"

$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

# ---------------- Webservers NSG ----------------
Write-Host "Creating web network security group..."
$webRuleVnet = New-AzNetworkSecurityRuleConfig -Name "AllowVnetInBound" -Priority 100 `
  -Direction Inbound -Access Allow -Protocol * -SourceAddressPrefix VirtualNetwork `
  -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$webRuleHttp = New-AzNetworkSecurityRuleConfig -Name "AllowHTTP" -Priority 200 `
  -Direction Inbound -Access Allow -Protocol Tcp -SourceAddressPrefix Internet `
  -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

$webRuleHttps = New-AzNetworkSecurityRuleConfig -Name "AllowHTTPS" -Priority 210 `
  -Direction Inbound -Access Allow -Protocol Tcp -SourceAddressPrefix Internet `
  -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$webNsg = New-AzNetworkSecurityGroup -Name $webSubnetName -ResourceGroupName $resourceGroupName `
  -Location $location -SecurityRules $webRuleVnet,$webRuleHttp,$webRuleHttps

# ---------------- Management NSG ----------------
Write-Host "Creating mngSubnet network security group..."
$mngRuleVnet = New-AzNetworkSecurityRuleConfig -Name "AllowVnetInBound" -Priority 100 `
  -Direction Inbound -Access Allow -Protocol * -SourceAddressPrefix VirtualNetwork `
  -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$mngRuleSsh = New-AzNetworkSecurityRuleConfig -Name "AllowSSH" -Priority 200 `
  -Direction Inbound -Access Allow -Protocol Tcp -SourceAddressPrefix Internet `
  -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$mngNsg = New-AzNetworkSecurityGroup -Name $mngSubnetName -ResourceGroupName $resourceGroupName `
  -Location $location -SecurityRules $mngRuleVnet,$mngRuleSsh

# ---------------- Database NSG ----------------
Write-Host "Creating dbSubnet network security group..."
$dbRuleVnet = New-AzNetworkSecurityRuleConfig -Name "AllowVnetInBound" -Priority 100 `
  -Direction Inbound -Access Allow -Protocol * -SourceAddressPrefix VirtualNetwork `
  -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

$dbNsg = New-AzNetworkSecurityGroup -Name $dbSubnetName -ResourceGroupName $resourceGroupName `
  -Location $location -SecurityRules $dbRuleVnet

# ---------------- Virtual Network ----------------
Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet  = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName  -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName `
  -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
