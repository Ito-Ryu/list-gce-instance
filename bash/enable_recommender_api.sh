#!/bin/bash

CONF_FILE="project_id.conf"

if [ ! -f "$CONF_FILE" ]; then
  echo "Error: $CONF_FILE not found"
  exit 1
fi

while IFS= read -r PROJECT_ID || [ -n "$PROJECT_ID" ]; do
  if [[ -z "$PROJECT_ID" ]]; then
    continue
  fi

  echo "Enabling Recommender API for project: $PROJECT_ID"

  gcloud services enable recommender.googleapis.com --project="$PROJECT_ID"

  if [ $? -eq 0 ]; then
    echo "✅ Enabled successfully for $PROJECT_ID"
  else
    echo "❌ Failed to enable for $PROJECT_ID"
  fi

done < "$CONF_FILE"
