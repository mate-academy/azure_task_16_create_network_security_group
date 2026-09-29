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
# Write your code for creation of Web NSG here ->

Write-Host "Creating mngSubnet network security group..."
# Write your code for creation of management NSG here ->

Write-Host "Creating dbSubnet network security group..."
# Write your code for creation of management NSG here ->

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet

# -----------------------------------
# Webservers NSG
# -----------------------------------

Write-Host "Creating web network security group..."

$webRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTP-HTTPS" `
    -Description "Allow HTTP and HTTPS traffic from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80,443

$webNsg = New-AzNetworkSecurityGroup `
    -Name $webSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $webRule


# -----------------------------------
# Management NSG
# -----------------------------------

Write-Host "Creating mngSubnet network security group..."

$sshRule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow-SSH" `
    -Description "Allow SSH traffic from Internet" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22

$mngNsg = New-AzNetworkSecurityGroup `
    -Name $mngSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $sshRule

# -----------------------------------
# Database NSG
# -----------------------------------

Write-Host "Creating dbSubnet network security group..."

$dbNsg = New-AzNetworkSecurityGroup `
    -Name $dbSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location


# -----------------------------------
# Virtual Network + Subnets
# -----------------------------------

Write-Host "Creating a virtual network ..."

$webSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroup $webNsg

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroup $dbNsg

$mngSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet,$dbSubnet,$mngSubnet

