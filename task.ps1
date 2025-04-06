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

$webSubnetrule1 = New-AzNetworkSecurityRuleConfig -Name web_sub_rule_1 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix `
    $webSubnetIpRange -SourcePortRange * -DestinationAddressPrefix $mngSubnetIpRange `
    -DestinationPortRange *
$webSubnetrule2 = New-AzNetworkSecurityRuleConfig -Name web_sub_rule_2 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 900 -SourceAddressPrefix `
    $webSubnetIpRange -SourcePortRange * -DestinationAddressPrefix $dbSubnetIpRange `
    -DestinationPortRange *
$webSubnetrule3 = New-AzNetworkSecurityRuleConfig -Name web_sub_rule_3 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 80

$webSubnetnsg = New-AzNetworkSecurityGroup -Name $webSubnetName -ResourceGroupName $resourceGroupName  -Location  $location -SecurityRules $webSubnetrule1, $webSubnetrule2, $webSubnetrule3


Write-Host "Creating mngSubnet network security group..."
# Write your code for creation of management NSG here -> 
$mngSubnetrule1 = New-AzNetworkSecurityRuleConfig -Name mng_sub_rule_1 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix `
    $mngSubnetIpRange -SourcePortRange * -DestinationAddressPrefix $webSubnetIpRange `
    -DestinationPortRange *
$mngSubnetrule2 = New-AzNetworkSecurityRuleConfig -Name mng_sub_rule_2 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 900 -SourceAddressPrefix `
    $mngSubnetIpRange -SourcePortRange * -DestinationAddressPrefix $dbSubnetIpRange `
    -DestinationPortRange *
$mngSubnetrule3 = New-AzNetworkSecurityRuleConfig -Name mng_sub_rule_3 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 22

$mngSubnetnsg = New-AzNetworkSecurityGroup -Name $mngSubnetName -ResourceGroupName $resourceGroupName  -Location  $location -SecurityRules $mngSubnetrule1, $mngSubnetrule2, $mngSubnetrule3



Write-Host "Creating dbSubnet network security group..."
# Write your code for creation of management NSG here ->
$dbSubnetrule1 = New-AzNetworkSecurityRuleConfig -Name db_sub_rule_1 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix `
    $dbSubnetIpRange -SourcePortRange * -DestinationAddressPrefix $webSubnetIpRange `
    -DestinationPortRange *
$dbSubnetrule2 = New-AzNetworkSecurityRuleConfig -Name db_sub_rule_2 `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 900 -SourceAddressPrefix `
    $dbSubnetIpRange -SourcePortRange * -DestinationAddressPrefix $mngSubnetIpRange `
    -DestinationPortRange *
$dbSubnetrule3 = New-AzNetworkSecurityRuleConfig -Name db_sub_rule_3 `
    -Access Deny -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange *

$dbSubnetnsg = New-AzNetworkSecurityGroup -Name $dbSubnetName -ResourceGroupName $resourceGroupName  -Location  $location -SecurityRules $dbSubnetrule1, $dbSubnetrule2, $dbSubnetrule3



Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webSubnetnsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbSubnetnsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngSubnetnsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
