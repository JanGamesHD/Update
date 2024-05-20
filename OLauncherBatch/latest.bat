@echo off
:reload
cls
set version=1.0
echo OLauncher Batch
echo Version %version%
title OLauncher Batch
if not exist "%userprofile%\OLauncher" md "%userprofile%\OLauncher"
echo Checking Internet connection...
title OLauncher Batch: Checking Internet connection...
ping 1.1.1.1 -n 1 -w 1000 >nul
if not %errorlevel%==0 goto offlinelaunch
cls
title OLauncher Batch: Checking cURL...
echo Checking cURL...
set curl_exec=NOT_INSTALLED
if exist %windir%\system32\curl.exe set curl_exec=%windir%\system32\curl.exe
if exist %windir%\syswow64\curl.exe set curl_exec=%windir%\syswow64\curl.exe
if exist "%userprofile%\OLauncher\curl\curl.exe" set curl_exec="%userprofile%\OLauncher\curl\curl.exe"
if %curl_exec%==NOT_INSTALLED goto downloadcurl
if not exist "%userprofile%\OLauncher\disablebatchupdates.sys" goto checkforbatchupdate
:returnbatchupdate
if exist "%userprofile%\OLauncher\disableupdates.skip" goto launch
cls
echo Getting latest release...
title OLauncher Batch: Getting latest release...
%curl_exec% -v -i https://github.com/olauncher/olauncher/releases/latest | find /I "Location:" >"%userprofile%\OLauncher\out.txt"
set /p remoteversion=<"%userprofile%\OLauncher\out.txt"
cls
echo Version is: %remoteversion:~63%
set remoteversion=%remoteversion:~63%
goto compareversions

:downloadcurl
cls
echo cURL not installed.
echo Please wait...
set bitsadmin_exec=NOT_INSTALLED
if exist %windir%\system32\bitsadmin.exe set bitsadmin_exec=%windir%\system32\bitsadmin.exe
if exist %windir%\syswow64\bitsadmin.exe set bitsadmin_exec=%windir%\syswow64\bitsadmin.exe
if %bitsadmin_exec%==NOT_INSTALLED goto downloadmanually
cls
title OLauncher Batch: Press any key to start the download.
echo Downloading cURL via bitsadmin.
echo This might take a few Minutes.
echo.
echo Bitsadmin will take some time to start the download.
echo Press any key to start the download.
pause >NUL
title OLauncher Batch: Download in progress... Please wait.
%bitsadmin_exec% /TRANSFER "cURL-Download" /PRIORITY FOREGROUND "http://web.flamegames.de/curl-8.7.1_9-win64-mingw.zip" "%userprofile%\OLauncher\curl2.zip"
echo Verifying hash...
certutil -hashfile "%userprofile%\OLauncher\curl2.zip" MD5 | findstr /V ":" >"%userprofile%\OLauncher\curlhash.temp"
set /p curlhash=<"%userprofile%\OLauncher\curlhash.temp"
set curlhash=%curlhash: =%
if not %curlhash%==8aeb6402744153c2318f423edd81a01e goto hashverificationfailed
echo Hash verified.
goto unzipcurl

:hashverificationfailed
title OLauncher Batch: Hash check failed.
echo Unable to verify hash (curl).
echo.
echo Reasons:
echo - The download failed
echo - The file has been modified on the server.
echo 1) Reload
echo 2) Ignore
set /p opt=Opt: 
if %opt%==1 goto reload
if %opt%==2 goto unzipcurl
cls
goto hashverificationfailed

:unzipcurl
if exist "%userprofile%\OLauncher\unzip.exe" goto unzipcurl2
echo Downloading unzip.exe
title OLauncher Batch: Downloading dependencies...
bitsadmin /TRANSFER "unzip-Download" /PRIORITY FOREGROUND "http://stahlworks.com/dev/unzip.exe" "%userprofile%\OLauncher\unzip.exe"
echo Verifying hash...
certutil -hashfile "%userprofile%\OLauncher\unzip.exe" MD5 | findstr /V ":" >"%userprofile%\OLauncher\unzip.hash"
set /p unziphash=<"%userprofile%\OLauncher\unzip.hash"
set unziphash=%unziphash: =%
if not %unziphash%==75375c22c72f1beb76bea39c22a1ed68 goto unziphashfailed
goto unzipcurl2

:unziphashfailed
title OLauncher Batch: Hash check failed.
echo Unable to verify hash (unzip)
echo.
echo Reasons: 
echo - The download failed
echo - The file has been modified on the server.
echo 1) Reload
echo 2) Ignore
set /p opt=Opt: 
if %opt%==1 goto reload
if %opt%==2 goto unzipcurl2
cls
goto unziphashfailed

