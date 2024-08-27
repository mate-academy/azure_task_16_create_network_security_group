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
$httpRule = New-AzNetworkSecurityRuleConfig -Name http-rule -Description "Allow HTTP/HTTPS" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80, 443
$webSG = New-AzNetworkSecurityGroup -Name $webSubnetName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $httpRule

Write-Host "Creating mngSubnet network security group..."
$sshRule = New-AzNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$mngSG = New-AzNetworkSecurityGroup -Name $mngSubnetName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $sshRule

Write-Host "Creating dbSubnet network security group..."
$dbSG = New-AzNetworkSecurityGroup -Name $dbSubnetName -ResourceGroupName $resourceGroupName -Location $location

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngSG
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet, $dbSubnet, $mngSubnet

