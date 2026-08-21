$location = "denmarkeast"
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
New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location


Write-Host "Creating web network security group..."

$webInternetRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-Web" `
    -Description "Allow HTTP and HTTPS from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80,443

$webNsg = New-AzNetworkSecurityGroup `
    -Name $webSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $webInternetRule


Write-Host "Creating mngSubnet network security group..."

$mngInternetRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-SSH" `
    -Description "Allow SSH from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22

# $mngVnetRule = New-AzNetworkSecurityRuleConfig `
#     -Name "Allow-VNet" `
#     -Description "Allow traffic from virtual network" `
#     -Access Allow `
#     -Protocol * `
#     -Direction Inbound `
#     -Priority 200 `
#     -SourceAddressPrefix 10.20.30.0/24 `
#     -SourcePortRange * `
#     -DestinationAddressPrefix * `
#     -DestinationPortRange *

$mngNsg = New-AzNetworkSecurityGroup `
    -Name $mngSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $mngInternetRule, $mngVnetRule


Write-Host "Creating dbSubnet network security group..."

$dbVnetRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-VNet" `
    -Description "Allow traffic from virtual network" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix 10.20.30.0/24 `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange *

$dbNsg = New-AzNetworkSecurityGroup `
    -Name $dbSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $dbVnetRule


Write-Host "Creating a virtual network ..."

$webSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroupId $webNsg.Id

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroupId $dbNsg.Id

$mngSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroupId $mngNsg.Id

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet, $dbSubnet, $mngSubnet