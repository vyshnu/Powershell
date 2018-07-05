param(
[string]$wname
)
$AppCmd = "$env:windir\system32\inetsrv\appcmd.exe" 
& $AppCmd unlock config /section:anonymousAuthentication
& $AppCmd set config $wname -section:system.webServer/security/authentication/anonymousAuthentication /enabled:"False"


#Unlocking and disabling the BasicAuthentication
& $AppCmd unlock config /section:basicAuthentication
& $AppCmd set config $wname -section:system.webServer/security/authentication/basicAuthentication /enabled:"False"


#Unlocking and disabling the DigestAuthentication
& $AppCmd unlock config /section:digestAuthentication
& $AppCmd set config $wname -section:system.webServer/security/authentication/digestAuthentication /enabled:"False"

& $AppCmd unlock config /section:windowsAuthentication
& $AppCmd set config $wname -section:system.webServer/security/authentication/windowsAuthentication /enabled:"True"



