#!/bin/bash

# GitHub API endpoint
API_ENDPOINT="https://api.github.com"

# GitHub username and personal access token
USERNAME="<Your GitHub Username>"
TOKEN="<Your Personal Access Token>"

# List of repositories to check pull requests
REPOSITORIES=("repo1" "repo2" "repo3")

# Loop through each repository
for repo in "${REPOSITORIES[@]}"; do
  echo "Repository: $repo"
  
  # Get all pull requests in the repository
  pull_requests=$(curl -s -u "$USERNAME:$TOKEN" "$API_ENDPOINT/repos/$USERNAME/$repo/pulls")
  
  # Loop through each pull request
  while IFS= read -r pr; do
    pr_number=$(echo "$pr" | jq -r '.number')
    pr_title=$(echo "$pr" | jq -r '.title')
    pr_checks=$(curl -s -u "$USERNAME:$TOKEN" "$API_ENDPOINT/repos/$USERNAME/$repo/pulls/$pr_number/checks")
    pr_conversations=$(curl -s -u "$USERNAME:$TOKEN" "$API_ENDPOINT/repos/$USERNAME/$repo/issues/$pr_number/comments")
    
    # Check if pull request has failed checks or unresolved conversations
    if [[ $(echo "$pr_checks" | jq -r '.check_runs[] | select(.conclusion == "failure")') || $(echo "$pr_conversations" | jq -r 'length') -gt 0 ]]; then
      echo "Pull Request #$pr_number: $pr_title"
      echo "Failed checks:"
      echo "$pr_checks" | jq -r '.check_runs[] | select(.conclusion == "failure") | .name'
      echo "Unresolved conversations:"
      echo "$pr_conversations" | jq -r '.[] | select(.resolved_at == null) | .body'
      echo "-----"
    fi
  done < <(echo "$pull_requests" | jq -c '.[]')
done
