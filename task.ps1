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

# --- Внутрішнє правило для всіх NSG (Вимога ментора) ---
$vnetInboundRule = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet-Inbound" `
    -Priority 110 `
    -Direction Inbound `
    -Access Allow `
    -Protocol "*" `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "*"

# ----------------------------------------------------------------------
# 1. Створення NSG для webservers (HTTP/HTTPS з Internet + VNet)
# ----------------------------------------------------------------------
Write-Host "Creating web network security group..."

# Правило: Дозволити TCP 80 та 443 з Інтернету (Priority 100)
$internetWebRule = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTP-HTTPS-Internet" `
    -Priority 100 `
    -Direction Inbound `
    -Access Allow `
    -Protocol Tcp `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange @("80", "443")

# Об'єднуємо правила: Інтернет + Явне VNet правило
$webRules = @($internetWebRule, $vnetInboundRule)

$webserversNSG = New-AzNetworkSecurityGroup -Name $webSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $webRules


# ----------------------------------------------------------------------
# 2. Створення NSG для management (SSH з Internet + VNet)
# ----------------------------------------------------------------------
Write-Host "Creating mngSubnet network security group..."

# Правило: Дозволити TCP 22 (SSH) з Інтернету (Priority 100)
$internetMngRule = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH-Internet" `
    -Priority 100 `
    -Direction Inbound `
    -Access Allow `
    -Protocol Tcp `
    -SourceAddressPrefix Internet `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange "22"

# Об'єднуємо правила: Інтернет + Явне VNet правило
$mngRules = @($internetMngRule, $vnetInboundRule)

$managementNSG = New-AzNetworkSecurityGroup -Name $mngSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $mngRules


# ----------------------------------------------------------------------
# 3. Створення NSG для database (Тільки VNet)
# ----------------------------------------------------------------------
Write-Host "Creating dbSubnet network security group..."

$databaseNSG = New-AzNetworkSecurityGroup -Name $dbSubnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules @($vnetInboundRule)


# ----------------------------------------------------------------------
# 4. Створення Virtual Network та приєднання NSG до підмереж
# ----------------------------------------------------------------------
Write-Host "Creating a virtual network ..."

# Приєднання NSG до конфігурації підмереж за допомогою параметра -NetworkSecurityGroup
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName `
    -AddressPrefix $webSubnetIpRange `
    -NetworkSecurityGroup $webserversNSG

$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName `
    -AddressPrefix $dbSubnetIpRange `
    -NetworkSecurityGroup $databaseNSG

$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName `
    -AddressPrefix $mngSubnetIpRange `
    -NetworkSecurityGroup $managementNSG

# Створення VNet з оновленими підмережами
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet