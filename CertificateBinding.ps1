param
        (
            <#[String]$certlocation,
            [String]$certPassword,#>
            [String]$iisSiteName,
            [String]$port,
            [String]$ip,
            [String]$hostname,
            [String]$protocol, 
            [String]$SslThumbprint
        )  
<# Function Thumbprint
    {
        param
        (
            [String]$certlocation ,
            [String]$certPassword 
        )

        $CertFromFile = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 
    
        $CertFromFile.Import($certlocation,$certPassword,[System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet)
    
        $thumbprint = $CertFromFile.Thumbprint
  
        return $thumbprint
    } 
    $SslThumbprint = Thumbprint $certlocation $certPassword#>
    
    New-WebBinding -Name $iisSiteName -Port $port -Protocol $protocol -IP $ip -HostHeader $hostname
    $myBind = Get-WebBinding -Name $iisSiteName -Port $port -Protocol $protocol -IP $ip -HostHeader $hostname
    if($SslThumbprint)
    {
    $certThumbprint = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -match $SslThumbprint}).Thumbprint
    $myBind.AddSslCertificate($certThumbprint,"My")
    }
