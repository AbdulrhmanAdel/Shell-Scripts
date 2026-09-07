using System.Diagnostics;

var self = Process.GetCurrentProcess().MainModule!.FileName!;
var shimFile = Path.ChangeExtension(self, ".shim");
if (!File.Exists(shimFile))
{
    Console.Error.WriteLine($"Missing shim file: {shimFile}");
    return 1;
}

var target = File.ReadLines(shimFile).First().Trim();

var psi = new ProcessStartInfo
{
    FileName = target,
    UseShellExecute = false,
};
foreach (var a in args) psi.ArgumentList.Add(a);

using var p = Process.Start(psi)!;
p.WaitForExit();
return p.ExitCode;
