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
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# Clean up existing resources first
Write-Host "Cleaning up existing resources..."
Remove-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetworkName -Force -ErrorAction SilentlyContinue
Remove-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $webSubnetName -Force -ErrorAction SilentlyContinue
Remove-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $dbSubnetName -Force -ErrorAction SilentlyContinue
Remove-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $mngSubnetName -Force -ErrorAction SilentlyContinue

# Create Network Security Groups for each subnet
Write-Host "Creating web network security group..."
$webNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $webSubnetName

# Web NSG Rules - ONLY 1 RULE: Allow HTTP/HTTPS from Internet
# VNet traffic is allowed by default between subnets
$webRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowWeb-Inbound" `
    -Description "Allow HTTP and HTTPS traffic from Internet" `
    -Protocol "Tcp" `
    -SourcePortRange "*" `
    -DestinationPortRange "80","443" `
    -SourceAddressPrefix "Internet" `
    -DestinationAddressPrefix "*" `
    -Access "Allow" `
    -Priority 100 `
    -Direction "Inbound"

$webNsg.SecurityRules.Add($webRule)
$webNsg | Set-AzNetworkSecurityGroup

Write-Host "Creating management network security group..."
$mngNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $mngSubnetName

# Management NSG Rules - ONLY 1 RULE: Allow SSH from Internet
$mngRule = New-AzNetworkSecurityRuleConfig `
    -Name "AllowSSH-Inbound" `
    -Description "Allow SSH traffic from Internet" `
    -Protocol "Tcp" `
    -SourcePortRange "*" `
    -DestinationPortRange "22" `
    -SourceAddressPrefix "Internet" `
    -DestinationAddressPrefix "*" `
    -Access "Allow" `
    -Priority 100 `
    -Direction "Inbound"

$mngNsg.SecurityRules.Add($mngRule)
$mngNsg | Set-AzNetworkSecurityGroup

Write-Host "Creating database network security group..."
$dbNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $dbSubnetName

# Database NSG Rules - NO RULES (no Internet traffic allowed)
# This means only VNet traffic is allowed (default behavior)
Write-Host "Database NSG created with no rules - blocking all Internet traffic"

Write-Host "Creating a virtual network with NSG associations..."
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

$virtualNetwork = New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet, $dbSubnet, $mngSubnet

Write-Host "Virtual network and NSGs created successfully!"
Write-Host "NSG Configuration Summary:"
Write-Host "  - $webSubnetName NSG: 1 rule (HTTP/HTTPS from Internet)"
Write-Host "  - $dbSubnetName NSG: 0 rules (No Internet traffic)"
Write-Host "  - $mngSubnetName NSG: 1 rule (SSH from Internet)"
Write-Host "Note: VNet traffic between subnets is allowed by default"