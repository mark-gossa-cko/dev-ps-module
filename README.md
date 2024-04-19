<h1> Dev PowerShell module </h1>
Location for quick and hacky little PowerShell cmdlets

- [Cmdlets](#cmdlets)
  - [gco (git commit)](#gco-git-commit)
  - [CodeArtifactLogin](#codeartifactlogin)
  - [Find-Code](#find-code)

# Cmdlets

## gco (git commit)

Commits and pushes changes. Creates remote branch if it doesn't exist.

## CodeArtifactLogin

Logs into AWS Code Artifact

## Find-Code

Finds code within your organization. Parameters:

| Parameter | Mandatory | Description |
| --- | --- | --- |
| Text | Yes | Code text to search for |
| Repository | No | Filters to search only within the specfied repository e.g. `vault-sdk` |
| Organization | No | Filters to search only within the specfied organization e.g. `cko-issuing`. Defaults to `cko-issuing`. |
