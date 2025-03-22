# Scrap Code [...temp1.querySelectorAll('left-nav-community-item')].map(m => ({id: m.id, name: m.prefixedName}))

function Join {
    param (
        $CommunityId
    )

    # Get Session From Console Network Tab
    
}


Get-Content -LiteralPath "$PSScriptRoot\Communities.json" | ConvertFrom-Json | ForEach-Object {
    Write-Host "Joining $($_.name)";
    Join -CommunityId $_.id;
};