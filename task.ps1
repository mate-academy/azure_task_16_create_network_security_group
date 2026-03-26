$location = "canadacentral"
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
$webserverInboundHTTPS = New-AzNetworkSecurityRuleConfig `
    -Name "WebserverAllowHTTPS" `
    -Protocol "Tcp" `
    -Access "Allow" `
    -Direction "Inbound" `
    -Priority 100 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 443,80

$webserverNsg = New-AzNetworkSecurityGroup `
    -Name $webSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $webserverInboundHTTPS


Write-Host "Creating mngSubnet network security group..."
$managementInboudSSH = New-AzNetworkSecurityRuleConfig `
    -Name "ManagementInboudSSH" `
    -Protocol "Tcp" `
    -Access "Allow" `
    -Direction "Inbound" `
    -Priority 100 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22

$managementNsg = New-AzNetworkSecurityGroup `
    -Name $mngSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $managementInboudSSH

Write-Host "Creating dbSubnet network security group..."
$dbNsg = New-AzNetworkSecurityGroup `
    -Name $dbSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webserverNsg
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $managementNsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
