[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$File,
    [Parameter()]
    [switch]
    $ReturnFileContent
)

$script:FileContent = $null
function Get-Encoding {
    param (
        [string]$filename
    )

    $bom = New-Object byte[] 4
    $file = [System.IO.File]::Open($filename, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    try {
        $file.Read($bom, 0, 4)
    }
    finally {
        $file.Dispose() | Out-Null;
    }

    # Analyze the BOM
    if ($bom[0] -eq 0x2b -and $bom[1] -eq 0x2f -and $bom[2] -eq 0x76) {
        return "UTF7"
    }
    elseif ($bom[0] -eq 0xef -and $bom[1] -eq 0xbb -and $bom[2] -eq 0xbf) {
        return "UTF8"
    }
    elseif ($bom[0] -eq 0xff -and $bom[1] -eq 0xfe -and $bom[2] -eq 0 -and $bom[3] -eq 0) {
        return "UTF32"
    }
    elseif ($bom[0] -eq 0xff -and $bom[1] -eq 0xfe) {
        return "Unicode"
    }
    elseif ($bom[0] -eq 0xfe -and $bom[1] -eq 0xff) {
        return "BigEndianUnicode"
    }
    elseif ($bom[0] -eq 0 -and $bom[1] -eq 0 -and $bom[2] -eq 0xfe -and $bom[3] -eq 0xff) {
        return "bigendianutf32"
    }

    return $null;
}

function TryEncoding {
    param (
        $encoding    
    )
    # Dialogue: 0, 0:00:42.79, 0:00:46.59, Default, , 0000, 0000, 0000, , ����� ������ ��� �������� �������� (����� ��������) , ����� �
    $content = Get-Content -LiteralPath $file -Encoding $encoding;
    $script:FileContent = $content;
    $inValidOne = $content | Where-Object {
        $_ -match "�"
    } | Select-Object -First 1;
    return !$inValidOne;
}


function ReturnResult {
    param (
        $Encoding
    )
    
    if ($ReturnFileContent) {
        return @{
            Encoding    = $Encoding;
            FileContent = $script:FileContent;
        }
    }


    return $Encoding;
}

$encoding = (Get-Encoding -filename $file)[1];
if ($encoding) {
    return ReturnResult -Encoding $encoding;
}

$encodings = @(
    "UTF8",    
    "ansi"
);

foreach ($encoding in $encodings) {
    if (TryEncoding -encoding $encoding) {
        return ReturnResult -Encoding $encoding;
    }
}

return ReturnResult -Encoding "UTF8";


