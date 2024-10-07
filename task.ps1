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
$webNsgRuleHttp = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTP-HTTPS" `
    -Description "Allow HTTP at port 80 and 443" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 100 `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 80, 443

$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $webSubnetName `
    -SecurityRules $webNsgRuleHttp

Write-Host "Creating mngSubnet network security group..."
$mngNsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" `
    -Description "Allow SSH at port 22" `
    -Access "Allow" `
    -Protocol "Tcp" `
    -Direction "Inbound" `
    -Priority 150 `
    -SourceAddressPrefix "Internet" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22

$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $mngSubnetName `
    -SecurityRules $mngNsgRuleSSH

Write-Host "Creating dbSubnet network security group..."
$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $dbSubnetName

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroup $webNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet,$dbSubnet,$mngSubnet
