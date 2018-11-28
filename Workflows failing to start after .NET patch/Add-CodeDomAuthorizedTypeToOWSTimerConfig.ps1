<#

 This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
 THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  
 We grant you a nonexclusive, royalty-free right to use and modify the sample code and to reproduce and distribute the object 
 code form of the Sample Code, provided that you agree: 
    (i)   to not use our name, logo, or trademarks to market your software product in which the sample code is embedded; 
    (ii)  to include a valid copyright notice on your software product in which the sample code is embedded; and 
    (iii) to indemnify, hold harmless, and defend us and our suppliers from and against any claims or lawsuits, including 
          attorneys' fees, that arise or result from the use or distribution of the sample code.
 Please note: None of the conditions outlined in the disclaimer above will supercede the terms and conditions contained within 
              the Premier Customer Services Description.
 ----------------------------------------------------------
 History
 ----------------------------------------------------------
 10/15/2018 - Added three additional authorized types

 09/20/2018 - Updated to automatically restart the timer service if any changes are made to the .config

 09/18/2018 - Updated to add the necessary <configSections> section, if it doesn't exist in the existing owstimer.exe.config file.

 09/18/2018 - Added an update to allow customers using Nintex to use the new IncludeNintexWorkflow switch to automatically add
              the necessary authorizedType required for Nintex

 09/17/2018 - Created script to update owstimer.exe.config file on farm servers.
 

   REFERENCE:
 
    https://blogs.msdn.microsoft.com/rodneyviana/2018/09/13/after-installing-net-security-patches-to-address-cve-2018-8421-sharepoint-workflows-stop-working/

  SUMMARY: 
    
    This script will update each of the specified servers defined at the bottom of the script. If additional servers are added to the 
    farm at a later date, this script will need to be run against the new server(s) in order for the updates to be added to the owstimer.exe.config

==============================================================
#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null

