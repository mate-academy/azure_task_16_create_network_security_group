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


# =========================
# NSG: webservers (80,443)
# =========================
Write-Host "Creating web network security group..."
$webRule = New-AzNetworkSecurityRuleConfig `
  -Name "allow-http-https" `
  -Direction Inbound `
  -Access Allow `
  -Protocol Tcp `
  -Priority 100 `
  -SourceAddressPrefix "*" `
  -SourcePortRange "*" `
  -DestinationAddressPrefix "*" `
  -DestinationPortRange @("80","443")

$webNsg = New-AzNetworkSecurityGroup `
  -Name $webSubnetName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -SecurityRules $webRule

# =========================
# NSG: management (22)
# =========================
Write-Host "Creating management network security group..."
$mngRule = New-AzNetworkSecurityRuleConfig `
  -Name "allow-ssh" `
  -Direction Inbound `
  -Access Allow `
  -Protocol Tcp `
  -Priority 100 `
  -SourceAddressPrefix "*" `
  -SourcePortRange "*" `
  -DestinationAddressPrefix "*" `
  -DestinationPortRange "22"

$mngNsg = New-AzNetworkSecurityGroup `
  -Name $mngSubnetName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -SecurityRules $mngRule

# =========================
# NSG: database (NO custom rules)
# =========================
Write-Host "Creating database network security group..."
$dbNsg = New-AzNetworkSecurityGroup `
  -Name $dbSubnetName `
  -ResourceGroupName $resourceGroupName `
  -Location $location


# =========================
# VNet + subnets with NSGs attached
# =========================
Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet  = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName  -AddressPrefix $dbSubnetIpRange  -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork `
  -Name $virtualNetworkName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -AddressPrefix $vnetAddressPrefix `
  -Subnet $webSubnet, $dbSubnet, $mngSubnet

Write-Host "Done."
