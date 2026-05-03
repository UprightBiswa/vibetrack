param(
  [ValidateSet("local", "prod")]
  [string] $Target = "prod"
)

$baseUrl = if ($Target -eq "local") {
  "http://127.0.0.1:8001"
} else {
  "https://vibetrack-backend-np02.onrender.com"
}

Write-Host "Checking $Target backend: $baseUrl"

foreach ($path in @("/api/v1/health", "/api/v1/ready")) {
  $url = "$baseUrl$path"
  try {
    $response = Invoke-WebRequest -UseBasicParsing $url -TimeoutSec 30
    Write-Host "OK $path -> $($response.StatusCode)"
    Write-Host $response.Content
  } catch {
    Write-Host "FAIL $path"
    Write-Host $_.Exception.Message
  }
}
