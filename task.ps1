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
$nsgRuleHttpHttps = New-AzNetworkSecurityRuleConfig `
-Name "HttpAndHttps" `
-Protocol Tcp `
-Direction Inbound `
-Priority 100 `
-SourceAddressPrefix * `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 80,443 `
-Access Allow;

$nsgWeb = New-AzNetworkSecurityGroup `
-Name $webSubnetName `
-ResourceGroupName $resourceGroupName `
-Location $location `
-SecurityRules $nsgRuleHttpHttps;

Write-Host "Creating mngSubnet network security group..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
-Name SSH `
-Protocol Tcp `
-Direction Inbound `
-Priority 1001 `
-SourceAddressPrefix * `
-SourcePortRange * `
-DestinationAddressPrefix * `
-DestinationPortRange 22 `
-Access Allow;

$nsgMng = New-AzNetworkSecurityGroup `
-Name $mngSubnetName `
-ResourceGroupName $resourceGroupName `
-Location $location `
-SecurityRules $nsgRuleSSH;

Write-Host "Creating dbSubnet network security group..."

$nsgDb = New-AzNetworkSecurityGroup `
-Name $dbSubnetName `
-ResourceGroupName $resourceGroupName `
-Location $location `

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig `
-Name $webSubnetName `
-AddressPrefix $webSubnetIpRange `
-NetworkSecurityGroup $nsgWeb

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
-Name $dbSubnetName `
-AddressPrefix $dbSubnetIpRange `
-NetworkSecurityGroup $nsgDb

$mngSubnet = New-AzVirtualNetworkSubnetConfig `
-Name $mngSubnetName `
-AddressPrefix $mngSubnetIpRange `
-NetworkSecurityGroup $nsgMng

New-AzVirtualNetwork `
-Name $virtualNetworkName `
-ResourceGroupName $resourceGroupName `
-Location $location `
-AddressPrefix $vnetAddressPrefix `
-Subnet $webSubnet,$dbSubnet,$mngSubnet
