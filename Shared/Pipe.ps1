$pipeName = $args[0];
$data = $args[1];

$client = [System.IO.Pipes.NamedPipeClientStream]::new('.', $pipeName, 'Out')
$pipeExists = $false;

try { 
    $pipe.Connect(10000);
    $sw = [System.IO.StreamWriter]::new($pipe)
    $sw.WriteLine('hello world!')
    $sw.Flush()
    $sw.Dispose()
    $pipeExists = $true;
} 
catch {}

if (!$pipeExists) {
    $async = [System.IO.Pipes.PipeOptions]::Asynchronous
    $pipe = [System.IO.Pipes.NamedPipeServerStream]::new($pipeName, 'In', 1, 0, $async, 512, 512)
    
    $timeout = [timespan]::FromSeconds(10)
    $source = [System.Threading.CancellationTokenSource]::new($timeout)
    $pipe.WaitForConnectionAsync($source.token);
    $data = $null
    if ($pipe.IsConnected) {
        $sr = [System.IO.StreamReader]::new($pipe)
        $data = $sr.ReadLine()
        $sr.Dispose()
    }
    $pipe.Dispose()
    write-host "response: $data"
    'end.'
}
