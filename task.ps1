$location =                   "uksouth"
$resourceGroupName =          "mate-azure-task-16"

$virtualNetworkName =         "todoapp"
$vnetAddressPrefix =          "10.20.30.0/24"

$webSubnetName =              "webservers"
$webSubnetIpRange =           "10.20.30.0/26"

$dbSubnetName =               "database"
$dbSubnetIpRange =            "10.20.30.64/26"

$mngSubnetName =              "management"
$mngSubnetIpRange =           "10.20.30.128/26"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup `
  -Name                       $resourceGroupName `
  -Location                   $location

Write-Host "Creating webSubnet network security group..."
$webrule = New-AzNetworkSecurityRuleConfig `
  -Name                       "web-rule" `
  -Description                "Allow inbound HTTP/HTTPS" `
  -Access                     "Allow" `
  -Protocol                   "Tcp" `
  -Direction                  "Inbound" `
  -Priority                   102 `
  -SourceAddressPrefix        "Internet" `
  -SourcePortRange            * `
  -DestinationAddressPrefix   $webSubnetIpRange `
  -DestinationPortRange       80, 443
New-AzNetworkSecurityGroup `
  -Name                       $webSubnetName `
  -ResourceGroupName          $resourceGroupName `
  -Location                   $location `
  -SecurityRules              $webrule
$webNSG = Get-AzNetworkSecurityGroup `
  -Name                       $webSubnetName `
  -ResourceGroupName          $resourceGroupName

Write-Host "Creating dbSubnet network security group..."
New-AzNetworkSecurityGroup `
  -Name                       $dbSubnetName `
  -ResourceGroupName          $resourceGroupName `
  -Location                   $location
$dbNSG = Get-AzNetworkSecurityGroup `
  -Name                       $dbSubnetName `
  -ResourceGroupName          $resourceGroupName

Write-Host "Creating mngSubnet network security group..."
$mngSSHrule = New-AzNetworkSecurityRuleConfig `
  -Name                       "ssh-rule" `
  -Description                "Allow inbound traffic for SSH connections" `
  -Access                     "Allow" `
  -Protocol                   "Tcp" `
  -Direction                  "Inbound" `
  -Priority                   102 `
  -SourceAddressPrefix        "Internet" `
  -SourcePortRange            * `
  -DestinationAddressPrefix   $mngSubnetIpRange `
  -DestinationPortRange       22
New-AzNetworkSecurityGroup `
  -Name                       $mngSubnetName `
  -ResourceGroupName          $resourceGroupName `
  -Location                   $location `
  -SecurityRules              $mngSSHrule
$mngNSG = Get-AzNetworkSecurityGroup `
  -Name                       $mngSubnetName `
  -ResourceGroupName          $resourceGroupName

Write-Host "Creating a virtual network $virtualNetworkName ..."
$webSubnetConfig =  New-AzVirtualNetworkSubnetConfig `
  -Name                       $webSubnetName `
  -AddressPrefix              $webSubnetIpRange `
  -NetworkSecurityGroup       $webNSG

$dbSubnetConfig =   New-AzVirtualNetworkSubnetConfig `
  -Name                       $dbSubnetName `
  -AddressPrefix              $dbSubnetIpRange `
  -NetworkSecurityGroup       $dbNSG

$mngSubnetConfig =  New-AzVirtualNetworkSubnetConfig `
  -Name                       $mngSubnetName `
  -AddressPrefix              $mngSubnetIpRange `
  -NetworkSecurityGroup       $mngNSG

New-AzVirtualNetwork `
  -Name                       $virtualNetworkName `
  -ResourceGroupName          $resourceGroupName `
  -Location                   $location `
  -AddressPrefix              $vnetAddressPrefix `
  -Subnet                     $webSubnetConfig,`
                              $dbSubnetConfig,`
                              $mngSubnetConfig
