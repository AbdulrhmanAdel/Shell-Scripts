[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$FilePath,
    [switch]$LogOtherDetails
)

#region Functions
function ParseTimeSpan {
    param (
        [string]$time
    )
    $edited = $time.Substring(0, $time.IndexOf(".") + 4)
    return [timespan]::Parse($edited )
}

function GetTagValue {
    param (
        $xml, $tag
    )
    $elements = $xml.GetElementsByTagName($tag);

    if (!$elements) {
        return $null
    }
    return $elements.Item(0).InnerXml;
}

function Get-Chapters {
    param (
        $path
    )

    $xmlData = & mkvextract chapters $path;
    $xmlData[0] = '<?xml version="1.0"?>';
    [xml]$xml = $xmlData;
    if (!$xml) {
        return @();
    }

    $chapters = @();
    $editionEntry = $xml.GetElementsByTagName("EditionEntry").Item(0);
    $editionEntry.ChildNodes | ForEach-Object {
        $tag = $_;
        switch ($tag.Name) {
            "ChapterAtom" {
                $chapter = @{
                    UID       = GetTagValue -xml $tag -tag "ChapterUID"
                    Start     = ParseTimeSpan -time (GetTagValue -xml $tag -tag "ChapterTimeStart")
                    End       = ParseTimeSpan -time (GetTagValue -xml $tag -tag "ChapterTimeEnd")
                    Hidden    = GetTagValue -xml $tag -tag "ChapterFlagHidden"
                    Enabled   = GetTagValue -xml $tag -tag "ChapterFlagEnabled"
                    Title     = GetTagValue -xml $tag -tag "ChapterString"
                    SegmentId = GetTagValue -xml $tag -tag "ChapterSegmentUID"
                }
                $chapter["Duration"] = ($chapter.End - $chapter.Start).TotalMilliseconds;
                $chapters += $chapter;
                break;
            }
            Default {
                if ($LogOtherDetails) {
                    Write-Host "$($tag.Name): $($tag.InnerText)"
                }
                break;
            }
        }
    }

    return $chapters;
}

#endregion

return Get-Chapters -path $filePath;