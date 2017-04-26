::----------------------------------------------------------------------------------------------------------------------------
::-- Filename: auto_import_firm_positions.bat
::-- Author: Easwaran Arnold
::-- Version: 1.00, 21-02-2017
::
:: Copy files from R:\Ftp\In\firm_positions to web server
::----------------------------------------------------------------------------------------------------------------------------

@echo off

::Set Log File path
set logfile=C:\inetpub\wwwroot\risk\auto_import_firm_positions.log

::Set time with leading zero
set vTime=%TIME: =0%

::Set current date and time for file name
set file_name=%date:~10,4%%date:~7,2%%date:~4,2%_%vTime:~0,2%

cd\
cd C:\inetpub\wwwroot\risk\files

::Write to log file when import starts
echo Started auto_import_firm_positions: %date% %time:~0,8%: %~nx0 >> %logfile%

::Copy files from FTP\In\firm_positions to web server
copy "\\10.10.10.10\Dealing Operations\FTP\In\firm_positions\firm_positions_LD4_%file_name%.csv" .\firm_positions_LD4_%file_name%.csv
copy "\\10.10.10.10\Dealing Operations\FTP\In\firm_positions\firm_positions_NY4_%file_name%.csv" .\firm_positions_NY4_%file_name%.csv

::Run php file to import data to table
if exist "\\10.10.10.10\Dealing Operations\FTP\In\firm_positions\firm_positions_LD4_%file_name%.csv" "C:\Program Files (x86)\PHP\v5.3\php.exe" C:\inetpub\wwwroot\risk\auto_import_firm_positions.php firm_positions_LD4_%file_name%.csv firm_positions_NY4_%file_name%.csv

::Delete CSV files from web server after import
del C:\inetpub\wwwroot\risk\files\*%file_name%.csv

::Write to log file when import ends
echo Completed auto_import_firm_positions: %date% %time:~0,8%: %~nx0  >> %logfile%

cd C:\inetpub\wwwroot\risk