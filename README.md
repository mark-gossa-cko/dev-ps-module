<h1> Dev PowerShell module </h1>
Location for quick and hacky little PowerShell cmdlets

- [Cmdlets](#cmdlets)
  - [gco (git commit)](#gco-git-commit)
  - [CodeArtifactLogin](#codeartifactlogin)
  - [Find-Code](#find-code)
  - [Start-FocusSession](#start-focussession)

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

## Start-FocusSession

Sets Slack to Do Not Disturb and starts a Windows focus session for the given number of minutes. The always-on-top focus timer is moved to the top right of the laptop screen if it opens on an external monitor. Parameters:

| Parameter | Mandatory | Description |
| --- | --- | --- |
| Minutes | Yes | Length of the focus session and Slack DND in minutes (1-240) |
| SlackToken | No | Slack user token (`xoxp-`) with the `dnd:write` scope. Defaults to the `SLACK_USER_TOKEN` environment variable. |