function Add-ConfigSections
{
    <#
    .Synopsis
       Adds the necessary configSections if not already present in owstimer.exe.config

    .DESCRIPTION
       Adds the necessary configSections if not already present in owstimer.exe.config

    .EXAMPLE
       Add-ConfigSections -XmlDocument $xmlDoc
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true)][System.Xml.XmlDocument]$XmlDocument
    )

    begin
    {
        $farmMajorVersion = (Get-SPFarm -Verbose:$false ).BuildVersion.Major
    }
    process
    {
        if( $farmMajorVersion -le 14)
        {
            $sectionGroup = New-Object PSObject -Property @{
                Path  = "/configuration/configSections"
                Name  = "/configuration/configSections/sectionGroup[@name='System.Workflow.ComponentModel.WorkflowCompiler'][@type='System.Workflow.ComponentModel.Compiler.WorkflowCompilerConfigurationSectionGroup, System.Workflow.ComponentModel, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35']"
                Value = '<sectionGroup name="System.Workflow.ComponentModel.WorkflowCompiler" type="System.Workflow.ComponentModel.Compiler.WorkflowCompilerConfigurationSectionGroup, System.Workflow.ComponentModel, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />'
            }

            $authorizedTypesSection = New-Object PSObject -Property @{
                Path  = "configuration/configSections/sectionGroup"
                Name  = "configuration/configSections/sectionGroup/section[@name='authorizedTypes'][@type='System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35']"
                Value = '<section name="authorizedTypes" type="System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />'
            }

            $authorizedRuleTypesSection = New-Object PSObject -Property @{
                Path  = "configuration/configSections/sectionGroup"
                Name  = "configuration/configSections/sectionGroup/section[@name='authorizedRuleTypes'][@type='System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35']"
                Value = '<section name="authorizedRuleTypes" type="System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />'
            }
        }
        else
        {
            $sectionGroup = New-Object PSObject -Property @{
                Path  = "/configuration/configSections"
                Name  = "/configuration/configSections/sectionGroup[@name='System.Workflow.ComponentModel.WorkflowCompiler'][@type='System.Workflow.ComponentModel.Compiler.WorkflowCompilerConfigurationSectionGroup, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35']"
                Value = '<sectionGroup name="System.Workflow.ComponentModel.WorkflowCompiler" type="System.Workflow.ComponentModel.Compiler.WorkflowCompilerConfigurationSectionGroup, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />'
            }

            $authorizedTypesSection = New-Object PSObject -Property @{
                Path  = "configuration/configSections/sectionGroup"
                Name  = "configuration/configSections/sectionGroup/section[@name='authorizedTypes'][@type='System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35']"
                Value = '<section name="authorizedTypes" type="System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />'
            }

            $authorizedRuleTypesSection = New-Object PSObject -Property @{
                Path  = "configuration/configSections/sectionGroup"
                Name  = "configuration/configSections/sectionGroup/section[@name='authorizedRuleTypes'][@type='System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35']"
                Value = '<section name="authorizedRuleTypes" type="System.Workflow.ComponentModel.Compiler.AuthorizedTypesSectionHandler, System.Workflow.ComponentModel, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" />'
            }
        }

        # ensure /configuration
        if( -not ($XmlDocument | Select-Xml -XPath "configuration").Node )
        {
            Initialize-Path -XmlDocument $XmlDocument -Path "configuration" | Out-Null
        }

        # ensure /configuration/configSections.  It must be the first child element of the <configuration> element.
        if( -not ($XmlDocument | Select-Xml -XPath "/configuration/configSections").Node )
        {
            $configNode = ($XmlDocument | Select-Xml -XPath "configuration").Node
            $configNode.InsertBefore( $XmlDocument.CreateElement("configSections"), $configNode.FirstChild) | Out-Null
        }

        # ensure /configuration/configSections/sectionGroup
        if( -not ($XmlDocument | Select-Xml -XPath $sectionGroup.Name) )
        {
            $parentNode = ($XmlDocument | Select-Xml -XPath $sectionGroup.Path).Node
            $parentNode.InnerXml += $sectionGroup.Value
        }

        # ensure /configuration/configSections/sectionGroup/section[@name='authorizedTypes']
        if( -not ($XmlDocument | Select-Xml -XPath $authorizedTypesSection.Name) )
        {
            $parentNode = ($XmlDocument | Select-Xml -XPath $authorizedTypesSection.Path).Node
            $parentNode.InnerXml += $authorizedTypesSection.Value
        }

        # ensure configuration/configSections/sectionGroup/section[@name='authorizedRuleTypes']
        if( -not ($XmlDocument | Select-Xml -XPath $authorizedRuleTypesSection.Name) )
        {
            $parentNode = ($XmlDocument | Select-Xml -XPath $authorizedRuleTypesSection.Path).Node
            $parentNode.InnerXml += $authorizedRuleTypesSection.Value
        }
    }
    end
    {
    }
}

