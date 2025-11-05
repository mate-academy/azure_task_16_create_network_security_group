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
$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -Name "Allow_HTTP" -Description "Allow HTTP from Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix $webSubnetIpRange -DestinationPortRange 80
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -Name "Allow_HTTPS" -Description "Allow HTTPS from Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix $webSubnetIpRange -DestinationPortRange 443
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -Name "Allow_VNet" -Description "Allow all from VNet" -Access Allow -Protocol * -Direction Inbound -Priority 120 -SourceAddressPrefix $vnetAddressPrefix -SourcePortRange * -DestinationAddressPrefix $webSubnetIpRange -DestinationPortRange *

Write-Host "Creating mngSubnet network security group..."
$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNsg -Name "Allow_SSH" -Description "Allow SSH from Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix $mngSubnetIpRange -DestinationPortRange 22
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNsg -Name "Allow_VNet" -Description "Allow all from VNet" -Access Allow -Protocol * -Direction Inbound -Priority 110 -SourceAddressPrefix $vnetAddressPrefix -SourcePortRange * -DestinationAddressPrefix $mngSubnetIpRange -DestinationPortRange *



Write-Host "Creating dbSubnet network security group..."
$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $dbNsg -Name "Deny_Internet" -Description "Deny all from Internet" -Access Deny -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix $dbSubnetIpRange -DestinationPortRange *
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $dbNsg -Name "Allow_VNet" -Description "Allow all from VNet" -Access Allow -Protocol * -Direction Inbound -Priority 110 -SourceAddressPrefix $vnetAddressPrefix -SourcePortRange * -DestinationAddressPrefix $dbSubnetIpRange -DestinationPortRange *


Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNsg
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg