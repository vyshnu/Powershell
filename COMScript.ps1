param
([Parameter(Mandatory=$true)]
[string]$CMDBSrv,
[Parameter(Mandatory=$true)] 
[string]$Application,
[Parameter(Mandatory=$true)] 
[string]$Release, 
[Parameter(Mandatory=$true)]    
[string]$cmdbEnvironment,
[string]$JSonFilePath,
[string]$LogLocation
)

$COMLogsLocation=join-path  $LogLocation  "\RMLogs"
if(!(Test-Path -Path $COMLogsLocation ))
{
    New-Item -ItemType directory -Path $COMLogsLocation
} 
$DeploymentLogFile = $COMLogsLocation + "\COMDeployment_Log_"+ $(Get-Date -f yyyy_MM_dd_HH_mm_ss)+".txt"
Function DeploymentLog 
{
   Param ([string]$LogMessages)
   #Writing to Logfiles
   Add-content $DeploymentLogFile -value $LogMessages
}

try
{
    $cmdbconfig=Invoke-RestMethod -Uri "http://$CMDBSrv/api/deployconfig?application=$Application&release=$Release&Environment=$cmdbEnvironment" -Method Get -UseDefaultCredentials 
    #write-host "http://$CMDBSrv/api/deployconfig?application=$Application&release=$Release&Environment=$cmdbEnvironment" 
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") http://$CMDBSrv/api/deployconfig?application=$Application&release=$Release&Environment=$cmdbEnvironment" 
}
catch
{
    if(Test-Path $JSonFilePath)
    {
      Try
        {
            $cmdb = Get-content $JSonFilePath -Raw
            $cmdbconfig = $cmdb | ConvertFrom-Json 
            DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") JSonFilePath is loaded"
            write-verbose "JSonFilePath is loaded"
        }
        Catch
        {
            write-verbose "Failed to load JSonFile"
            DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Failed to load JSonFile"
            exit
        
        }
    }
    else
    {
        write-verbose "JSonFilePath is empty"
        DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") JSonFilePath is empty"
        exit
    }  
}

 
$Component =$cmdbconfig.Components.InvoiceComponents.ApplicationDetails
$Count = $Component.Count
write-verbose  "Count of COM Applications is $Count"
DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Count of COM Applications is $Count"
for($i=0; $i -lt $Count ; $i++)
{
    $appName=$Component[$i].Name
    $comCatalog=New-Object -ComObject comadmin.comadmincatalog
    $appCollection=$comCatalog.GetCollection("Applications")
    $appCollection.Populate()
    $app= $appCollection |where {$_.Name -eq $appName}
    If($app)
    { 
        Try
        {
            write-verbose "$appName already exists"
            DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") $appName already exists"
            $index=0
            Foreach($apps in $appCollection)
            {
              if($apps.Name -eq $appName)
               {
                    $appCollection.Remove($Index)
                    $appCollection.SaveChanges()
               }
            $index++
             }
             write-verbose "Deleted the already existing $appName"
             DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Deleted the already existing $appName"
          }
          catch
          {
            write-verbose "Failed to deleted existing aplication $appName"
            DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Failed to deleted existing aplication $appName"
            DeploymentLog $Error
            Exit
          }
      }
      Try
      {
           write-verbose "Creating/Recreating $appName COM application"
           DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Creating/Recreating $appName COM application"
           $app=$appCollection.Add()
           $app.Value("Name")=$appName
           $app.Value("Identity")=$Component[$i].ServiceAccount
           $app.Value("Password")=$Component[$i].Password
           $appCollection.SaveChanges()
           write-verbose "Created $appName COM application"
           DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Created $appName COM application"
           $rolecount = $Component[$i].Roles.Count
           write-verbose "Roles Count for $appName is $roleCount"
           DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Roles Count for $appName is $roleCount"
           $usercount = $Component[$i].Users.Count
           write-verbose "Users Count for $appName under each role is $usercount"
           DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Users Count for $appName under each role is $usercount"
           $dllcount = $Component[$i].Dllpath.Count
           write-verbose "Dll Count for $appName  is $dllcount"
           DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Users Count for Dll Count for $appName  is $dllcount"
           for($j=0 ; $j -lt $rolecount ; $j++)
           {
                $appRole=$appCollection.GetCollection("Roles",$app.Key)
                $role=$appRole.Add()
                $role.Value("Name")=$Component[$i].Roles[$j]
                $appRole.SaveChanges()
                $appRole.Populate()
                $a=$Component[$i].Roles[$j]
                write-verbose " Created role $a"
                DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Created role $a"
                for($k=0 ; $k -lt $usercount ; $k++ )
                {
                      $Users=$appRole.GetCollection("UsersInRole",$role.Key)
                      $User=$Users.Add()
                      $User.Value("User")=$Component[$i].Users[$k]
                      $Users.SaveChanges()
                      $b=$Component[$i].Users[$k]
                      write-verbose "Created user $b under $a role"
                      DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Created user $b under $a role"
                 }
             } 
             write-verbose "Installing Components under $appName COM application"
             DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Installing Components under $appName COM application"
             for($l=0 ; $l -lt $dllcount ; $l++)
             {
                 $X=$Component[$i].Dllpath[$l]
                 $comCatalog.InstallComponent($appName,$x,"","")
              }
              write-verbose "Installed Components under $appName COM application"
              DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Installed Components under $appName COM application"
         }
        Catch
        {
           # Log error details in case of failure
            "Error in " + $_.InvocationInfo.ScriptName + " at line: " + $_.InvocationInfo.ScriptLineNumber + ", offset: " + $_.InvocationInfo.OffsetInLine + ".`r`n";
             DeploymentLog $Error
             Write-Verbose "Installed Components under COM application"
	         exit 1
        }
  }
 