:unzipcurl2
cls
title OLauncher Batch: Extracting dependencies...
echo Extracing cURL...
"%userprofile%\OLauncher\unzip.exe" -j -o "%userprofile%\OLauncher\curl2.zip" -d "%userprofile%\OLauncher\curl"
echo Completed!
echo Reloading...
goto reload

:compareversions
title OLauncher Batch: Loading...
cls
echo Loading local version...
if not exist "%userprofile%\OLauncher\version.txt" goto downloadolauncher
set /p localversion=<"%userprofile%\OLauncher\version.txt"
if not %localversion%==%remoteversion% goto updatefound
echo You are on the latest version.
goto launch

:updatefound
title OLauncher Batch: Update found!
if exist "%userprofile%\OLauncher\v%remoteversion%.skip" goto launch
cls
echo An update has been found.
echo.
echo Current Version: %localversion%
echo Latest Version: %remoteversion%
echo.
echo Do you want to update to this release? (y/n)
set /p opt=Opt: 
if %opt%==y goto downloadolauncher
if %opt%==n goto skipupdate
goto updatefound

:downloadolauncher
title OLauncher Batch: Downloading OLauncher...
cls
if exist "%userprofile%\OLauncher\olauncher.jar" goto move4backup
echo Downloading OLauncher...
%curl_exec% --location https://github.com/olauncher/olauncher/releases/download/v%remoteversion%/olauncher-%remoteversion%-redist.jar >"%userprofile%\OLauncher\olauncher.jar"
echo %remoteversion%>"%userprofile%\OLauncher\version.txt"
set localversion=%remoteversion%
goto launch

:move4backup
title OLauncher Batch: Creating backup...
if not exist "%userprofile%\OLauncher\Old_Versions" md "%userprofile%\OLauncher\Old_Versions"
echo Backing up...
move "%userprofile%\OLauncher\olauncher.jar" "%userprofile%\OLauncher\Old_Versions\olauncher_v%localversion%.jar"
goto downloadolauncher

:launch
title OLauncher Batch: Preparing OLauncher...
cls
echo Preparing to launch OLauncher...
if not exist "%userprofile%\OLauncher\unzip.exe" goto downloadunzip
java -version
if %errorlevel%==0 goto preinstalledlaunch
set java_exec=NOT_INSTALLED
if exist "%userprofile%\OLauncher\Java\jdk-21.0.3+9\bin\java.exe" set java_exec="%userprofile%\OLauncher\Java\jdk-21.0.3+9\bin\java.exe"
if %java_exec%==NOT_INSTALLED goto downloadjava
goto launch2
:preinstalledlaunch
echo Local Java installation found. Using this JRE/JDK.
set java_exec=java
:launch2
title OLauncher Batch: Running
cls
echo Launching OLauncher v%localversion% ...
%java_exec% -jar "%userprofile%\OLauncher\olauncher.jar"
echo Launcher closed. Exiting...
pause
exit

:downloadjava
title OLauncher Batch: Downloading JDK21-Microsoft
cls
echo We could not find a local Java installation. Download Java... (JDK)
echo This might take some time.
%curl_exec% --location https://aka.ms/download-jdk/microsoft-jdk-21.0.3-windows-x64.zip >"%userprofile%\OLauncher\Java.zip"
echo Extracting Java...
md "%userprofile%\OLauncher\Java\"
"%userprofile%\OLauncher\unzip.exe" -o "%userprofile%\OLauncher\Java.zip" -d "%userprofile%\OLauncher\Java"
echo Done!
echo Reloading...
goto reload

:downloadunzip
title OLauncher Batch: Downloading dependencies...
echo Downloading unzip...
%curl_exec% http://stahlworks.com/dev/unzip.exe >"%userprofile%\OLauncher\unzip.exe"
echo Verifying hash...
certutil -hashfile "%userprofile%\OLauncher\unzip.exe" MD5 | findstr /V ":" >"%userprofile%\OLauncher\unzip.hash"
set /p unziphash=<"%userprofile%\OLauncher\unzip.hash"
set unziphash=%unziphash: =%
if not %unziphash%==75375c22c72f1beb76bea39c22a1ed68 goto unziphashfailed2
goto launch

:unziphashfailed2
title OLauncher Batch: Hash check failed.
echo Unable to verify hash (unzip)
echo.
echo Reasons: 
echo - The download failed
echo - The file has been modified on the server.
echo 1) Reload
echo 2) Ignore
set /p opt=Opt: 
if %opt%==1 goto reload
if %opt%==2 goto launch
cls
goto unziphashfailed2

