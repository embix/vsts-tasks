# This file implements IAzureUtility for Azure PowerShell version >= 1.0.0

function Create-AzureSqlDatabaseServerFirewallRuleRDFE
{
    param([String] [Parameter(Mandatory = $true)] $startIPAddress,
          [String] [Parameter(Mandatory = $true)] $endIPAddress,
          [String] [Parameter(Mandatory = $true)] $serverName,
          [String] [Parameter(Mandatory = $true)] $firewallRuleName)

    try
    {
        Write-Verbose "[Azure RDFE Call] Creating firewall rule $firewallRuleName"  -Verbose
        $azureSqlDatabaseServerFirewallRule = New-AzureSqlDatabaseServerFirewallRule -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress -ServerName $serverName `
                                                                                    -RuleName $firewallRuleName -ErrorAction Stop
        Write-Verbose "[Azure RDFE Call] Firewall rule $firewallRuleName created"  -Verbose
    }
    catch [System.ServiceModel.CommunicationException]
    {
        $exceptionMessage = $_.Exception.Message.ToString()
        Write-Verbose "ExceptionMessage: $exceptionMessage" -Verbose

        Throw (Get-VstsLocString -Key "SAD_InvalidServerAddress" -ArgumentList $serverName)
    }

    return $azureSqlDatabaseServerFirewallRule
}

function Get-AzureSqlDatabaseServerRGName
{
    param([String] [Parameter(Mandatory = $true)] $serverName)

    $ARMSqlServerResourceType =  "Microsoft.Sql/servers"
    try
    {
        Write-Verbose "[Azure RM Call] Getting resource details for azure sql server resource: $serverName with resource type: $ARMSqlServerResourceType" -Verbose
        $azureSqlServerResourceDetails = (Get-AzureRMResource -ErrorAction Stop) | Where-Object { $_.ResourceName -eq $serverName -and $_.ResourceType -eq $ARMSqlServerResourceType }
        Write-Verbose "[Azure RM Call] Retrieved resource details successfully for azure sql server resource: $serverName with resource type: $ARMSqlServerResourceType" -Verbose

        $azureResourceGroupName = $azureSqlServerResourceDetails.ResourceGroupName
        return $azureSqlServerResourceDetails.ResourceGroupName
    }
    finally
    {
        if ([string]::IsNullOrEmpty($azureResourceGroupName))
        {
            Write-Verbose "[Azure RM Call] Sql Database Server: $serverName not found" -Verbose

            Throw (Get-VstsLocString -Key "SAD_ServerNotFound" -ArgumentList $serverName)
        }
    }
}

function Create-AzureSqlDatabaseServerFirewallRuleARM
{
    param([String] [Parameter(Mandatory = $true)] $startIPAddress,
          [String] [Parameter(Mandatory = $true)] $endIPAddress,
          [String] [Parameter(Mandatory = $true)] $serverName,
          [String] [Parameter(Mandatory = $true)] $firewallRuleName)

     # get azure storage account resource group name
    $azureResourceGroupName = Get-AzureSqlDatabaseServerRGName -serverName $serverName
    Write-Verbose "For azure sql database server: '$serverName' resourcegroup name is '$azureResourceGroupName'." -Verbose

    try
    {
        Write-Verbose "[Azure RM Call] Creating firewall rule $firewallRuleName on azure database server: $serverName" -Verbose
        $azureSqlDatabaseServerFirewallRule = New-AzureRMSqlServerFirewallRule -ResourceGroupName $azureResourceGroupName -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress -ServerName $serverName -FirewallRuleName $firewallRuleName -ErrorAction Stop
        Write-Verbose "[Azure RM Call] Firewall rule $firewallRuleName created on azure database server: $serverName" -Verbose
    }
    catch [Hyak.Common.CloudException]
    {
        $exceptionMessage = $_.Exception.Message.ToString()
        Write-Verbose "ExceptionMessage: $exceptionMessage" -Verbose

        Throw (Get-VstsLocString -Key "SAD_InvalidIPv4Address")
    }

    return $azureSqlDatabaseServerFirewallRule
}

function Delete-AzureSqlDatabaseServerFirewallRuleRDFE
{
    param([String] [Parameter(Mandatory = $true)] $serverName,
          [String] [Parameter(Mandatory = $true)] $firewallRuleName)

    Write-Verbose "[Azure RDFE Call] Deleting firewall rule $firewallRuleName on azure database server: $serverName" -Verbose
    Remove-AzureSqlDatabaseServerFirewallRule -ServerName $serverName -RuleName $firewallRuleName -Force -ErrorAction Stop
    Write-Verbose "[Azure RDFE Call] Firewall rule $firewallRuleName deleted on azure database server: $serverName" -Verbose
}

function Delete-AzureSqlDatabaseServerFirewallRuleARM
{
    param([String] [Parameter(Mandatory = $true)] $serverName,
          [String] [Parameter(Mandatory = $true)] $firewallRuleName)

    # get azure storage account resource group name
    $azureResourceGroupName = Get-AzureSqlDatabaseServerRGName -serverName $serverName
    Write-Verbose "For azure sql database server: '$serverName' resourcegroup name is '$azureResourceGroupName'." -Verbose

    Write-Verbose "[Azure RM Call] Deleting firewall rule $firewallRuleName on azure database server: $serverName" -Verbose
    Remove-AzureRMSqlServerFirewallRule -ResourceGroupName $azureResourceGroupName -ServerName $serverName -FirewallRuleName $firewallRuleName -Force -ErrorAction Stop
    Write-Verbose "[Azure RM Call] Firewall rule $firewallRuleName deleted on azure database server: $serverName" -Verbose
}
