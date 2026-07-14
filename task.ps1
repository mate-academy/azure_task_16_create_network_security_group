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

$common_rule =New-AzNetworkSecurityRuleConfig -Name AllowVnetInbound `
    -Access Allow -Protocol * -Direction Inbound -Priority 101 -SourceAddressPrefix `
    VirtualNetwork -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

Write-Host "Creating web network security group..."
$rule = New-AzNetworkSecurityRuleConfig -Name AllowHttpHttps `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange @(80,443)

$nsgWeb = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
    $webSubnetName -SecurityRules $common_rule, $rule

Write-Host "Creating mngSubnet network security group..."
$rule = New-AzNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$nsgMng = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
    $mngSubnetName -SecurityRules $common_rule, $rule
Write-Host "Creating dbSubnet network security group..."

#I comment code that create DenyAllOutbound rule because this rule block tests
#And this rule is NSG default rule at all

$rule = New-AzNetworkSecurityRuleConfig -Name DenyAllOutbound -Description "DenyAllOutbound" `
    -Access Deny -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *


$nsgDb = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
    $dbSubnetName -SecurityRules $common_rule, $rule

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $nsgWeb
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $nsgDb
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $nsgMng
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
