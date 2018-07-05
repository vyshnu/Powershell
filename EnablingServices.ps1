param(
[Parameter(Mandatory=$true)]
[string[]]$ssissvname,
[Parameter(Mandatory=$true)]
[string]$Startuptype
)

#-----------------------------Enabling Services----------------------------------------------------------------------
$ssissvname=$ssissvname.Split(",")
foreach($svc in $ssissvname)
{
$service = gwmi win32_service -filter "name='$svc'"
Set-Service –Name $svc –StartupType $Startuptype
$service.StartService()
}

#---------------------------------------------------------------------------------------------------------------