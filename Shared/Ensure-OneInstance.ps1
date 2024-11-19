[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $UniqueKey
)

$MutexName = "$([System.DateTime]::UtcNow.ToString(''))-$UniqueKey"
$isNewInstance = $false;
$mutex = New-Object System.Threading.Mutex($true , $MutexName, [ref] $isNewInstance);
$pipeName = $MutexName;
if (!$isNewInstance) {
    $serverName = "."  # Use '.' for the local machine
    $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream $serverName, $pipeName
    $pipeClient.Connect()
    $writer = New-Object System.IO.StreamWriter $pipeClient
    $writer.AutoFlush = $true
    $writer.WriteLine("Hello from client!")
    $writer.Close()
    $pipeClient.Close()
    EXIT;
}

$pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream $pipeName
Write-Host "Waiting for a client connection..."
$pipeServer.WaitForConnection()
$reader = New-Object System.IO.StreamReader $pipeServer
$message = $reader.ReadLine()
Write-Host "Received from client: $message"

$reader.Close()
$pipeServer.Close()
Write-Host $isNewInstance;
Read-Host "Test";
$mutex.Close()