# Scrap Code [...temp1.querySelectorAll('left-nav-community-item')].map(m => ({id: m.id, name: m.prefixedName}))

function Join {
    param (
        $CommunityId
    )

    
    # -Body "{`"operation`":`"UpdateSubredditSubscriptions`",`"variables`":{`"input`":{`"inputs`":[{`"subredditId`":`"$CommunityId`",`"subscribeState`":`"SUBSCRIBED`"}]}},`"csrf_token`":`"39b4989a07633c0ea5aae6a1ab36d42f`"}"
}


Get-Content -LiteralPath "$PSScriptRoot\Communities.json" | ConvertFrom-Json | ForEach-Object {
    Write-Host "Joining $($_.name)";
    Join -CommunityId $_.id;
};