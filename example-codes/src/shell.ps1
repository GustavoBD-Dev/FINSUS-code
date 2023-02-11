$Query="SELECT * FROM deudores LIMIT 20"
$Inst="10.7.83.17"
$DBName="princeps"
$UID="gblas"
$PASS="Blas.7"
Invoke-Sqlcmd2 -Serverinstance $Inst -Database $DBName -query $Query -Username $UID -Password $PASS