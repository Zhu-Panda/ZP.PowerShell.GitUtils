# Opens your Git directory.
Function ZP-OpenGitDir
{
    [CmdletBinding(PositionalBinding = $False)]
    Param
    (
        [Parameter()][String]$Path
    )
    Set-Location $ZPConfig.GitUtils.DefaultDir
    If (($Path -Ne "") -And (Resolve-Path $Path -ErrorAction Ignore).Path.StartsWith($ZPConfig.GitUtils.DefaultDir))
    {
        Set-Location $Path
    }
}
# Gets your repo name.
Function ZP-GetGitRepo
{
    $Message = ZP-NewTempFile -Identifier ZP.GitUtils
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:")
    {
        ZP-RemoveTempFile -TempFile $Message
        Write-Error "Not in a Git repository."
    }
    Else
    {
        ZP-RemoveTempFile -TempFile $Message
        Write-Output (Split-Path -Leaf (git rev-parse --show-toplevel))
    }
}
# Gets information about your Git head.
Function ZP-GetGitHead
{
    $Message = ZP-NewTempFile -Identifier ZP.GitUtils
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:")
    {
        ZP-RemoveTempFile -TempFile $Message
        Write-Error "Not in a Git repository."
    }
    Else
    {
        ZP-RemoveTempFile -TempFile $Message
        If (git branch --show-current = "")
        {
            Write-Output ("Detached : " + (git rev-parse --short HEAD))
        }
        Else
        {
            Write-Output ("Attached : " + (git branch --show-current))
        }
    }
}
# Gets information about your Git status.
Function ZP-GetGitStatus
{
    $Message = ZP-NewTempFile -Identifier ZP.GitUtils
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:")
    {
        ZP-RemoveTempFile -TempFile $Message
        Write-Error "Not in a Git repository."
    }
    Else
    {
        ZP-RemoveTempFile -TempFile $Message
        $Status = (git status -b --porcelain=v2 -z) -Split "`0"
        If (($Status[3] -Split " ")[1] -Ne "branch.ab")
        {
            If (($Status[2] -Split " ")[1] -Ne "branch.upstream")
            {
                Write-Output $ZPConfig.GitUtils.Icons.Branch.Gone
            }
            Else
            {
                Write-Output $ZPConfig.GitUtils.Icons.Branch.NotFound
            }
        }
        Else
        {
            Write-Output (($Status[3] -split " ")[2] -Replace "\+", $ZPConfig.GitUtils.Icons.Branch.Ahead) + " " + (($Status[3] -split " ")[3] -Replace "-", $ZPConfig.GitUtils.Icons.Branch.Behind)
        }
    }
}
# Set your branch's upstream.
Function ZP-SetUpstream
{   
    [CmdletBinding(PositionalBinding = $False)]   
    Param
    (
        [Parameter(Mandatory)][String]$LocalBranch,
        [Parameter(Mandatory)][String]$UpstreamBranch,
        [Parameter(Mandatory)][String]$UpstreamRemote,
        [Parameter()][Switch]$Force
    )
    $Message = ZP-NewTempFile -Identifier ZP.GitUtils
    git status 2> $Message.FullName
    If ((Get-Content $Message.FullName) -Match "fatal:")
    {
        ZP-RemoveTempFile -TempFile $Message
        Write-Error "Not in a Git repository."
    }
    Else
    {
        If ($Force)
        {
            git config --unset branch.$($LocalBranch).remote
            git config --unset branch.$($LocalBranch).merge
            git config branch.$($LocalBranch).remote $UpstreamRemote
            git config branch.$($LocalBranch).merge refs/heads/$UpstreamBranch
        }
        Else
        {
            git branch -u $UpstreamRemote/$UpstreamBranch $LocalBranch 2> $Message.FullName
            If ((Get-Content $Message.FullName) -Match "error:")
            {
                Write-Error "Can't set upstream of branch $LocalBranch."
            }
            Else
            {
            }
            ZP-RemoveTempFile -TempFile $Message
        }
    }
}
# Get Git Status : git status -b --porcelain=v2 -z
