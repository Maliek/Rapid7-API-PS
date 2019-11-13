#This Script deletes assets without hostname.
#Created by Maliek Meersschaert

add-type @”
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
public bool CheckValidationResult(
ServicePoint srvPoint, X509Certificate certificate,
WebRequest request, int certificateProblem) {
return true;
}
}
“@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#endregion

$credential = Get-Credential
$user = $credential.UserName
$pass = $credential.GetNetworkCredential().Password
$pair = "${user}:${pass}"

$ip = "10.10.20.203"
$port = "3780"
$page = "0"
$size = "500"
$sortBy = "hostname"

$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair.ToString())
$base64 = [System.Convert]::ToBase64String($bytes)

$basicAuthValue = "Basic $base64"

$headers = @{ Authorization = $basicAuthValue }

$url = "https://${ip}:${port}/api/3/assets?page=$page&size=$size&sort=$sortBy" 

$json = Invoke-WebRequest -uri $url -Headers $headers -Method Get | Select-Object -ExpandProperty Content | ConvertFrom-Json


$hostnames = $json.resources.hostname
$ids = $json.resources.id
$resources = $json.resources


foreach ($resource in $resources) {
    if (!$resource.hostname) {
        Write-Host $resource.hostname "empty hostname with id " $resource.id
        $uri = "https://${ip}:${port}/api/3/assets/" + $resource.id
        Invoke-WebRequest -uri $uri -Headers $headers -Method DELETE
    }
}