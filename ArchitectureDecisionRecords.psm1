<#
.Synopsis
Gets the directory ADRs are stored in for this project.

.Description
Gets the directory ADRS are stored in for this project. Directory is relative
to the correct working dir.

Supports an ADR_DIR environment variable or a .adr-dir file specifying the path.
If both are provided, an error will be thrown. If neither is provided, the default
doc/adr directory will be used.
#>
Function Get-AdrDir {
  [CmdletBinding()]
  [OutputType([string])]
  Param()

  if ($env:ADR_DIR -and (Test-Path '.adr-dir')) {
    throw 'Cannot use both the .adr-dir file and ADR_DIR env var.'
  } elseif ($env:ADR_DIR) {
    $env:ADR_DIR
  } elseif (Test-Path '.adr-dir') {
    Get-Content '.adr-dir'
  } else {
    'doc/adr'
  }
}

<#
.Synopsis
Gets a Markdown template to use for ADRs.

.Description
Get a Markdown template for use by ADRs, from one of many sources.

- Path parameter on this function
- ADR_TEMPLATE environment variable
- $(Get-AdrDir)/templates/template.md
- A template included in this module

.Parameter Path
Path to the template to use over the other auto-lookup sources.
#>
Function Get-AdrTemplate {
  [CmdletBinding()]
  [OutputType([string])]
  Param(
    [Parameter()]
    [string] $Path
  )

  $DstDir = Get-AdrDir
  $CustomTemplateFile = Join-Path -Path $DstDir -ChildPath 'templates/template.md'
  if ($Path) {
    if (-not (Test-Path -Path $Path)) {
      throw "Specified template path does not exist: $Path"
    }
    $TemplateFile = $Path
  } elseif ($env:ADR_TEMPLATE) {
    if (-not (Test-Path -Path $env:ADR_TEMPLATE)) {
      throw "Specified ADR_TEMPLATE does not exist: $($env:ADR_TEMPLATE)"
    }
    $TemplateFile = $env:ADR_TEMPLATE
  } elseif (Test-Path $CustomTemplateFile) {
    $TemplateFile = $CustomTemplateFile
  } else {
    $TemplateFile = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'template.md'
  }
  Get-Content -Path $TemplateFile -Encoding UTF8NoBOM
}

<#
.Synopsis
Converts an ADR object into ADR markdown.

.Description
Converts an ADR object into ADR markdown via a template. The template will be
sourced from one of the following locations:

- Template parameter on this function
- ADR_TEMPLATE environment variable
- $(Get-AdrDir)/templates/template.md
- A template included in this module

.Parameter InputObject
A custom object representing the state of the ADR to be rendered.

.Parameter Tempalte
Path to the template to use over the other auto-lookup sources.
#>
Function ConvertTo-AdrText {
  [CmdletBinding()]
  [OutputType([String])]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [PSCustomObject] $InputObject,

    [Parameter()]
    [string] $Template
  )

  Begin {
    $TemplateContent = Get-AdrTemplate -Path:$Template
  }
  Process {
    $Replacements = @{
      'NUMBER'       = $InputObject.Number;
      'TITLE'        = $InputObject.Title;
      'DATE'         = $InputObject.Date;
      'STATUS'       = $InputObject.Status;
      'CONTEXT'      = $InputObject.Context;
      'DECISION'     = $InputObject.Decision;
      'CONSEQUENCES' = $InputObject.Consequences;
    }
    $Content = $TemplateContent
    ForEach ($Replacement in $Replacements.GetEnumerator()) {
      $Content = $Content -creplace $Replacement.Name, $Replacement.Value
    }
    $Content
  }
}

<#
.Synopsis
Converts ADR markdown text into an ADR object.

.Description
Converts ADR markdown text into an ADR object.

