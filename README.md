# ArchitectureDecisionRecords

[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/ArchitectureDecisionRecords.svg)](https://www.powershellgallery.com/packages/ArchitectureDecisionRecords)

A PowerShell module for working with [ArchitectureDecisionRecords](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions) (ADRs).

## What is it?

ArchitectureDecisionRecords provides PowerShell functions that let you work with ADRs in a method compatible with the Bash-based [adr-tools](https://github.com/npryce/adr-tools).

## How do I use it?

### Installation

Use PowerShellGet to install from PowerShell Gallery.

```powershell
Install-Module -Name ArchitectureDecisionRecords
```

### Starting from scratch

```powershell
Initialize-Adr
```

### Adding a new ADR

```powershell
New-Adr -Title 'Use a database'
New-Adr -Title 'Do not use a database' -Supersede 2
```

### Generating a TOC

```powershell
Reset-AdrToc
```

### For more help

```powershell
Get-Command -Module ArchitectureDecisionRecords
```

```powershell
Get-Help New-Adr
```
