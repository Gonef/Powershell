 #input group name, share path and domain from csv file
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

$input = Import-Csv $inputfile -Delimiter ";" 

foreach ($item in $input){

#Taking last part of group name and translate it to permission name
	if 	($item.GROUPS.split("-")[-1] -eq "m") #Taking last part of group name and translate it to permission name
            {
            $PERMISSIONS = "Modify"
            }
        elseif 	($item.GROUPS.split("-")[-1] -eq "r")
            {
            $PERMISSIONS = "Read"
            }
	elseif 	(($item.GROUPS.split("-")[-1] -eq "rw") -or ($item.GROUPS.split("-")[-1] -eq "w"))
            {
            $PERMISSIONS = "Read,Write"
            }
        elseif 	($item.GROUPS.split("-")[-1] -eq "l")
            {
            $PERMISSIONS = "ReadData"
            }
	elseif 	($item.GROUPS.split("-")[-1] -eq "f")
            {
            $PERMISSIONS = "FullControl"
            }
	elseif 	(($item.GROUPS.split("-")[-1] -eq "x") -or ($item.GROUPS.split("-")[-1] -eq "e") -or ($item.GROUPS.split("-")[-1] -eq "re"))
            {
            $PERMISSIONS = "ReadAndExecute"
	    }
	
#Merging domain and group to full domain group name

$domainname = $item.DOMAIN
$groupname = $item.GROUPS
$domaingroupname = "$domainname\$groupname"

#Giving permissions to share		
$acl = Get-Acl $item.PATH

$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($domaingroupname,$PERMISSIONS,"Allow")

$acl.SetAccessRule($AccessRule)

$acl | Set-Acl $item.PATH 

}
