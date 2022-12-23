# by 3Peso, 2022

#region Private Members
#region Constants
[string]$script:COLLECTPATH = "collectpath"
[string]$script:DESTINATION = "destinationpath"
[string]$script:ACTIONTAG = "action-"
[string]$script:MICROSOFT = "Microsoft*"
[string]$script:SPERATOR_PLACEHOLDER = "_"
#endregion Constants

#region Variables
[XML]$script:dataSpec = $null
[Hashtable]$script:variables = @{
    $script:COLLECTPATH=""
    $script:DESTINATION=""
}
#endregion Variables

function Get_RunningPlatform {
    return $PSVersionTable.OS
}

function Get_PathSeperator {
    if ($(Get_RunningPlatform) -like $script:MICROSOFT) {
        return "\"
    } else {
        return "/"
    }
}

function Replace_Seperator {
    param(
        [string]$value
    )

    return $value.Replace($script:SPERATOR_PLACEHOLDER, $(Get_PathSeperator))
}

function Ensure_Seperator {
    if ($script:variables[$script:COLLECTPATH] -eq "") {
        return
    }

    $path = $script:variables[$script:COLLECTPATH]
    $path = $path.TrimEnd($(Get_PathSeperator))
    $path += Get_PathSeperator
    $script:variables[$script:COLLECTPATH] = $path
    return $path
}

function Update_CollectPath {
    param(
        [string]$nodeName,
        [string]$childNodeName
    )

    # if node is given, we add something
    if ($null -ne $nodeName -and $nodeName -ne "") {
        $script:variables[$script:COLLECTPATH] += Replace_Seperator -value $nodeName
        Ensure_Seperator
    # If child node is given, we moved down a level and have to remove a portion of the path
    } else {
        $childNodePath = Replace_Seperator -value $childNodeName
        $childNodePath = $childNodePath.TrimEnd($(Get_PathSeperator))
        $childNodePath += $(Get_PathSeperator)
        $script:variables[$script:COLLECTPATH] = $script:variables[$script:COLLECTPATH].Replace($($childNodePath), "")
    }

    Write-Verbose "$($script:variables[$script:COLLECTPATH])"
}

function Is_Action {
    param(
        [System.Xml.XmlElement]$node
    )

    return $node.LocalName -like "$script:ACTIONTAG*"
}

function Invoke_Action {
    param(
        [System.Xml.XmlElement]$actionNode
    )

    $actionName = $actionNode.LocalName.Replace($script:ACTIONTAG, "")
    & $actionName -node $actionNode
}

function Traverse_Specification {
    param(
        [ValidateScript(
            { $_.GetType().toString() -ceq "System.Xml.XmlElement" `
            -or $_.GetType().toString() -ceq "System.Xml.XmlDocument" })]
        [System.Xml.XmlElement]$node
    )
    Update_CollectPath -nodeName $node.LocalName

    # Check if the current node has child nodes
    if ($node.HasChildNodes) {
        # Traverse each child node
        $node.ChildNodes | Foreach-Object {
            if ($_.GetType().toString() -ceq "System.Xml.XmlElement") {
                if (Is_Action -node $_) {
                    Invoke_Action -actionNode $_
                } else {
                    # Call the function recursively for each child node
                    Traverse_Specification -node $_
                }
            }
        }
    }

    Update_CollectPath -childNodeName $node.LocalName
}

function Load_Specification {
    param(
        $filePath
    )

    $script:dataSpec = Get-Content -path $filePath
}

function Initialize_DestinationPath {
    param(
        [string]$destinationPath
    )

    if ($null -eq $destinationPath -or $destinationPath -eq "") {
        # get execution path
        $script:variables[$script:DESTINATION] = $PSScriptRoot
    } else {
        $script:variables[$script:DESTINATION] = $destinationPath
    }
}
#endregion

#region Public Functions
function Get-SpecifiedData {
    param(
        [ValidateScript({Test-Path $_})]
        [Parameter(Mandatory=$true)]
        [string]
        $dataSpecFilePath,
        # Parameter for destination path
        [ValidateScript({Test-Path $_})]
        [string]
        $destinationPath
    )
    <#
    .SYNOPSIS
        Collects data from the system based on a given specification
    .DESCRIPTION
        Collects data from the system based on a given specification
    .PARAMETER dataSpecFilePath
        Path to the data specification file
    .PARAMETER destinationPath
        Path to the destination folder
    .EXAMPLE
        Get-SpecifiedData -dataSpecFilePath "C:\DataSpec.xml" -destinationPath "C:\Data"
    #>
    # Load data specification
    Load_Specification -filePath $dataSpecFilePath
    # Initialize destination path
    Initialize_DestinationPath -destinationPath $destinationPath
    # Traverse Data Tree
    Traverse_Specification -node $script:dataSpec.
}

#region Actions
function Copy-File {
    param(
        [System.Xml.XmlElement]$node
    )
    # get help for Get-Help
    <#
    .SYNOPSIS
        Copies a file from the source path to the destination path
    .DESCRIPTION
        Copies a file from the source path to the destination path
    .PARAMETER node
        The xml node containing the file name in the inner text of the xml element
    .EXAMPLE
        Copy-File -node $node
    #>
    $sourceFile = $node.InnerText
    $sourceFilePath = $script:variables[$script:COLLECTPATH] + $sourceFile
    if (Test-Path -Path $sourceFilePath) {
        $destinationFilePath = $script:variables[$script:DESTINATION] + $sourceFile

        Write-Verbose "Copying file from $sourceFilePath to $destinationFilePath"
        Copy-Item -Path $sourceFilePath -Destination $destinationFilePath -Force
    } else {
        throw "File $sourceFilePath does not exist"
    }
}
#endregion Actions
#endregion Public Functions

#region Exports
Export-ModuleMember -Function Get-SpecifiedData -Alias gsd
Export-ModuleMember -Function Copy-File -Alias cf
#endregion Exports