.Parameter InputObject
A string of Markdown text to convert into an ADR object.
#>
Function ConvertFrom-AdrText {
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  Param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [string] $InputObject
  )

  Process {
    # Find title
    if ($InputObject -match '# (\d+)\. (.+)(?:`n|\s)+Date: (.+)') {
      $Number = [int]$Matches[1]
      $Title = $Matches[2].Trim()
      $Date = $Matches[3].Trim()
    }

    # Find status
    if ($InputObject -match '(?s)## Status(.*?)(?:##|$)') {
      $Status = $Matches[1].Trim()
    }

    # Find context
    if ($InputObject -match '(?s)## Context(.*?)(?:##|$)') {
      $Context = $Matches[1].Trim()
    }

    # Find decision
    if ($InputObject -match '(?s)## Decision(.*?)(?:##|$)') {
      $Decision = $Matches[1].Trim()
    }

    # Find consequences
    if ($InputObject -match '(?s)## Consequences(.*?)(?:##|$)') {
      $Consequences = $Matches[1].Trim()
    }

    [PSCustomObject]@{
      'Number'       = $Number;
      'Title'        = $Title;
      'Date'         = $Date;
      'Status'       = $Status;
      'Context'      = $Context;
      'Decision'     = $Decision;
      'Consequences' = $Consequences;
    }
  }
}

<#
.Synopsis
Initializes an ADR directory.

.Description
Initliazes an ADR directory and populates it with an initial decision to use ADRs.

.Parameter Target
If provided, creates an .adr-dir file with the target path as it's content, creates
the target path as a directory (if it doesn't already exist) and uses this as the
directory to populate the initial decision. If omitted, uses doc/adr as the target.
#>
Function Initialize-Adr {
  [CmdletBinding()]
  Param(
    [Parameter()]
    [string] $Target
  )

  if ($Target) {
    # If target provided, create .adir-dir file to point to it
    Set-Content -Path '.adr-dir' -Value "$($Target)" -Encoding UTF8NoBOM
  }

  $TemplateFile = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath 'init.md'
  New-Adr -Title 'Record architecture decisions' -Status 'Accepted' -Template $TemplateFile
}

<#
.Synopsis
Gets all ADRs or a single ADR from the ADR dir.

.Description
Gets all ADRs from the ADR dir, parsed as objects. If a number is specified, only that
ADR will be returned.

.Parameter Number
Get a single ADR with the number given. If not specified, all ADRs will be returned.
#>
Function Get-Adr {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  Param(
    [Parameter()]
    [int] $Number
  )

  $Dir = Get-AdrDir

  if (-not (Test-Path $Dir)) {
    Write-Error "ADR dir does not exist: $Dir"
    return @()
  }

  $AdrFiles = Get-ChildItem -Path $Dir -Filter '*.md' |
    Where-Object { $_.Name -match '(\d+)-.+\.md' } |
    Where-Object { ($Number -eq 0) -or ($Number -eq [int]$Matches[1]) }

  $AdrFiles | ForEach-Object {
    $Result = ConvertFrom-AdrText -InputObject (Get-Content -Path $_.FullName -Encoding UTF8NoBOM -Raw)
    Add-Member -InputObject $Result -MemberType NoteProperty -Name 'Path' -Value $_.FullName
    $Result
  }
}

<#
.Synopsis
Adds an link between two ADRs.

.Description
Adds a link between two ADRs, optionally with a reverse link.

.Parameter FromNumber
The number of the ADR to link from.

.Parameter FromLink
The text to prefix the forward link with.

.Parameter ToNumber
The number of the ADR to link to.

.Parameter ToLink
The text to prefix the reverse link with. If not specified the To ADR will not be modified.

.Example
Add-AdrLink -FromNumber 1 -ToNumber 2 -FromLink "Linked" -ToLink "Linked"

.Example
Add-AdrLink -FromNumber 1 -ToNumber 2 -FromLink "Superseded by" -ToLink "Supersedes"
#>
Function Add-AdrLink {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True)]
    [int] $FromNumber,

    [Parameter(Mandatory = $True)]
    [string] $FromLink,

    [Parameter(Mandatory = $True)]
    [int] $ToNumber,

    [Parameter()]
    [string] $ToLink
  )

  if ($FromNumber -eq $ToNumber -or $FromNumber -le 0 -or $ToNumber -le 0) {
    throw 'FromNumber and ToNumber must be different and greater than 0'
  }

  $FromAdr = Get-Adr -Number $FromNumber
  $ToAdr = Get-Adr -Number $ToNumber

  if ($FromAdr -and $ToAdr) {
    $ToFile = Split-Path -Path $ToAdr.Path -Leaf

    $FromAdr.Status = @"
$($FromAdr.Status)

$FromLink [$($ToAdr.Title)]($ToFile)
"@.Trim()

    $Content = ConvertTo-AdrText -InputObject $FromAdr
    Set-Content -Path $FromAdr.Path -Value $Content -Encoding UTF8NoBOM

    if ($ToLink) {
      Add-AdrLink -FromNumber $ToNumber -FromLink $ToLink -ToNumber $FromNumber
    }
  } else {
    Write-Error "Both ADR number $FromNumber and $ToNumber must exist."
  }
}

