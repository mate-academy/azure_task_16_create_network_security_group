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

Write-Host "Creating web network security group for subnet: $webSubnetName..."
$nsgRuleAllowHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP `
  -Description "Allow HTTP/HTTPS" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix $webSubnetIpRange `
  -DestinationPortRange 80, 8008, 8080, 443

$webNSG = New-AzNetworkSecurityGroup -Name $webSubnetName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -SecurityRules $nsgRuleAllowHTTP

Write-Host "Creating mngSubnet network security group for subnet: $mngSubnetName..."
$nsgRuleAllowSSH = New-AzNetworkSecurityRuleConfig -Name SSH `
  -Description "Allow SSH" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 900 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix $mngSubnetIpRange `
  -DestinationPortRange 22

$mngNSG = New-AzNetworkSecurityGroup -Name $mngSubnetName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -SecurityRules $nsgRuleAllowSSH

Write-Host "Creating dbSubnet network security group for subnet: $dbSubnetName..."
$dbNSG = New-AzNetworkSecurityGroup -Name $dbSubnetName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNSG
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet, $dbSubnet, $mngSubnet
