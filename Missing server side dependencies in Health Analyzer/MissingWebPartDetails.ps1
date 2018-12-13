param (
    [string]$DBserver = $(throw "Missing server name (please use -dbserver [dbserver])"),
    [string]$path = $(throw "Missing input file (please use -path [path\file.txt])")
)
 
#Set Variables
$input = @(Get-Content $path)
 
#Addin SharePoint2010 PowerShell Snapin
Add-PSSnapin -Name Microsoft.SharePoint.PowerShell
 
#Declare Log File
Function StartTracing
{
    $LogTime = Get-Date -Format yyyy-MM-dd_h-mm
    $script:LogFile = "MissingWebPartOutput-$LogTime.csv"
    Start-Transcript -Path $LogFile -Force
}
 
#Declare SQL Query function
function Run-SQLQuery ($SqlServer, $SqlDatabase, $SqlQuery)
{
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server =" + $SqlServer + "; Database =" + $SqlDatabase + "; Integrated Security = True"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close()
$DataSet.Tables[0]
}
 
 
function GetWebPartDetails ($wpid, $DBname)
    {
    #Define SQL Query and set in Variable
    $Query =  "SELECT * from AllDocs inner join AllWebParts on AllDocs.Id = AllWebParts.tp_PageUrlID where AllWebParts.tp_WebPartTypeID = '"+$wpid+"'"
 
    #Runing SQL Query to get information about Assembly (looking in EventReceiver Table) and store it in a Table
    $QueryReturn = @(Run-SQLQuery -SqlServer $DBserver -SqlDatabase $DBname -SqlQuery $Query | select Id, SiteId, DirName, LeafName, WebId, ListId, tp_ZoneID, tp_DisplayName)
 
    #Actions for each element in the table returned
        foreach ($event in $QueryReturn)
        {
            if ($event.id -ne $null)
                {
                #Get Site URL
                $site = Get-SPSite -Limit all | where {$_.Id -eq $event.SiteId}
    
                #Log information to Host
                Write-Host $wpid -nonewline -foregroundcolor yellow
                write-host ";" -nonewline
                write-host $site.Url -nonewline -foregroundcolor green
                write-host "/" -nonewline -foregroundcolor green
                write-host $event.LeafName -foregroundcolor green -nonewline
                write-host ";" -nonewline
                write-host $site.Url -nonewline -foregroundcolor gray
                write-host "/" -nonewline -foregroundcolor gray
                write-host $event.DirName -foregroundcolor gray -nonewline
                write-host "/" -nonewline -foregroundcolor gray
                write-host $event.LeafName -foregroundcolor gray -nonewline
                write-host "?contents=1" -foregroundcolor gray -nonewline
                write-host ";" -nonewline
                write-host $event.tp_ZoneID -foregroundcolor cyan
                }
         }
    }
 
#Start Logging
StartTracing
 
#Log the CVS Column Title Line
write-host "WebPartID;PageUrl;MaintenanceUrl;WpZoneID" -foregroundcolor Red
 
foreach ($event in $input)
    {
    $wpid = $event.split(";")[0]
    $DBname = $event.split(";")[1]
    GetWebPartDetails $wpid $dbname
    }
    
#Stop Logging
Stop-Transcript