:offlinelaunch
title OLauncher Batch: No internet connection.
cls
echo Not connected to the internet.
echo Preparing for launch...
java -version
if %errorlevel%==0 goto preinstalledlaunch
set java_exec=NOT_INSTALLED
if exist "%userprofile%\OLauncher\Java\jdk-21.0.3+9\bin\java.exe" set java_exec="%userprofile%\OLauncher\Java\jdk-21.0.3+9\bin\java.exe"
if %java_exec%==NOT_INSTALLED goto offlinejavaerror
goto launch2

:offlinejavaerror
title OLauncher Batch: Unable to start.
cls
echo You are not connected to the internet.
echo Java is not installed, unable to launch OLauncher.
echo Please connect to the internet and try again.
echo.
echo 1) Reload
echo 2) Bypass Ping check (use this if you have high ping)
echo 3) Exit
set /p opt=Opt: 
if %opt%==1 goto reload
if %opt%==2 goto bypasswarning
if %opt%==3 exit
goto offlinejavaerror

:skipupdate
title OLauncher Batch: Update settings
cls
echo 1) Remind me later
echo 2) Skip this version
echo 3) Dont check for updates in the future
echo 4) Cancel (Go back to the update prompt)
set /p opt=Opt: 
if %opt%==1 goto launch
if %opt%==2 goto addversionskip
if %opt%==3 goto disableupdates
if %opt%==4 goto updatefound
goto skipupdate

:addversionskip
title OLauncher Batch: Skipping update...
cls
echo Skipping update...
type NUL>"%userprofile%\OLauncher\v%remoteversion%.skip"
goto launch

:disableupdates
title OLauncher Batch: Disabling updates...
echo Disabling updates...
type NUL>"%userprofile%\OLauncher\disableupdates.skip"
goto launch

:checkforbatchupdate
echo Checking for Batch updates...
%curl_exec% https://raw.githubusercontent.com/JanGamesHD/Update/main/OLauncherBatch/currentversion.sys >"%userprofile%\OLauncher\batchlatest.temp"
set /p remotebatchversion=<"%userprofile%\OLauncher\batchlatest.temp"
if %remotebatchversion%==%version% goto returnbatchupdate
if exist "%userprofile%\OLauncher\skipbatch_%remotebatchversion%.sys" goto returnbatchupdate
:updatefoundbatch
cls
echo OLauncher Batch-Script update found.
echo Current Version: %version%
echo Latest Version: %remotebatchversion%
echo.
%curl_exec% https://raw.githubusercontent.com/JanGamesHD/Update/main/OLauncherBatch/changelog.txt
echo.
echo Check out the changelog: https://github.com/JanGamesHD/Update/releases/latest
echo Do you want to update to this release? (y/n)
set /p opt=Opt: 
if %opt%==y goto updatebatch
if %opt%==n goto updatesettingsbatch
goto updatefoundbatch

:updatesettingsbatch
cls
echo 1) Remind me later
echo 2) Skip this release
echo 3) Disable update checking
echo 4) Return to update page
set /p opt=Opt: 
if %opt%==1 goto returnbatchupdate
if %opt%==2 goto skipbatchrelease
if %opt%==3 goto disablebatchupdates
if %opt%==4 goto updatefoundbatch
goto updatesettingsbatch

:skipbatchrelease
echo Skipping this release...
type NUL>"%userprofile%\OLauncher\skipbatch_%remotebatchversion%.sys"
goto returnbatchupdate

:disablebatchupdates
echo Disabling updates...
type NUL>"%userprofile%\OLauncher\disablebatchupdates.sys"
goto returnbatchupdate


:updatebatch
cls
echo Downloading update...
%curl_exec% https://raw.githubusercontent.com/JanGamesHD/Update/main/OLauncherBatch/latest.bat >"%userprofile%\OLauncher\latest_batch.bat"
echo Writing updater...
echo Writing Updater-Script...
echo @echo off>"%userprofile%\OLauncher\batchupdater.bat"
echo timeout 1 >>"%userprofile%\OLauncher\batchupdater.bat"
echo copy "%userprofile%\OLauncher\latest_batch.bat" "%~f0">>"%userprofile%\OLauncher\batchupdater.bat"
echo start cmd /c "%~f0">>"%userprofile%\OLauncher\batchupdater.bat"
echo exit>>"%userprofile%\OLauncher\batchupdater.bat"
echo Starting update...
start "%userprofile%\OLauncher\batchupdater.bat"
exit