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

# Create NSGs
Write-Host "Creating web network security group..."
$webNSG = New-AzNetworkSecurityGroup -Name $webSubnetName -ResourceGroupName $resourceGroupName -Location $location

Write-Host "Creating management network security group..."
$mngNSG = New-AzNetworkSecurityGroup -Name $mngSubnetName -ResourceGroupName $resourceGroupName -Location $location

Write-Host "Creating database network security group..."
$dbNSG = New-AzNetworkSecurityGroup -Name $dbSubnetName -ResourceGroupName $resourceGroupName -Location $location

# Allow intra-VNet traffic on all NSGs
foreach ($nsg in @($webNSG, $mngNSG, $dbNSG)) {
    Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
        -Name "Allow-VNet-Inbound" -Priority 100 `
        -Direction Inbound -Access Allow -Protocol * -SourceAddressPrefix VirtualNetwork `
        -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

    # Apply updates
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
}

# Add Internet-facing rules
# Web: Allow HTTP/HTTPS from Internet
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNSG `
    -Name "Allow-HTTP" -Priority 200 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 80
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNSG `
    -Name "Allow-HTTPS" -Priority 210 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 443
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNSG

# Management: Allow SSH only from Internet
Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNSG `
    -Name "Allow-SSH" -Priority 200 -Direction Inbound -Access Allow -Protocol Tcp `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNSG

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
