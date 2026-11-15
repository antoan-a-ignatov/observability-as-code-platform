#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Creates a GitHub milestone and its issues from a JSON file.

.DESCRIPTION
    Reads one milestone definition from a JSON file and makes GitHub match it.
    The milestone is found by its title, or created if it does not exist.
    Each issue is created open and assigned to the milestone, unless an issue
    with the same key already exists. The key is stored in the issue body as a
    hidden HTML comment, so titles can repeat across milestones.
    Existing milestones and issues are left unchanged, so the script is safe to
    run again. Use -WhatIf to see what would be created without creating it.

.PARAMETER MilestoneFile
    Path to the milestone JSON file, for example ./scripts/milestones/M1.json.

.PARAMETER Repository
    Target GitHub repository in owner/name form.

.EXAMPLE
    ./scripts/New-GitHubMilestoneIssues.ps1 -MilestoneFile ./scripts/milestones/M1.json -Repository owner/observability-as-code-platform -WhatIf

    Shows which milestone and issues would be created, without creating anything.

.EXAMPLE
    ./scripts/New-GitHubMilestoneIssues.ps1 -MilestoneFile ./scripts/milestones/M1.json -Repository owner/observability-as-code-platform

    Creates the M1 milestone and any of its issues that do not exist yet.

.NOTES
    Requires a GitHub token in the GITHUB_TOKEN environment variable: a
    fine-grained personal access token for the target repository only, with
    read and write access to issues. Set it in the current shell session; never
    store it in a file.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$MilestoneFile,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$')]
    [string]$Repository
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$token = $env:GITHUB_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'The GITHUB_TOKEN environment variable is not set.'
}

$headers = @{
    Authorization          = "Bearer $token"
    Accept                 = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2026-03-10'
}
$apiBase = "https://api.github.com/repos/$Repository"

function Get-AllPages {
    param([string]$Uri)
    Invoke-RestMethod -Uri $Uri -Headers $headers -FollowRelLink | ForEach-Object { $_ }
}

function Invoke-GitHubPost {
    param([string]$Uri, [hashtable]$Payload)
    Invoke-RestMethod -Method Post -Uri $Uri -Headers $headers `
        -ContentType 'application/json; charset=utf-8' -Body ($Payload | ConvertTo-Json)
}

$data = Get-Content -LiteralPath $MilestoneFile -Raw | ConvertFrom-Json
$created = @()
$skipped = @()

$milestone = Get-AllPages "$apiBase/milestones?state=all&per_page=100" |
    Where-Object { $_.title -eq $data.milestone.title } |
    Select-Object -First 1

if ($milestone) {
    $skipped += "Milestone '$($data.milestone.title)' (#$($milestone.number))"
}
elseif ($PSCmdlet.ShouldProcess($Repository, "Create milestone '$($data.milestone.title)'")) {
    $milestone = Invoke-GitHubPost "$apiBase/milestones" @{
        title       = $data.milestone.title
        description = $data.milestone.description
    }
    $created += "Milestone '$($milestone.title)' (#$($milestone.number))"
}

$existingIssues = Get-AllPages "$apiBase/issues?state=all&per_page=100"

foreach ($issue in $data.issues) {
    $marker = "<!-- key: $($issue.key) -->"
    $existing = $existingIssues |
        Where-Object { $_.body -and $_.body.Contains($marker) } |
        Select-Object -First 1

    if ($existing) {
        $skipped += "Issue '$($issue.title)' (#$($existing.number))"
        continue
    }

    if ($PSCmdlet.ShouldProcess($Repository, "Create issue '$($issue.title)'")) {
        if (-not $milestone) {
            throw "Milestone '$($data.milestone.title)' does not exist; cannot create issues."
        }
        $body = ($issue.body -join "`n") + "`n`n" + $marker
        $newIssue = Invoke-GitHubPost "$apiBase/issues" @{
            title     = $issue.title
            body      = $body
            milestone = $milestone.number
        }
        $created += "Issue '$($newIssue.title)' (#$($newIssue.number))"
    }
}

Write-Output "Created: $($created.Count)"
$created | ForEach-Object { Write-Output "  + $_" }
Write-Output "Skipped (already exist): $($skipped.Count)"
$skipped | ForEach-Object { Write-Output "  = $_" }
