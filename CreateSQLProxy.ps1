param(
[Parameter(Mandatory=$true)]
[string]$ProxyName,
[Parameter(Mandatory=$true)]
[string]$ProxyCredentialName
)

#-----------------------------------------SQL Server Proxy------------------------------------------------------------------

[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
$server = New-Object Microsoft.SqlServer.Management.Smo.Server '.'
$jobserver = $server.JobServer
$subsystemos = [Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem]::CmdExec
$subsystemssis = [Microsoft.SqlServer.Management.Smo.Agent.AgentSubSystem]::SSIS
if(!$JobServer.ProxyAccounts[$ProxyName])
{
    $proxy = New-Object Microsoft.SqlServer.Management.Smo.Agent.ProxyAccount($JobServer,$ProxyName,$ProxyCredentialName, $true, "Proxy")
    $proxy.Create()
    $proxy.AddSubSystem($subsystemssis)
    $proxy.AddSubSystem($subsystemos)
    $proxy.Alter()
}

#--------------------------------------------------------------------------------------------------------------------------