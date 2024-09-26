function ForceExit {
    Write-Host "PLEASE CLOSE THE WINDOW MANUALLY" -ForegroundColor Red;
    Read-Host " ";
    ForceExit;
}

ForceExit