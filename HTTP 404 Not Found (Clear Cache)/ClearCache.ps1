Add-PSSnapin -Name Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue

write-host "CLEAR CONFIG CACHE ON FARM" -fore green
$servers = get-spserver | ?{$_.role -ne "Invalid" }
foreach ($server in $servers) {
    $servername = $server.Address
    write-host "Stop Timer Service on server $servername" -fore yellow
    (Get-WmiObject Win32_Service -filter "name='SPTimerV4'" -ComputerName $servername).stopservice() | Out-Null
}

foreach ($server in $servers) {
	$servername = $server.Address
	$folders = Get-ChildItem ("\\" + $servername + "\C$\ProgramData\Microsoft\SharePoint\Config")
    
    write-host "NOTE: There should only be ONE CacheFolder on each Server (don't copy folders to same top-level folder as a backup!!)" -fore Red

    foreach ($folder in $folders) {
        $items = Get-ChildItem $folder.FullName -Recurse
        foreach ($item in $items){
			if ( $item.Name.ToLower() -eq "cache.ini" ) {   
				$cachefolder = $folder.FullName
                write-host "Found CacheFolder on Server $servername = $cachefolder" -fore Yellow
			}
		}
	}
	

    $cachefolderitems = Get-ChildItem $cachefolder -Recurse

    write-host "Delete all XML Files inside this CacheFolder" -fore Yellow
    foreach ($cachefolderitem in $cachefolderitems){
	    if ($cachefolderitem -like "*.xml"){
			$cachefolderitem.Delete()
	    }
	}

	$a = Get-Content $cachefolder\cache.ini
	write-host $a
	$a = 1
	write-host "Creating a new Cache.ini File on server $servername" -fore Yellow
	Set-Content $a -Path $cachefolder\cache.ini
}

foreach ($server in $servers){
	$servername = $server.Address
	write-host "START Timer Service on server $servername" -fore yellow
	(Get-WmiObject Win32_Service -filter "name='SPTimerV4'" -ComputerName $servername).startservice() | Out-Null
}