function Add-AuthorizedTypes
{
    <#
    .Synopsis
       Adds the necessary authorizedTypes elements if not already present in owstimer.exe.config

    .DESCRIPTION
       Adds the necessary elements if not already present in owstimer.exe.config. Includes -IncludeNintexWorkflow
       if the local farm utilizes Nintex workflows.

    .EXAMPLE
       Add-AuthorizedTypes -XmlDocument $xmlDoc

    .EXAMPLE
       Add-AuthorizedTypes -XmlDocument $xmlDoc -IncludeNintexWorkflow
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true)][System.Xml.XmlDocument]$XmlDocument,
        [parameter(Mandatory=$false)][switch]$IncludeNintexWorkflow
    )
    
    begin
    {
        $authorizedTypes = @()
        $farmMajorVersion = (Get-SPFarm -Verbose:$false ).BuildVersion.Major
 
        if( $farmMajorVersion -le 14)
        {
            $systemAssemblyVersion = "2.0.0.0"
            $targetParentPath      = "configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes"
        }
        else
        {
            $systemAssemblyVersion = "4.0.0.0"
            $targetParentPath      = "configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes/targetFx[@version='v4.0']"
        }

        if($IncludeNintexWorkflow.IsPresent)
        {
            $authorizedTypes += New-Object PSCustomObject -Property @{
                Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
                Namespace = "System.CodeDom"
                TypeName  = "CodeTypeReferenceExpression"
            }
        }
        
        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodeBinaryOperatorExpression"
        } 

        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodePrimitiveExpression"
        } 

        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodeMethodInvokeExpression"
        } 

        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodeMethodReferenceExpression"
        } 

        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodeFieldReferenceExpression"
        } 

        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodeThisReferenceExpression"
        } 

        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=b77a5c561934e089"
            Namespace = "System.CodeDom"
            TypeName  = "CodePropertyReferenceExpression"
        }

        # added 10/15/2018 to match Nov 2018 CU
        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System.Workflow.Activities, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
            Namespace = "System.Workflow.Activities.Rules"
            TypeName  = "RuleDefinitions"
        }

        # added 10/15/2018 to match Nov 2018 CU
        $authorizedTypes += New-Object PSCustomObject -Property @{
            Assembly  = "System.Workflow.Activities, Version=$systemAssemblyVersion, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
            Namespace = "System.Workflow.Activities.Rules"
            TypeName  = "RuleExpressionCondition"
        }

        # added 10/15/2018 - TBD if necessary
        #$authorizedTypes += New-Object PSCustomObject -Property @{
        #    Assembly  = "Microsoft.SharePoint.WorkflowActions, Version=$farmMajorVersion.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"
        #    Namespace = "Microsoft.SharePoint.WorkflowActions"
        #    TypeName  = "*"
        #}
    }
    process
    {
        Initialize-Path -XmlDocument $XmlDocument -Path "configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes" | Out-Null

        if( $farmMajorVersion -gt 14 -and -not $XmlDocument.SelectSingleNode( "/configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes/targetFx[@version='v4.0']" ))
        {
            $parent = $XmlDocument.SelectSingleNode( "configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes")
            $parent.InnerXml += "<targetFx version=`"v4.0`" />"
        }

        foreach( $authorizedType in $authorizedTypes )
        {
            $object = New-Object PSObject -Property @{
                Path  = $targetParentPath
                Name  = "authorizedType[@Assembly='$($authorizedType.Assembly)'][@Namespace='$($authorizedType.Namespace)'][@TypeName='$($authorizedType.TypeName)'][@Authorized='True']" 
                Value = "<authorizedType Assembly=`"$($authorizedType.Assembly)`" Namespace=`"$($authorizedType.Namespace)`" TypeName=`"$($authorizedType.TypeName)`" Authorized=`"True`"/>"
            }

            $parentNode = $XmlDocument.SelectSingleNode( $object.Path )

            if( $parentNode -and -not $parentNode.SelectSingleNode( $object.Name ))
            {
                Write-Verbose -Message "Adding Authorized Type: $($object.Value)"
                $parentNode.InnerXml += $object.Value
            }
        }
    }
    end
    {
    }
        
}

function Initialize-Path
{
    <#
    .Synopsis
       Ensures the supplied XML node path has been created.

    .DESCRIPTION
       Ensures the supplied XML node path has been created in the supplied in the XMLDocument

    .EXAMPLE
        Initialize-Path -XmlDocument $xml -Path "configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes"

    .EXAMPLE
        Initialize-Path -XmlDocument $xml -Path "configuration/System.Workflow.ComponentModel.WorkflowCompiler/authorizedTypes/targetFx"
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true)][System.Xml.XmlDocument]$XmlDocument,
        [parameter(Mandatory=$true)][string]$Path
    )

    begin
    {
        $farmMajorVersion = (Get-SPFarm -Verbose:$false ).BuildVersion.Major
    }
    process
    {
        $currentNode = $XmlDocument

        foreach( $nodeName in $Path -split "/" )
        {
            $node = $currentNode.SelectSingleNode( $nodeName )
            
            if( -not $node )
            {
                $node = $currentNode.AppendChild($XmlDocument.CreateElement($nodeName))
            }

            $currentNode = $node
        }
        
        return $currentNode
    }
    end
    {
    }
}

