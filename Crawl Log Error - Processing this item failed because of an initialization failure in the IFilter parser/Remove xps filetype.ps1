Add-PSSnapin Microsoft.SharePoint.Powershell

$ssa = Get-SPEnterpriseSearchServiceApplication
Set-SPEnterpriseSearchFileFormatState -SearchApplication $ssa 'xps' $FALSE

net stop spsearchhostcontroller
net start spsearchhostcontroller

