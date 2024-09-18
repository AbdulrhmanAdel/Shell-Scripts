$file = $args[0];
return Is-Audio.ps1 $file -or `
    Is-Video.ps1 $file;