function Add-CodeDomAuthorizedTypeToOWSTimerConfig
{
    <#
    .Synopsis
       Adds the necessary updates to the OWSTIMER.EXE.CONFIG file on the supplied computers.

    .DESCRIPTION
       Adds the necessary updates to the OWSTIMER.EXE.CONFIG file on the supplied computers.  Any existing OWSTIMER.EXE.CONFIG files
       will be backed to a timestamped file.

    .EXAMPLE
        Add-CodeDomAuthorizedTypeToOWSTimerConfig -ComputerName "Computer01", "Computer02"

    .EXAMPLE
        Add-CodeDomAuthorizedTypeToOWSTimerConfig -ComputerName "Computer01", "Computer02" -IncludeNintexWorkflow
    #>
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true)][string[]]$ComputerName,
        [parameter(Mandatory=$false)][switch]$IncludeNintexWorkflow
    )

    begin
    {
    }
    process
    {
        foreach( $computer in $ComputerName )
        {
            # get the path to owstimer.exe on each $ComputerName, just in case it's not in the expected location
            $timerServiceConfigPath = Get-WmiObject -Query "SELECT * FROM Win32_Service WHERE name = 'SPTimerV4'" -ComputerName $computer | SELECT @{Name="PathName"; Expression={$_.PathName.Trim('"')}}

            Write-Verbose -Message "Processing server: $($computer)"

            # convert local path to UNC PATH
            $uncPath = "\\$computer\$($timerServiceConfigPath.PathName)" -replace ":", "$"
            
            $fi = New-Object System.IO.FileInfo( $uncPath )
            
            # make sure the path exists
            if( -not $fi.Directory.Exists )
            {
                Write-Error -Message "Directory not found: $($fi.Directory.FullName)"
                continue
            }

            # add ".config" to the end of the file name
            $uncPath = "$uncPath.CONFIG"

            # create a default owstimer.exe.config, if none exists
            if( -not (Test-Path -Path $uncPath -PathType Leaf) )
            {
                # build a base XML file based on what 2010 would have
                $defaultXml = New-Object System.Text.StringBuilder
                $defaultXml.AppendLine("<?xml version=`"1.0`" encoding=`"utf-8`" ?>") | Out-Null
                $defaultXml.AppendLine("<configuration>")  | Out-Null
                $defaultXml.AppendLine("<runtime>")        | Out-Null
                $defaultXml.AppendLine("</runtime>")       | Out-Null
                $defaultXml.AppendLine("</configuration>") | Out-Null
                
                $defaultXml.ToString() | Set-Content -Path $uncPath
            }

            # make a backup of the file before doing anything
            Get-Content -Path $uncPath | Set-Content -Path "$($uncPath)_backup_$(Get-Date -Format 'yyyy_MM_dd_hh.mm.ss').config"
            
            # get the existing xml from the file
            [xml]$xml = Get-Content -Path $uncPath
            $originalXml = $xml.OuterXml

            # ensure the necessary config sections are present
            Add-ConfigSections -XmlDocument $xml

            # ensure authorizedTypes are added
            Add-AuthorizedTypes -XmlDocument $xml -IncludeNintexWorkflow:$IncludeNintexWorkflow.IsPresent

            if( $originalXml -ne $xml.OuterXml )
            {
                Write-Verbose -Message "Saving file changes on $computer"

                # save the changes
                $xml.Save($uncPath)

                # restart the timer service to pick up the changes
                Get-Service -Name SPTimerV4 -ComputerName $computer | Restart-Service
            }
        }
    }
    end
    {
    }
}


# get all the servers in the farm
$serverNames = @(Get-SPServer | ? { $_.Role -ne "Invalid" } | Select -ExpandProperty Name)

# add the owstimer.exe.config updates to all the servers.  Add the -IncludeNintexWorkflow if you use Nintex workflows on the farm
Add-CodeDomAuthorizedTypeToOWSTimerConfig -ComputerName $serverNames -Verbose
