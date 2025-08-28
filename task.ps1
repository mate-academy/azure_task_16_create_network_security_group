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
$AllowHTTPandHTTPS = New-AzNetworkSecurityRuleConfig `
  -Name "http-rule" `
  -Description "Allow HTTP and HTTPS traffic from the Internet" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix  Internet `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80, 443

$webserversNSG =  New-AzNetworkSecurityGroup `
  -Name $webSubnetName  `
  -ResourceGroupName $resourceGroupName  `
  -Location  $location `
  -SecurityRules $AllowHTTPandHTTPS

Write-Host "Creating mngSubnet network security group..."
$AllowSSH = New-AzNetworkSecurityRuleConfig `
  -Name "ssh-rule" `
  -Description "Allow only SSH traffic from the Internet" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix  Internet `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22

$ManagementNSG =  New-AzNetworkSecurityGroup `
  -Name $mngSubnetName  `
  -ResourceGroupName $resourceGroupName  `
  -Location  $location `
  -SecurityRules $AllowSSH

Write-Host "Creating dbSubnet network security group..."

$DataBaseNSG =  New-AzNetworkSecurityGroup `
  -Name $dbSubnetName  `
  -ResourceGroupName $resourceGroupName  `
  -Location  $location

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webserversNSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $DataBaseNSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $ManagementNSG
New-AzVirtualNetwork `
  -Name $virtualNetworkName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -AddressPrefix $vnetAddressPrefix `
  -Subnet $webSubnet, $dbSubnet, $mngSubnet
