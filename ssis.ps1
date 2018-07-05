
[CmdletBinding()]
Param(
    # IsPacFilePath is required
    [Parameter(Mandatory=$True,Position=1)]
    [string]$IspacFilePath, # Enter the ispac filepath
     
    # SsisServer is required 
    [Parameter(Mandatory=$True,Position=2)]
    [string]$SsisServer,   # Server on which it should be deployed
     
    # FolderName is required
    [Parameter(Mandatory=$True,Position=3)]
    [string]$FolderName,  # Folder Name to be entered under catalog
     
    # ProjectName is not required
    # If empty filename is used
    [Parameter(Mandatory=$False,Position=4)]
    [string]$ProjectName, # It should be a ispacfile name because automatic deploying is done, if not given Project Name is replaced with ispac file name
     
    # EnvironmentName is not required
    # If empty no environment is referenced
    [Parameter(Mandatory=$False,Position=5)]
    [string]$EnvironmentName, # Environment Name to be created.Give the ENvironment name if environment references are present
     
    # EnvironmentFolderName is not required
    # If empty the FolderName param is used
    [Parameter(Mandatory=$False,Position=6)]
    [string]$EnvironmentFolderName, #Optional if not entered replaced with the folder name

    [string]$ssiscatalog, #ENter the ssis catalog name in which the ispac to be deployed.If
    [string]$DatabaseName, #Enter the database name
    [string]$LogLocation,  #Enter the LogLocation
    [string]$CatalogPwd #enter the Catalog Password
)
#$IspacFilePath = "C:\Users\xyz\Desktop\ssistrial.ispac"
#$SsisServer = "localhost"
#$ssiscatalog = "SSISDB"
#$EnvironmentName = "ssisenv"
#$FolderName = "ssis"
#$DatabaseName = "master"
#Writing Logs

#-------------------------------------------Function to create logs------------------------------------------------------------------

$SSISLogsLocation=join-path  $LogLocation  "\RMLogs\SSISLogs"

