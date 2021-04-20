
Function Get-FileName($directory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $directory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    
    }

$inputfile = Get-FileName ".\" 
$TimeStamp = Get-Date -Format "MM-dd-yyyy-HH-mm"
$csv = Import-Csv $inputfile -Delimiter ";" 
$JavaTable = @()
$ErrorLog = @()

foreach ($line in $csv)
    {

    $srv = $line.server + '.' + $line.domain
        if (Test-Connection -Computername $srv -Quiet -Count 1)
        {
            Write-Host "Processing server: $srv "
            try
            {
            Enable-WSManCredSSP -Force -Role "Client" -DelegateComputer $srv
            Invoke-Command -cn $srv { Enable-WSManCredSSP -Force -Role "Client" -DelegateComputer MachineName }
            Invoke-Command -cn $srv { Set-Item WSMan:\localhost\Service\Auth\CredSSP true }
            $JavaVersion = Invoke-Command -cn $srv {get-package java*} | Select-Object Name,Source

            foreach ($Row in $JavaVersion)
                {
                $JavaTableBuild = [ordered]@{
                    ServerName = $line.server
                    Version = $Row.Name
                    Localization = $Row.Source
                    }
                    $JavaTable += New-Object PSObject -Property $JavaTableBuild
                }
            }
            catch
            {
            $ErrorLog += "$timestamp Unable to Check Java Version on $srv"
            }
        }
        else
        {
        $ErrorLog += "$timestamp Unable to Check Java Version on $srv"
        }
    }

$JavaTable | Export-Csv -Path .\"$TimeStamp.csv" -NoTypeInformation
Write-Host "Check Error.log file to see if any errors occured." -ForegroundColor Red
$ErrorLog >> errors.log
