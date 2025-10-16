# Azure Network Security Groups Deployment Script
# This script creates VNet and NSGs for the task

param(
    [string]$ResourceGroupName = "mate-resources",
    [string]$Location = "uksouth"
)

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database" 
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

try {
    Write-Host "=== Azure NSG Deployment ==="
    
    # Check Azure connection
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-Host "Authenticating to Azure..."
        Connect-AzAccount
    }
    
    $context = Get-AzContext
    Write-Host "Connected to: $($context.Subscription.Name)"
    Write-Host "Using account: $($context.Account.Id)"

    # Create or get resource group
    Write-Host "`n1. Setting up resource group..."
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $resourceGroup) {
        Write-Host "Creating resource group: $ResourceGroupName"
        $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
    }
    Write-Host "✅ Resource group: $ResourceGroupName"

    # Create or get virtual network
    Write-Host "`n2. Setting up virtual network..."
    $virtualNetwork = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $virtualNetwork) {
        Write-Host "Creating virtual network: $virtualNetworkName"
        
        $webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange
        $dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange
        $mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange
        
        $virtualNetwork = New-AzVirtualNetwork `
            -Name $virtualNetworkName `
            -ResourceGroupName $ResourceGroupName `
            -Location $Location `
            -AddressPrefix $vnetAddressPrefix `
            -Subnet $webSubnet, $dbSubnet, $mngSubnet
        
        Write-Host "✅ Virtual network created"
    } else {
        Write-Host "✅ Virtual network already exists"
    }

    Write-Host "Subnets: $($virtualNetwork.Subnets.Name -join ', ')"

    # Create NSGs
    Write-Host "`n3. Creating Network Security Groups..."

    # Web NSG
    Write-Host "Creating Web NSG..."
    $webNsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $webSubnetName -ErrorAction SilentlyContinue
    if (-not $webNsg) {
        $webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $webSubnetName
    } else {
        $webNsg.SecurityRules.Clear()
    }

    $webRules = @(
        @{Name="AllowHTTP"; Desc="HTTP from Internet"; Protocol="Tcp"; Port="80"; Source="Internet"},
        @{Name="AllowHTTPS"; Desc="HTTPS from Internet"; Protocol="Tcp"; Port="443"; Source="Internet"},
        @{Name="AllowVNet"; Desc="All from VNet"; Protocol="*"; Port="*"; Source="VirtualNetwork"}
    )

    $priority = 100
    foreach ($rule in $webRules) {
        $secRule = New-AzNetworkSecurityRuleConfig `
            -Name $rule.Name -Description $rule.Desc -Protocol $rule.Protocol `
            -SourcePortRange "*" -DestinationPortRange $rule.Port `
            -SourceAddressPrefix $rule.Source -DestinationAddressPrefix "*" `
            -Access Allow -Priority $priority -Direction Inbound
        $webNsg.SecurityRules.Add($secRule)
        $priority += 10
    }
    $webNsg | Set-AzNetworkSecurityGroup
    Write-Host "✅ Web NSG configured"

    # Management NSG
    Write-Host "Creating Management NSG..."
    $mngNsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $mngSubnetName -ErrorAction SilentlyContinue
    if (-not $mngNsg) {
        $mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $mngSubnetName
    } else {
        $mngNsg.SecurityRules.Clear()
    }

    $mngRules = @(
        @{Name="AllowSSH"; Desc="SSH from Internet"; Protocol="Tcp"; Port="22"; Source="Internet"},
        @{Name="AllowVNet"; Desc="All from VNet"; Protocol="*"; Port="*"; Source="VirtualNetwork"}
    )

    $priority = 100
    foreach ($rule in $mngRules) {
        $secRule = New-AzNetworkSecurityRuleConfig `
            -Name $rule.Name -Description $rule.Desc -Protocol $rule.Protocol `
            -SourcePortRange "*" -DestinationPortRange $rule.Port `
            -SourceAddressPrefix $rule.Source -DestinationAddressPrefix "*" `
            -Access Allow -Priority $priority -Direction Inbound
        $mngNsg.SecurityRules.Add($secRule)
        $priority += 10
    }
    $mngNsg | Set-AzNetworkSecurityGroup
    Write-Host "✅ Management NSG configured"

    # Database NSG
    Write-Host "Creating Database NSG..."
    $dbNsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $dbSubnetName -ErrorAction SilentlyContinue
    if (-not $dbNsg) {
        $dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $dbSubnetName
    } else {
        $dbNsg.SecurityRules.Clear()
    }

    $dbRule = New-AzNetworkSecurityRuleConfig `
        -Name "AllowVNet" -Description "All from VNet" -Protocol "*" `
        -SourcePortRange "*" -DestinationPortRange "*" `
        -SourceAddressPrefix "VirtualNetwork" -DestinationAddressPrefix "*" `
        -Access Allow -Priority 100 -Direction Inbound
    $dbNsg.SecurityRules.Add($dbRule)
    $dbNsg | Set-AzNetworkSecurityGroup
    Write-Host "✅ Database NSG configured"

    # Associate NSGs with subnets
    Write-Host "`n4. Associating NSGs with subnets..."
    $vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $ResourceGroupName

    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbNsg
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg

    $vnet | Set-AzVirtualNetwork
    Write-Host "✅ NSGs associated with subnets"

    Write-Host "`n🎉 Deployment completed successfully!"
    Write-Host "📋 Summary:"
    Write-Host "   - Resource Group: $ResourceGroupName"
    Write-Host "   - Virtual Network: $virtualNetworkName ($vnetAddressPrefix)"
    Write-Host "   - Subnets with NSGs: $webSubnetName, $dbSubnetName, $mngSubnetName"

}
catch {
    Write-Error "❌ Deployment failed: $($_.Exception.Message)"
    exit 1
}