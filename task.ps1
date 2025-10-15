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
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# Create Network Security Groups for each subnet
Write-Host "Creating web network security group..."
$webNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $webSubnetName

# Web NSG Rules - Only HTTP/HTTPS from Internet and all traffic from VNet
$webRules = @(
    @{
        Name                     = "AllowHTTP-Inbound"
        Description              = "Allow HTTP traffic from Internet"
        Protocol                 = "Tcp"
        SourcePortRange          = "*"
        DestinationPortRange     = "80"
        SourceAddressPrefix      = "Internet"
        DestinationAddressPrefix = "*"
        Access                   = "Allow"
        Priority                 = 100
        Direction                = "Inbound"
    },
    @{
        Name                     = "AllowHTTPS-Inbound"
        Description              = "Allow HTTPS traffic from Internet"
        Protocol                 = "Tcp"
        SourcePortRange          = "*"
        DestinationPortRange     = "443"
        SourceAddressPrefix      = "Internet"
        DestinationAddressPrefix = "*"
        Access                   = "Allow"
        Priority                 = 110
        Direction                = "Inbound"
    },
    @{
        Name                     = "AllowVNet-Inbound"
        Description              = "Allow all traffic from VNet"
        Protocol                 = "*"
        SourcePortRange          = "*"
        DestinationPortRange     = "*"
        SourceAddressPrefix      = "VirtualNetwork"
        DestinationAddressPrefix = "*"
        Access                   = "Allow"
        Priority                 = 120
        Direction                = "Inbound"
    }
)

foreach ($rule in $webRules) {
    $securityRule = New-AzNetworkSecurityRuleConfig `
        -Name $rule.Name `
        -Description $rule.Description `
        -Protocol $rule.Protocol `
        -SourcePortRange $rule.SourcePortRange `
        -DestinationPortRange $rule.DestinationPortRange `
        -SourceAddressPrefix $rule.SourceAddressPrefix `
        -DestinationAddressPrefix $rule.DestinationAddressPrefix `
        -Access $rule.Access `
        -Priority $rule.Priority `
        -Direction $rule.Direction
    
    $webNsg.SecurityRules.Add($securityRule)
}

$webNsg | Set-AzNetworkSecurityGroup

Write-Host "Creating management network security group..."
$mngNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $mngSubnetName

# Management NSG Rules - Only SSH from Internet and all traffic from VNet
$mngRules = @(
    @{
        Name                     = "AllowSSH-Inbound"
        Description              = "Allow SSH traffic from Internet"
        Protocol                 = "Tcp"
        SourcePortRange          = "*"
        DestinationPortRange     = "22"
        SourceAddressPrefix      = "Internet"
        DestinationAddressPrefix = "*"
        Access                   = "Allow"
        Priority                 = 100
        Direction                = "Inbound"
    },
    @{
        Name                     = "AllowVNet-Inbound"
        Description              = "Allow all traffic from VNet"
        Protocol                 = "*"
        SourcePortRange          = "*"
        DestinationPortRange     = "*"
        SourceAddressPrefix      = "VirtualNetwork"
        DestinationAddressPrefix = "*"
        Access                   = "Allow"
        Priority                 = 110
        Direction                = "Inbound"
    }
)

foreach ($rule in $mngRules) {
    $securityRule = New-AzNetworkSecurityRuleConfig `
        -Name $rule.Name `
        -Description $rule.Description `
        -Protocol $rule.Protocol `
        -SourcePortRange $rule.SourcePortRange `
        -DestinationPortRange $rule.DestinationPortRange `
        -SourceAddressPrefix $rule.SourceAddressPrefix `
        -DestinationAddressPrefix $rule.DestinationAddressPrefix `
        -Access $rule.Access `
        -Priority $rule.Priority `
        -Direction $rule.Direction
    
    $mngNsg.SecurityRules.Add($securityRule)
}

$mngNsg | Set-AzNetworkSecurityGroup

Write-Host "Creating database network security group..."
$dbNsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $dbSubnetName

# Database NSG Rules - Only VNet traffic (no Internet)
$dbRules = @(
    @{
        Name                     = "AllowVNet-Inbound"
        Description              = "Allow all traffic from VNet"
        Protocol                 = "*"
        SourcePortRange          = "*"
        DestinationPortRange     = "*"
        SourceAddressPrefix      = "VirtualNetwork"
        DestinationAddressPrefix = "*"
        Access                   = "Allow"
        Priority                 = 100
        Direction                = "Inbound"
    }
)

foreach ($rule in $dbRules) {
    $securityRule = New-AzNetworkSecurityRuleConfig `
        -Name $rule.Name `
        -Description $rule.Description `
        -Protocol $rule.Protocol `
        -SourcePortRange $rule.SourcePortRange `
        -DestinationPortRange $rule.DestinationPortRange `
        -SourceAddressPrefix $rule.SourceAddressPrefix `
        -DestinationAddressPrefix $rule.DestinationAddressPrefix `
        -Access $rule.Access `
        -Priority $rule.Priority `
        -Direction $rule.Direction
    
    $dbNsg.SecurityRules.Add($securityRule)
}

$dbNsg | Set-AzNetworkSecurityGroup

Write-Host "Creating a virtual network with NSG associations..."
$webSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroup $webNsg

$dbSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroup $dbNsg

$mngSubnet = New-AzVirtualNetworkSubnetConfig `
    -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroup $mngNsg

$virtualNetwork = New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $webSubnet, $dbSubnet, $mngSubnet

Write-Host "Virtual network and NSGs created successfully!"
Write-Host "NSG Configuration Summary:"
Write-Host "  - $webSubnetName NSG: 3 rules (HTTP/HTTPS from Internet + VNet traffic)"
Write-Host "  - $dbSubnetName NSG: 1 rule (Only VNet traffic)"
Write-Host "  - $mngSubnetName NSG: 2 rules (SSH from Internet + VNet traffic)"
