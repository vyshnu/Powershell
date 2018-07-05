Param
(
[Parameter(Mandatory=$true)]
[string]$SqlServer,
[Parameter(Mandatory=$true)]
[string]$dbbkname,
 [Parameter(Mandatory=$true)]
[string]$dbname,
 [Parameter(Mandatory=$true)]
[string]$restoresrc ,
 [Parameter(Mandatory=$true)]
[string]$mdfpath, #If restore is set to 1 then restore will happen.
 [Parameter(Mandatory=$true)]
[string]$ldfpath, #If backup is set to 1 then Backup will happen.
 [Parameter(Mandatory=$true)]
[string]$log_filename ,
 [Parameter(Mandatory=$true)]
[string]$data_filename  ,
 [Parameter(Mandatory=$true)]
[string]$mdf_pathname   ,
 [Parameter(Mandatory=$true)]
[string]$ldf_pathname    
    
)

if (Test-Path -Path "$mdfpath")
{
Write-Verbose "$mdfpath already exists"
}
else
{
New-Item -Path "$mdfpath" -ItemType "Directory"
}

OSQL -S $SqlServer -E -Q "RESTORE DATABASE $dbname FROM DISK = '$restoresrc\$dbbkname.bak' WITH REPLACE, 
RECOVERY, MOVE '$data_filename' TO '$mdfpath\$mdf_pathname.mdf'
,MOVE '$log_filename' TO '$ldfpath\$ldf_pathname.ldf'"