<#
.Synopsis
Removes the status in the given ADR.

.Description
Removes the status in the given ADR.

.Parameter Number
The number of the ADR to remove the status of.
#>
Function Remove-AdrStatus {
  [CmdletBinding()]
  [OutputType([hashtable[]])]
  Param(
    [Parameter(Mandatory = $True)]
    [int] $Number
  )

  if ($Number -le 0) {
    throw 'Invalid ADR number. Must be a positive integer'
  }

  $Adr = Get-Adr -Number $Number
  if ($Adr) {
    $Adr.Status = ''
    $Content = ConvertTo-AdrText -InputObject $Adr
    Set-Content -Path $Adr.Path -Value $Content -Encoding UTF8NoBOM
  } else {
    Write-Error "No ADR found for number: $Number"
  }
}

<#
.Synopsis
Create a new ADR.

.Description
Creates a new ADR numbered after the ADRs currently present in the ADR dir.

.Parameter Title
The title of the ADR.

.Parameter Status
The initial status of the ADR. Can be Proposed or Accepted (default).

.Parameter Supersede
An array of ADR numbers that are superseded by this ADR.

.Parameter Link
An array of link specs to add from this ADR. A link spec is as follows:

<ToNumber>:<ToLink>:<FromLink>

Example: '8:Amends:Amended by'

.Parameter Template
Path to the template to use over the other auto-lookup sources. This is meant for internal use only.
#>
Function New-Adr {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $True)]
    [string] $Title,

    [ValidateSet('Proposed', 'Accepted')]
    [Parameter()]
    [string] $Status = 'Accepted',

    [Parameter()]
    [int[]] $Supersede,

    [ValidatePattern('^\d+\:[\w -]+\:[\w -]+$')]
    [Parameter()]
    [string[]] $Link,

    [Parameter()]
    [string] $Template
  )

  $DstDir = Get-AdrDir
  $MaxAdrNum = [int](Get-Adr -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'Number' | Measure-Object -Maximum).Maximum
  $NewNum = $MaxAdrNum + 1

  # Remove any leading/trailing non-alphanumeric characters. Intermediate non-alphanumeric replaced by a dash
  $Slug = ($Title.ToLower() -replace '^[^a-z0-9]+|[^a-z0-9]+$', '') -replace '[^a-z0-9]+', '-'

  $FileName = '{0:d4}-{1}.md' -f $NewNum, $Slug
  $DstFile = Join-Path -Path $DstDir -ChildPath $FileName

  $Date = Get-Date -Format 'yyyy-MM-dd'

  $Adr = @{'Number' = $NewNum; 'Title' = $Title; 'Date' = $Date; 'Status' = $Status}
  $Content = ConvertTo-AdrText -InputObject $Adr -Template:$Template
  New-Item -ItemType Directory -Path $DstDir -Force | Out-Null
  Set-Content -Path $DstFile -Value $Content -Encoding UTF8NoBOM

  ForEach ($SupersedeNum in $Supersede) {
    Remove-AdrStatus -Number $SupersedeNum
    Add-AdrLink -FromNumber $NewNum -FromLink 'Supersedes' -ToNumber $SupersedeNum -ToLink 'Superseded by'
  }

  ForEach ($LinkSpec in $Link) {
    $ToNumber, $FromLink, $ToLink = $LinkSpec -split '\:'
    Add-AdrLink -FromNumber $NewNum -FromLink $FromLink -ToNumber $ToNumber -ToLink $ToLink
  }
}

<#
.Synopsis
Generates an ADR TOC in the ADR dir's README.md file.

.Description
Generates a table of contents of the ADRs in ADR dir and outputs
it into a README.md file as a sibling to the ADRs.
#>
Function Reset-AdrToc {
  [CmdletBinding()]
  Param()

  $Links = (Get-Adr | ForEach-Object { "- [$($_.Title)]($($LinkPrefix)$(Split-Path $_.Path -Leaf))" }) -join "`r`n"

  $Content = @"
# Architecture Decision Records

## Decisions

$Links
"@

  $Path = Join-Path -Path (Get-AdrDir) -ChildPath 'README.md'
  Set-Content -Path $Path -Value $Content -Encoding UTF8NoBOM
}
