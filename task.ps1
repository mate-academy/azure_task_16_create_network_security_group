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


Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating web network security group..."
$ruleHttp = New-AzNetworkSecurityRuleConfig -Name "allow-http" `
    -Description "HTTP" -Access Allow -Protocol Tcp -Direction Inbound `
    -Priority 100 -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 80,443

$webNsg = New-AzNetworkSecurityGroup -Name "nsg-webservers" `
    -ResourceGroupName $resourceGroupName -Location $location `
    -SecurityRules $ruleHttp

Write-Host "Creating mngSubnet network security group..."
$dbRule = New-AzNetworkSecurityRuleConfig -Name "allow-from-vnet" `
  -Description "Allow TCP from inside VNet" `
  -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
  -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange *

$dbNsg = New-AzNetworkSecurityGroup -Name "nsg-database" `
  -ResourceGroupName $resourceGroupName -Location $location `
  -SecurityRules $dbRule


Write-Host "Creating dbSubnet network security group..."
$ruleSsh = New-AzNetworkSecurityRuleConfig -Name "allow-ssh" `
    -Description "SSH" -Access Allow -Protocol Tcp -Direction Inbound `
    -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22

$mngNsg = New-AzNetworkSecurityGroup -Name "nsg-management" `
    -ResourceGroupName $resourceGroupName -Location $location `
    -SecurityRules $ruleSsh

Write-Host "Creating a virtual network ..."

$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet

