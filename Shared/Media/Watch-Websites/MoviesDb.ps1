$result = Invoke-WebRequest -Method Get `
  -Uri "https://api.themoviedb.org/3/search/movie?query=The+Wild+Robot" `
  -Headers @{
  Authorization = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJiYTI2OTU3ZjU0NGE0M2ZjNGUxOTU0ODg3MDJkODg2MSIsIm5iZiI6MTcyOTYwNzQ2OC4xOTI2NCwic3ViIjoiNjcxN2I1NjhhNzdhZjFkYmJhZjhiM2FjIiwic2NvcGVzIjpbImFwaV9yZWFkIl0sInZlcnNpb24iOjF9.rZMV9aRzCjF_zLxtc_1ZBkjlAM4VpP4bohJD-iYC0Qo"
  accept        = "application/json"
}
return $result.Content | ConvertFrom-Json;