if(!(Test-Path -Path $SSISLogsLocation ))
{
    New-Item -ItemType directory -Path $SSISLogsLocation
} 
$DeploymentLogFile = $SSISLogsLocation + "\SSISDeployment_Log_"+ $(Get-Date -f yyyy_MM_dd_HH_mm_ss)+".txt"
Function DeploymentLog 
{
   Param ([string]$LogMessages)
   #Writing to Logfiles
   Add-content $DeploymentLogFile -value $LogMessages
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------



 
#---------------------------------- Replacing empty projectname with ISpac filename if Project Name not given---------------------------------------------------------

if (-not $ProjectName)
{ 
  Try
    {

  $ProjectName = [system.io.path]::GetFileNameWithoutExtension($IspacFilePath)
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Getting file name"
  Write-Host "Project Name is replaced with file name"
     }

  Catch
      {

      Write-Host "Failed to update Project Name with Ispac file name"
      DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Failed to update Project Name with Ispac file name"
      exit
      }
}
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



#---------------------------------- Replace empty Environment folder with FolderName if Environment folder name doesn't exist-------------------------------------------------------------------------------------

if (-not $EnvironmentFolderName)
{
 Try
   {
  $EnvironmentFolderName = $FolderName
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Getting project name for environment folder"
  Write-Host "Environment folder name is replaced with project name"
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Environment folder name is replaced with project name"
   }

 catch
     {
     Write-Host "Failed to update Folder Name with Environment folder name "
     DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Failed to update Folder Name with Environment folder name"
     exit
     }

}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 

#--------------------------------------------------Checking if ispac file path exists------------------------------------------------------------------------------------------------------------------

try
  {
if (-Not (Test-Path $IspacFilePath))
{
  Write-Host "Ispac file $IspacFilePath doesn't exists!"
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Ispac file $IspacFilePath doesn't exists!"
}

else
{
    $IspacFileName = split-path $IspacFilePath -leaf
    Write-Host "Ispac file" $IspacFileName "found"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") "Ispac file" $IspacFileName "found""
}
  }

catch
{
 Write-Host "Issue in loading ispac file"
 DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Issue in loading ispac file"
}
 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 

#-------------------------------------------------- Loading the IntegrationServices Assembly------------------------------------------------------------------------------

DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Connecting to server $SsisServer"
Write-Host "Connecting to server $SsisServer"

try
  {
   $SsisNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
   [System.Reflection.Assembly]::LoadWithPartialName($SsisNamespace) | Out-Null;
   DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") IntegrationServices Assembly are loaded"
   Write-Host "IntegrationServices Assembly are loaded"
  }

catch
     {
     DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") failed to load IntegrationServices Assembly"
     Write-Host "failed to load IntegrationServices Assembly"
     exit
     }

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 
#-------------------------------------------------Creating a connection to the server-------------------------------------------------------------------------------------------------------

$SqlConnectionstring = "Data Source=$SsisServer;Initial Catalog=$DatabaseName;Integrated Security=SSPI;"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection $SqlConnectionstring
    
# Create the Integration Services object
$IntegrationServices = New-Object "$SsisNamespace.IntegrationServices" $SqlConnection
 
# Check if connection succeeded


if (-not $IntegrationServices)
{
  
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Connection to server failed"
  Write-Host "Connection to server failed"
}
else
{
   Write-Host "Connected to server" $SsisServer
   DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Connected to server $SsisServer"
}
   
#_---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 

#--------------------------------------------------Checking the catalog-----------------------------------------------------------------------------------------------------------
# Create object for SSISDB Catalog
$Catalog = $IntegrationServices.Catalogs[$ssiscatalog]
 Try
    {
     if (-not $Catalog)
      {


    # Catalog doesn't exists. The user should create it manually.
    # It is possible to create it, but that shouldn't be part of
    # deployment of packages.
    #Throw  [System.Exception] "$ssiscatalog catalog doesn't exist. Create it manually!"
    Write-Host "Catalog should be created manually or give fixed default catalog SSISDB"
    #$Catalog = New-Object $SsisNamespace".Catalog" ($integrationServices, $ssisCatalog, $CatalogPwd)
    #$Catalog.Create()
    
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Catalog should be created manually or give fixed default catalog SSISDB"
       }

     else
      {
    Write-Host "Catalog $ssisCatalog found"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Catalog $ssisCatalog exists"
      }
   }
catch
     {
     Write-Host "failed to create catalog or No catalog found"
     DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") failed to create catalog or No catalog found"
     }

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------ Creating folder under the catalog -----------------------------------------------------------------------------------------------------

Try
{
 $Folder = $Catalog.Folders[$FolderName]
 # Check if folder already exists
  if (-not $Folder)
    {
   
    # Folder doesn't exists, so create the new folder.
    Write-Host "Creating new folder" $FolderName
    $Folder = New-Object $SsisNamespace".CatalogFolder" ($Catalog, $FolderName, $FolderName)
    $Folder.Create()
    Write-Host "Folder with folder name $FolderName is created"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Folder with folder name $FolderName is created"

    }

   else
    {
    Write-Host "Folder" $FolderName "found"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") folder $FolderName  found"
    }
   
    }
catch
     {
     Write-Host "failed to create folder or No folder found"
     DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") failed to create folder or No folder found"
     }

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------- Deploying project to folder---------------------------------------------------------------------------------------------
Try
{
if($Folder.Projects.Contains($ProjectName)) {
    Write-Host "Deploying" $ProjectName "to" $FolderName "(REPLACE)"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Deploying $ProjectName to $FolderName (REPLACE)"
}
else
{
    Write-Host "Deploying" $ProjectName "to" $FolderName "(NEW)"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Deploying $ProjectName to $FolderName (NEW)"
}
# Reading ispac file as binary
[byte[]] $IspacFile = [System.IO.File]::ReadAllBytes($IspacFilePath)
$Folder.DeployProject($ProjectName, $IspacFile)
$Project = $Folder.Projects[$ProjectName]
if (-not $Project)
{
    Write-Host "Error in creating the project"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Error in creating the project"
    return "Error in creating the project"
    
}
else
{
Write-Host "Deployed" $ProjectName "to" $FolderName "(NEW)"
DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Deployed $ProjectName to $FolderName"
}
 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#---------------------------------------------Checking if environment exists and adding references if environment exists---------------------------------------------------------
if (-not $EnvironmentName)
{
    # Kill connection to SSIS
    $IntegrationServices = $null
 
    # Stop the deployment script
    Write-Host "Deployed $IspacFileName without adding environment references"
    DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Deployed $IspacFileName without adding environment references"
    Exit
}
 
# Create object to the (new) folder
$EnvironmentFolder = $Catalog.Folders[$EnvironmentFolderName]
 
# Check if environment folder exists
if (-not $EnvironmentFolder)
{
  #Creating Environment Folder incase it doesn't exist
  $EnvironmentFolder = New-Object $SsisNamespace".CatalogFolder" ($Catalog, $EnvironmentFolderName, $EnvironmentFolderName)
  $EnvironmentFolder.Create()
  Write-Host "Created $EnvironmentFolderName "
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Created $EnvironmentFolderName"
}

 
# Check if environment exists
if(-not $EnvironmentFolder.Environments.Contains($EnvironmentName))
{
  #Creating environment incase environment doesn't exist
  $environment = New-Object $SsisNamespace".EnvironmentInfo" ($EnvironmentFolder, $EnvironmentName, $EnvironmentName)
  $environment.Create()
  Write-Host "Created environment under $EnvironmentFolderName"
  DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Created environment under $EnvironmentFolderName"

}
else
{
    # Create object for the environment
    $Environment = $Catalog.Folders[$EnvironmentFolderName].Environments[$EnvironmentName]
 
    if ($Project.References.Contains($EnvironmentName, $EnvironmentFolderName)) #Checking if reference already exists
    {
        Write-Host "Reference to $EnvironmentName found"
        DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Reference to $EnvironmentName found"
    }
    else
    {   
        #Adding References for $EnvironmentName to $EnvironmentFOlderName...if reference not present
        Write-Host "Adding reference to" $EnvironmentName
        DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Adding reference to $EnvironmentName"
        $Project.References.Add($EnvironmentName, $EnvironmentFolderName)
        $Project.Alter() 
    }
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
 
#-----------------------------------------Referencing Project Parameters to environment--------------------------------------------------------------------------------------------------
try
   {
$ParameterCount = 0
# Loop through all project parameters
foreach ($Parameter in $Project.Parameters)
{
    # Get parameter name and check if it exists in the environment
   if ($Environment.Variables.Contains($Parameter.Name))
    {   
        #If Environment variables contain project parameter name,referencing the variables to the environment
        $ParameterCount = $ParameterCount + 1
        Write-Host "Environment variable already exists and Project parameter" $ParameterName "connected to environment"
        DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Environment variable already exists and Project parameter $ParameterName connected to environment"
        $Project.Parameters[$Parameter.Name].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $Parameter.Name)
        $Project.Alter()
    }
    else
    {
       #If project parameters found and environment variables doesn't exist...adding env variables and referencing it to environment
        $y = $Parameter.Name
        $environment.Variables.Add("$y", [System.TypeCode]::String, $y, $false, "$y")
        $environment.Alter()
        $Project.Parameters[$Parameter.Name].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $Parameter.Name)
        $Project.Alter()
        Write-Host "Environment variable added for Project parameter $ParameterName and referenced to environment"
        DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Environment variable added for Project parameter $ParameterName and referenced to environment"
    }
}
Write-Host "Number of project parameters mapped:" $ParameterCount
DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Number of project parameters mapped: $ParameterCount"
   }

catch
{
Write-Host "project parameters not found"
DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") project parameters not found"
}
 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#-----------------------------------------Referencing Package parameters to environment---------------------------------------------------------------------------------------------------------
try
{
$ParameterCount = 0
# Loop through all packages
foreach ($Package in $Project.Packages)
{
    # Loop through all package parameters
    foreach ($Parameter in $Package.Parameters)
    {
      if ($Environment.Variables.Contains($Parameter.Name))
        {   
            #If Environment variables contain package parameter name,referencing the variables to the environment
            $ParameterCount = $ParameterCount + 1
            Write-Host "Environment Variable already exists and Package parameter" $ParameterName "from package" $PackageName "connected to environment"
            DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Environment Variable already exists and Package parameter $ParameterName from package $PackageName connected to environment"
            $Package.Parameters[$Parameter.Name].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $Parameter.Name)
            $Package.Alter()
        }
        else
        {
            #If package parameters found and environment variables doesn't exist...adding env variables and referencing it to environment
            $ParameterCount = $ParameterCount + 1
            $x = $Parameter.Name
            $environment.Variables.Add("$x", [System.TypeCode]::String, $x, $false, "$x")
            $environment.Alter()
            $Package.Parameters[$Parameter.Name].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $Parameter.Name)
            $Package.Alter()
            Write-Host  "Environment Variable for Package parameter $ParameterName from package $PackageName is added and referenced"
            DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Environment Variable for Package parameter $ParameterName from package $PackageName is added and referenced"
        }
    }
   }
   Write-Host "Number of package parameters mapped:" $ParameterCount
   DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") Number of package parameters mapped: $ParameterCount"

}
catch
{
Write-Host "No Packages to be mapped in the project"
DeploymentLog "$(Get-Date –f "yyyy/MM/dd/hh:mm:ss") No Package parameters to be mapped in the project"
}
$IntegrationServices = $null #Killing connection to ssis
}

#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#-------------------------------------------------Logging script execution errors--------------------------------------------------------------------------------------------------------------------------------

Catch
{
# Log error details in case of failure
            "Error in " + $_.InvocationInfo.ScriptName + " at line: " + $_.InvocationInfo.ScriptLineNumber + ", offset: " + $_.InvocationInfo.OffsetInLine + ".`r`n";
             DeploymentLog $Error
             Write-Host "Error in executing the ssis script.Verify the log file"
	         exit 1
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------