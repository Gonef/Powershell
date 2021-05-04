Function Get-FileName($directory)
{
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

foreach ($line in $csv)
    {
    $ServerName = $line.ServerName    
    $ShareList = Invoke-Command -cn $ServerName {Get-SmbShare}
    $AccessList = @()

    foreach ($row in $ShareList)
        {
            try
            {
            $AccessList += Invoke-Command -cn $ServerName {Get-Acl -path $row.Path}
            }
            catch
            {
            continue
            }

        }
    
    $AccessList | Export-csv -Path .\$ServerName.csv -NoTypeInformation -Delimiter ";"

    }
