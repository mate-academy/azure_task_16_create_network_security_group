$location = "denmarkeast"
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
$webRule = New-AzNetworkSecurityRuleConfig -Name $webSubnetName -Description "Allow HTTP and HTTPS" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix $webSubnetIpRange -DestinationPortRange 80, 443

Write-Host "Creating mngSubnet network security group..."
$mngRule = New-AzNetworkSecurityRuleConfig -Name $mngSubnetName -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix $mngSubnetIpRange -DestinationPortRange 22

Write-Host "Creating dbSubnet network security group..."


$webNsg = New-AzNetworkSecurityGroup -Name $webSubnetName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $webRule
$mngNsg = New-AzNetworkSecurityGroup -Name $mngSubnetName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $mngRule
$dbNsg = New-AzNetworkSecurityGroup -Name $dbSubnetName -ResourceGroupName $resourceGroupName -Location $location

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
