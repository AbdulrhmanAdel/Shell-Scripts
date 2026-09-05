$result = Invoke-WebRequest -Method Get `
  -Uri "https://api.themoviedb.org/3/search/movie?query=The+Wild+Robot" `
  -Headers @{
  Authorization = "Bearer $(Get-ShellSecret.ps1 -Name "MoviesDb:ApiToken")"
  accept        = "application/json"
}
return $result.Content | ConvertFrom-Json;
