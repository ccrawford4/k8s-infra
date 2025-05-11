#!/bin/bash
# Example usage:
# ./delete_ecr.sh auth-service user-service payment-service
# Set these environment variables ahead of time
# export AWS_REGION=us-west-2
# export AWS_PROFILE=your-profile-name
# export PROJECT_DIR=/path/to/your/project

MICROSERVICES=("$@") # All arguments become array elements
echo $MICROSERVICES

for PROJECT_NAME in "${MICROSERVICES[@]}"; do
  echo "Checking ECR for microservice: $PROJECT_NAME"
  REPO_EXISTS=$(aws ecr describe-repositories \
    --repository-names "$PROJECT_NAME" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    2>/dev/null)

  if [[ -z "$REPO_EXISTS" ]]; then
    echo "⚠️  No ECR repository found for '$PROJECT_NAME'."
    continue
  fi

  echo "🗑️  Deleting repository for '$PROJECT_NAME'..."
  aws ecr delete-repository \
    --repository-name "$PROJECT_NAME" \
    --force \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    1>/dev/null

  # Remove the corresponding .ecr file
  rm --force "$PROJECT_DIR/.ecr-$PROJECT_NAME"
  echo "✅ Deleted ECR repository and config for '$PROJECT_NAME'"
done
