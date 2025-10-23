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

Write-Host "Creating web network security group..."
# Два правила: HTTP/HTTPS из интернета + весь трафик из VNet
$webNsgRuleInternet = New-AzNetworkSecurityRuleConfig -Name "Allow-Web" `
    -Description "Allow HTTP and HTTPS from Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange "80","443"

$webNsgRuleVNet = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet" `
    -Description "Allow all traffic from VNet" -Access Allow -Protocol * -Direction Inbound -Priority 110 `
    -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange *

$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName `
    -SecurityRules $webNsgRuleInternet, $webNsgRuleVNet

Write-Host "Creating management network security group..."
# Два правила: SSH из интернета + весь трафик из VNet
$mngNsgRuleInternet = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" `
    -Description "Allow SSH from Internet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22

$mngNsgRuleVNet = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet" `
    -Description "Allow all traffic from VNet" -Access Allow -Protocol * -Direction Inbound -Priority 110 `
    -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange *

$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName `
    -SecurityRules $mngNsgRuleInternet, $mngNsgRuleVNet

Write-Host "Creating database network security group..."
# NSG для database БЕЗ правил (полагается на дефолтные правила Azure)
$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName

Write-Host "Creating a virtual network with attached NSGs..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet, $dbSubnet, $mngSubnet
