# Opens your Git directory.
Function ZP-OpenGitDir
{
    Set-Location $ZPConfig.Git.DefaultDir
}
# Gets your directory name.
Function ZP-GetGitRepo
{
    [CmdletBinding(PositionalBinding = $False)]
    Param
    (
        [Parameter()][Switch]$NoThrow
    )
    $Message = ZP-NewTempFile -Identifier ZP.Git
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:")
    {
        ZP-RemoveTempFile -TempFile $Message
        $Exception = ZP-NewObject -Source ZP.Git -Message "Not in a Git repository." -ZPObjectType ZP.Exception.GitDirectoryNotFoundException
        If ($NoThrow) 
        {
            Return $Exception
        } Else
        {
            Throw $Exception
        }
    } Else
    {
        ZP-RemoveTempFile -TempFile $Message
        Write-Output (Split-Path -Leaf (git rev-parse --show-toplevel))
    }
}
# Gets information about your Git head.
Function ZP-GetGitHead
{
    [CmdletBinding(PositionalBinding = $False)]
    Param (
        [Parameter()][Switch]$NoThrow
    )
    $Message = ZP-NewTempFile -Identifier ZP.Git
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:") {
        ZP-RemoveTempFile -TempFile $Message
        $Exception = ZP-NewObject -Source ZP.Git -Message "Not in a Git repository." -ZPObjectType ZP.Exception.GitDirectoryNotFoundException
        If ($NoThrow) {
            Return $Exception
        } Else {
            Throw $Exception
        }
    } Else {
        ZP-RemoveTempFile -TempFile $Message
        If (git branch --show-current = "") {
            Write-Output ("Detached : " + (git rev-parse --short HEAD))
        } Else {
            Write-Output ("Attached : " + (git branch --show-current))
        }
    }
}
Function ZP-GetGitStatus
{
    [CmdletBinding(PositionalBinding = $False)]
    Param (
        [Parameter()][Switch]$NoThrow
    )
    $Message = ZP-NewTempFile -Identifier ZP.Git
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:") {
        ZP-RemoveTempFile -TempFile $Message
        $Exception = ZP-NewObject -Source ZP.Git -Message "Not in a Git repository." -ZPObjectType ZP.Exception.GitDirectoryNotFoundException
        If ($NoThrow) {
            Return $Exception
        } Else {
            Throw $Exception
        }
    } Else {
        ZP-RemoveTempFile -TempFile $Message
        $Status = (git status -b --porcelain=v2 -z) -Split "`0"
        If (($Status[3] -Split " ")[1] -Ne "branch.ab") {
            If (($Status[2] -Split " ")[1] -Ne "branch.upstream") {
                Write-Output $ZPConfig.Git.Icons.Branch.Gone
            } Else {
                Write-Output $ZPConfig.Git.Icons.Branch.NotFound
            }
        } Else {
            Write-Output (($Status[3] -split " ")[2] -Replace "\+", $ZPConfig.Git.Icons.Branch.Ahead) + " " + (($Status[3] -split " ")[3] -Replace "-", $ZPConfig.Git.Icons.Branch.Behind)
        }
    }
}
Function ZP-SetUpstream
{   
    [CmdletBinding(PositionalBinding = $False)]   
    Param (
        [Parameter(Mandatory)][String]$LocalBranch,
        [Parameter(Mandatory)][String]$UpstreamBranch,
        [Parameter(Mandatory)][String]$UpstreamRemote,
        [Parameter()][Switch]$Force,
        [Parameter()][Switch]$NoThrow
    )
    $Message = ZP-NewTempFile -Identifier ZP.Git
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:") {
        ZP-RemoveTempFile -TempFile $Message
        $Exception = ZP-NewObject -Source ZP.Git -Message "Not in a Git repository." -ZPObjectType ZP.Exception.GitDirectoryNotFoundException
        If ($NoThrow) {
            Return $Exception
        } Else {
            Throw $Exception
        }
    } Else {
        If ($Force) {
            git config --unset branch.$($LocalBranch).remote
            git config --unset branch.$($LocalBranch).merge
            git config branch.$($LocalBranch).remote $UpstreamRemote
            git config branch.$($LocalBranch).merge refs/heads/$UpstreamBranch
        } Else {
            git branch -u $UpstreamRemote/$UpstreamBranch $LocalBranch 2> $Message.FullName
            If ((Get-Content $Message.FullName) -Match "error:") {
                "T"
            } Else {
                "F"
            }
            ZP-RemoveTempFile -TempFile $Message
        }
    }
}
# Get Git Status : git status -b --porcelain=v2 -z
