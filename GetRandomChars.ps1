#Create Function for getting random chars from list
function GetRandomChars($length, $characters){
    $randomChar = 1..$length | ForEach-Object {
        Get-Random -Maximum $characters.length
        }
    $private:ofs=""
    return [String]$characters[$randomChar]
    }
