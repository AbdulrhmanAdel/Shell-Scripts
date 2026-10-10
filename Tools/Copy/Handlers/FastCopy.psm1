function Invoke-Copy {
    param (
        [string[]]$Files,
        [string]$Destination,
        [switch]$Move,
        [switch]$Verify
    )

    $arguments = @(
        "/cmd=$($Move ? "move" : "diff")",
        "/estimate", "/balloon",
        "/force_close", "/open_window"
    );
    if ($Verify) {
        $arguments += @("/verify", "/verifyinfo");
    }

    $arguments += $Files + @("/to=`"$Destination`"");
    $process = Start-Process fastcopy.exe -ArgumentList $arguments -Wait -PassThru;
    if ($process.ExitCode -eq 0) {
        Write-Host "FastCopy completed successfully." -ForegroundColor Green;
    }
    else {
        Write-Host "FastCopy failed with exit code $($process.ExitCode)." -ForegroundColor Red;
    }
}

Export-ModuleMember -Function Invoke-Copy;
