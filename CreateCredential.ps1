param(
[string]$credentialname,
[Parameter(Mandatory=$true)]
[string]$credidentity,
[Parameter(Mandatory=$true)]
[string]$credpassword)
#-----------------------------------------SQL Server Credential---------------------------------------------------------
Invoke-SqlCmd -Query "CREATE CREDENTIAL $credentialname WITH IDENTITY = '$credidentity',SECRET = '$credpassword'" -ErrorAction SilentlyContinue

#-------------------------------------------------------------------------------------------------------------------------
