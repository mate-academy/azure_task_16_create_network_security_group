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
$webRule = New-AzNetworkSecurityRuleConfig -Name http-rule `
    -Description "Allow HTTP and HTTPS" -Access Allow -Protocol Tcp `
    -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
    -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443

$webSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$webSubnetName-nsg" -SecurityRules $webRule

Write-Host "Creating mngSubnet network security group..."
# Write your code for creation of management NSG here -> 
$sshRule = New-AzNetworkSecurityRuleConfig -Name ssh-rule `
    -Description "Allow SSH" -Access Allow -Protocol Tcp `
    -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
    -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

$mngSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$mngSubnetName-nsg" -SecurityRules $sshRule

Write-Host "Creating dbSubnet network security group..."
$dbSG = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$dbSubnetName-nsg"

Write-Host "Creating a virtual network ..."

$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webSG
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbSG
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngSG

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
