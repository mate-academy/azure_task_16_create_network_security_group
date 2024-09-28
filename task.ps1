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

$ruleParamsSSH = @{
  Name                    = "AllowSSH"
  Description             = "Allow SSH traffic"
  Access                  = "Allow"
  Protocol                = "Tcp"
  Direction               = "Inbound"
  Priority                = 100
  SourceAddressPrefix     = "*"
  SourcePortRange         = "*"
  DestinationAddressPrefix= "*"
  DestinationPortRange    = "22"
}
$sshRule = New-AzNetworkSecurityRuleConfig @ruleParamsSSH

$ruleParamsHTTP = @{
  Name                    = "AllowHTTPandHTTPS"
  Description             = "Allow HTTP and HTTPS traffic"
  Access                  = "Allow"
  Protocol                = "Tcp"
  Direction               = "Inbound"
  Priority                = 200
  SourceAddressPrefix     = "*"
  SourcePortRange         = "*"
  DestinationAddressPrefix= "*"
  DestinationPortRange    = "80","443"
}
$httpRule = New-AzNetworkSecurityRuleConfig @ruleParamsHTTP

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating web network security group..."
$webServersNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName -SecurityRules $httpRule

Write-Host "Creating mngSubnet network security group..."
$mngServersNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName -SecurityRules $sshRule

Write-Host "Creating dbSubnet network security group..."
$dbServersNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webServersNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbServersNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngServersNsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
