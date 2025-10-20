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
$web_rule_http = New-AzNetworkSecurityRuleConfig `
    -Name "HTTP_Rule" `
    -Description "Allow HTTP and HTTPS" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix $webSubnetIpRange `
    -DestinationPortRanges @('80','443')

$web_Vnet_rule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow_Traffic_From_VNet" `
    -Description "Allow traffic from other subnets from the same VNet" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange *

$web_nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName -SecurityRules $web_rule_http, $web_Vnet_rule

Write-Host "Creating mngSubnet network security group..."
$mng_rule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow_SSH" `
    -Description "Allow SSH" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix $mngSubnetIpRange `
    -DestinationPortRange 22

$mng_Vnet_rule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow_Traffic_From_VNet" `
    -Description "Allow traffic from other subnets from the same VNet" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange *

$mng_nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName -SecurityRules $mng_rule, $mng_Vnet_rule

Write-Host "Creating dbSubnet network security group..."
$db_Vnet_rule = New-AzNetworkSecurityRuleConfig `
    -Name "Allow_Traffic_From_VNet" `
    -Description "Allow traffic from other subnets within the same VNet" `
    -Access Allow `
    -Protocol * `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange *

$db_nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName -SecurityRules $db_Vnet_rule


Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $web_nsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $db_nsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mng_nsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
