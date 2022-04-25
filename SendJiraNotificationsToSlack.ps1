Import-Module PSSlack
Import-Module JiraPS


# Jira Configuration
$jiraServer = ""
$jiraUsername = ""
$jiraToken = ""
$jiraPwd = ConvertTo-SecureString $jiraToken -AsPlainText -Force
[pscredential]$jiraCredentials = New-Object System.Management.Automation.PSCredential ($jiraUsername, $jiraPwd)

Set-JiraConfigServer -Server $jiraServer
New-JiraSession -Credential $jiraCredentials

# Logs setup
$todayDate = get-date -format "dd-MM-yyyy"
New-Item -Path "" -Name "$todayDate.log"
$logFile = ""

function Send-Notification {

  $timestamp = get-date -format "HH:mm:ss"

  try {
    Send-SlackMessage -uri $teamUri -text $slackMessage -parse full
    Set-JiraIssue -Issue $issueKey -Fields $field -notify $false
    "$timestammp $customfield was set to true, notification sent via slack for $issueKey"
    
  }

  catch{
    $lastError = $ERROR[0]
    "$timestamp $customfield wasn't edited, notification failed for $issueKey, ERROR OCCURED: $lastError"

  }
}

while([int](get-date -format "HH") -lt 17){

  $notAcknowledgedIssues = Get-JiraIssue -Query 'query' -Fields '*all'
  $acknowledgedIssues = Get-JiraIssue -Query 'query' -fields '*all'


  $teamUri = "webhookURL" # testing purposes - test channel
  $teamManager = "@team.manager" # also testing purposes
  $groupDirector = "@group.director" # also tests

  foreach ($issue in $notAcknowledgedIssues){

    $issueKey =  $issue.Key
    $issueLink = $jiraServer + "/browse/" + $issueKey
    $remainingTime = $issue.customfield_xxxxx
    $maxSlaAck = $issue.customfield_xxxxx
    $issueSummary = $issue.summary


    # First SLA ackonwledgment notification wasn't send
    if($issue.customfield_xxxxx -ne 'true'){

      $customfield = ""
      $field = @{'customfield_xxxxx' = 'true'}
      $slackMessage = 'A new ticket was assigned. You have ' + $remainingTime + ' remaining to check if the ticket relates to your team scope and has all information. If yes, then set the status to Acknowledged.
      -------------------------------------------------------------------------------
      ' + $issueSummary + '
      ' + $issueLink + ''
      
      Send-Notification

    }
    

    #If half SLA for acknowledgment passed and notification wasn't send
    elseif(($issue.customfield_xxxxx -ne 'true') -and ([int]($issue.customfield_xxxxx)/2 -gt [int]$Issue.customfield_xxxxx)){

      $customfield = ""
      $field = @{'customfield_xxxxx' = 'true'}
      $slackMessage = '50% of the time has passed when the ticket was assigned to your team. You have ' + $remainingTime + ' remaining to check if the ticket relates to your team scope and has all information. 
      If yes, then set the status to Acknowledged.
      -------------------------------------------------------------------------------
      ' + $issueSummary + '
      ' + $issueLink + '
      ' + $teamManager + ''
        
      Send-Notification
      
    }

    #If SLA for acknowledgmend passed and notification wasn't send
    elseif(($issue.customfield_xxxxx -ne 'true') -and ([int]$Issue.customfield_xxxxx -le 0)){

      $customfield = ""
      $field = @{'customfield_xxxxx' = 'true'}
      $slackMessage = 'Maximum acknowledge time has passed. The maximum time is ' + $maxSlaAck + ' 
      Check if the ticket relates to your team scope and has all information. If yes, then set the status to Acknowledged.
      ' + $issueSummary + '
      ' + $issueLink + '
      ' + $teamManager + $groupDirector + ''

      Send-Notification

    }

  }

  foreach ($issue in $acknowledgedIssues) {

    $issueKey =  $issue.Key
    $issueLink = $jiraServer + "/browse/" + $issue.Key
    $remainingTime = $issue.customfield_xxxxx
    $maxSlaRes = $issue.customfield_xxxxx
    $issueSummary = $issue.summary


    #If first SLA notification wasn't send
    if($issue.customfield_xxxxx -ne 'true'){

      $customfield = ""
      $field = @{'customfield_xxxxx' = 'true'}
      $slackMessage = 'You have ' + $remainingTime + ' remaining to resolve the ticket. 
      -------------------------------------------------------------------------------
      ' + $issueSummary + '
      ' + $issueLink + ''
      
      Send-Notification

    }

    #If half SLA for resolution passed and notification wasn't send
    elseif(($issue.customfield_xxxxx -ne "true") -and ([int]($issue.customfield_xxxxx)/2 -gt [int]$Issue.customfield_xxxxx)){

      $customfield = ""  
      $field = @{'customfield_xxxxx' = 'true'}
      $slackMessage = '50% of the time has passed, ' + $remainingTime + 'left to resolve the ticket' + '
      -------------------------------------------------------------------------------
      ' + $issueSummary + '
      ' + $issueLink + '
      ' + $teamManager + ''
        
      Send-Notification  

      }

    #If SLA for acknowledgmend passed and notification wasn't send
    elseif(($issue.customfield_xxxxx -ne 'true') -and ([int]$Issue.customfield_xxxxx -le 0)){

    $customfield = "" 
    $field = @{'' = 'true'}
    $slackMessage = 'The maximum resolution time has passed for you to resolve the ticket. The maximum time is ' + $maxSlaRes + ' 
    Remember to add a comment to the ticket with a date when you plan to resolve it.
    -------------------------------------------------------------------------------
    ' + $issueSummary + '
    ' + $issueLink + '
    ' + $teamManager + $groupDirector + ''

    Send-Notification

    }
  }
Start-Sleep -Seconds 50
}
