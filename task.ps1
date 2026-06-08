$location = "polandcentral"
$resourceGroupName = "mate-resources"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

$webnsgname = $webSubnetName
$mngnsgname = $mngSubnetName
$dbnsgname = $dbSubnetName

$webnsgrulenameHTTP = "HTTP/HTTPS"
$mngnsgrulenameSSH = "SSH"
$mngnsgruleNameName = "Internal"
$webnsgruleNameName = "Internal"
$dbnsgruleNameName = "Internal"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating web network security group..."
# Write your code for creation of Web NSG here -> 

Write-Host "Creating mngSubnet network security group..."
# Write your code for creation of management NSG here -> 

Write-Host "Creating dbSubnet network security group..."
# Write your code for creation of management NSG here -> 

$webnsgruleHTTP = New-AzNetworkSecurityRuleConfig -Name $webnsgrulenameHTTP -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80, 443
$webnsgruleInternal = New-AzNetworkSecurityRuleConfig -Name $webnsgruleNameName -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix "10.20.30.0/24" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80, 443
$mngnsgruleSSH = New-AzNetworkSecurityRuleConfig -Name $mngnsgrulenameSSH -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$mngnsgruleInternal = New-AzNetworkSecurityRuleConfig -Name $mngnsgruleNameName -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix "10.20.30.0/24" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$dbnsgruleInternal = New-AzNetworkSecurityRuleConfig -Name $dbnsgruleNameName -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix "10.20.30.0/24" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$webnsg = New-AzNetworkSecurityGroup -Name $webnsgname -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $webnsgruleHTTP, $webnsgruleInternal
$mngnsg = New-AzNetworkSecurityGroup -Name $mngnsgname -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $mngnsgruleSSH, $mngnsgruleInternal
$dbnsg = New-AzNetworkSecurityGroup -Name $dbnsgname -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $dbnsgruleInternal

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webnsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbnsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngnsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet