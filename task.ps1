$location = "westus2" # any region that is available in your Azure subscription
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

Write-Host "Creating a virtual network ..."

$rule1 = New-AzNetworkSecurityRuleConfig -Name $webSubnetName -Description "Allow HTTP AND HTTPS" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80, 443

$rule2 = New-AzNetworkSecurityRuleConfig -Name $mngSubnetName -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$rule3 = New-AzNetworkSecurityRuleConfig -Name $dbSubnetName -Description "Block internet " `
    -Access Deny -Protocol * -Direction Inbound -Priority 200 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *

$allowInternal = New-AzNetworkSecurityRuleConfig -Name "AllowInternal" `
    -Access Allow -Protocol * -Direction Inbound -Priority 100 `
    -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange *

$nsgWeb = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
    "webservers" -SecurityRules $rule1

$nsgMng = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
    "management" -SecurityRules $rule2

$nsgDb = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
    "database" 

$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroupId $nsgWeb.Id
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroupId $nsgDb.Id
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroupId $nsgMng.Id
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet



