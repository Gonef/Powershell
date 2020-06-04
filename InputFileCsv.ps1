#input group name, share path and domain from csv file
Function Get-FileName($directory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $directory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
    
    }

$inputfile = Get-FileName ".\" 

$csv = Import-Csv $inputfile -Delimiter ";" 
