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

$webRuleName = "web-allow-http-https-rule"
$webSubnetNsg = Get-AzNetworkSecurityGroup `
                -Name $webSubnetName `
                -ResourceGroupName $resourceGroupName `
                -ErrorAction SilentlyContinue

if ($null -eq $webSubnetNsg)
{
    Write-Host "NSG $webSubnetName does not exist, creating..."
    $webRule = New-AzNetworkSecurityRuleConfig `
                -Name $webRuleName `
                -Description "Allow HTTP and HTTPS" `
                -Access Allow `
                -Protocol Tcp `
                -Direction Inbound `
                -Priority 100 `
                -SourceAddressPrefix Internet `
                -SourcePortRange * `
                -DestinationAddressPrefix * `
                -DestinationPortRange 80,443

    $webSubnetNsg = New-AzNetworkSecurityGroup `
                    -ResourceGroupName $resourceGroupName `
                    -Location $location `
                    -Name $webSubnetName `
                    -SecurityRules $webRule
}
else
{
    Write-Host "NSG $webSubnetName already exists, checking rules..."
    $existingRule = Get-AzNetworkSecurityRuleConfig `
                    -NetworkSecurityGroup $webSubnetNsg `
                    -Name $webRuleName `
                    -ErrorAction SilentlyContinue

    if ($null -eq $existingRule)
    {
        Write-Host "Adding missing rule $webRuleName..."
        Add-AzNetworkSecurityRuleConfig `
            -NetworkSecurityGroup $webSubnetNsg `
            -Name $webRuleName `
            -Description "Allow HTTP and HTTPS" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority 100 `
            -SourceAddressPrefix Internet `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 80,443

        $webSubnetNsg | Set-AzNetworkSecurityGroup
    }
    else
    {
        Write-Host "Rule $webRuleName already exists in NSG $webSubnetName"
    }
}

$mngRuleName = "mng-allow-ssh-rule"
$mngSubnetNsg = Get-AzNetworkSecurityGroup `
                -Name $mngSubnetName `
                -ResourceGroupName $resourceGroupName `
                -ErrorAction SilentlyContinue

if ($null -eq $mngSubnetNsg)
{
    Write-Host "NSG $mngSubnetName does not exist, creating..."
    $mngRule = New-AzNetworkSecurityRuleConfig `
                -Name $mngRuleName `
                -Description "Allow SSH" `
                -Access Allow `
                -Protocol Tcp `
                -Direction Inbound `
                -Priority 100 `
                -SourceAddressPrefix Internet `
                -SourcePortRange * `
                -DestinationAddressPrefix * `
                -DestinationPortRange 22

    $mngSubnetNsg = New-AzNetworkSecurityGroup `
                    -ResourceGroupName $resourceGroupName `
                    -Location $location `
                    -Name $mngSubnetName `
                    -SecurityRules $mngRule
}
else
{
    Write-Host "NSG $mngSubnetName already exists, checking rules..."
    $existingRule = Get-AzNetworkSecurityRuleConfig `
                    -NetworkSecurityGroup $mngSubnetNsg `
                    -Name $mngRuleName `
                    -ErrorAction SilentlyContinue

    if ($null -eq $existingRule)
    {
        Write-Host "Adding missing rule $mngRuleName..."
        Add-AzNetworkSecurityRuleConfig `
            -NetworkSecurityGroup $mngSubnetNsg `
            -Name $mngRuleName `
            -Description "Allow SSH" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority 100 `
            -SourceAddressPrefix Internet `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 22

        $mngSubnetNsg | Set-AzNetworkSecurityGroup
    }
    else
    {
        Write-Host "Rule $mngRuleName already exists in NSG $mngSubnetName"
    }
}

$dbSubnetNsg = Get-AzNetworkSecurityGroup `
                -Name $dbSubnetName `
                -ResourceGroupName $resourceGroupName `
                -ErrorAction SilentlyContinue

if ($null -eq $dbSubnetNsg)
{
    Write-Host "NSG $dbSubnetName does not exist, creating..."
    $dbSubnetNsg = New-AzNetworkSecurityGroup `
                    -ResourceGroupName $resourceGroupName `
                    -Location $location `
                    -Name $dbSubnetName
}
else
{
    Write-Host "NSG $dbSubnetName already exists"
}

Write-Host "Getting existing virtual network..."
$vnet = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($null -eq $vnet)
{
    Write-Host "Creating a virtual network ..."
    $webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webSubnetNsg
    $dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroup $dbSubnetNsg
    $mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngSubnetNsg
    New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
}
else
{
    Write-Host "Updating existing virtual network with NSGs..."
    $webSubnet = $vnet.Subnets | Where-Object Name -eq $webSubnetName
    $dbSubnet = $vnet.Subnets | Where-Object Name -eq $dbSubnetName
    $mngSubnet = $vnet.Subnets | Where-Object Name -eq $mngSubnetName

    $webSubnet.NetworkSecurityGroup = $webSubnetNsg
    $dbSubnet.NetworkSecurityGroup = $dbSubnetNsg
    $mngSubnet.NetworkSecurityGroup = $mngSubnetNsg

    Set-AzVirtualNetwork -VirtualNetwork $vnet
}