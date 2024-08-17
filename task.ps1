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
$webNsgRuleHttp = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTP" `
  -Description "Allow HTTP traffic from the Internet" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80

$webNsgRuleHttps = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTPS" `
  -Description "Allow HTTPS traffic from the Internet" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 110 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 443

$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
  -Name "$webSubnetName-nsg" -SecurityRules $webNsgRuleHttp, $webNsgRuleHttps

Write-Host "Creating mngSubnet network security group..."
$mngNsgRuleSsh = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" `
  -Description "Allow SSH traffic from the Internet" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22

$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
  -Name "$mngSubnetName-nsg" -SecurityRules $mngNsgRuleSsh

Write-Host "Creating dbSubnet network security group..."
$dbNsgRuleSql = New-AzNetworkSecurityRuleConfig -Name "Allow-SQL" `
  -Description "Allow SQL traffic" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 1433

$dbNsgRuleMySql = New-AzNetworkSecurityRuleConfig -Name "Allow-MySQL" `
  -Description "Allow MySQL traffic" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 110 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 3306

$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
  -Name "$dbSubnetName-nsg" -SecurityRules $dbNsgRuleSql, $dbNsgRuleMySql

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
