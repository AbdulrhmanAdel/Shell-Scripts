::==========================================
@Echo OFF
:: AveYo: define USER before asking for elevation since it gets replaced for limited accounts
@if not defined USER for /f "tokens=2" %%s in ('whoami /user /fo list') do set "USER=%%s">nul
:: AveYo: ask for elevation passing arguments
@set "_=set USER=%USER%&&call "%~f0" %*"&reg query HKU\S-1-5-19>nul 2>nul||(
@powershell -nop -c "start -verb RunAs cmd -args '/d/x/q/r',$env:_"&exit)
::==========================================