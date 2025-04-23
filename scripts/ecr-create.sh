#!/bin/bash

# Example usage:
# ./create_ecr.sh auth-service user-service payment-service

# Set these environment variables ahead of time
# export AWS_REGION=us-west-2
# export AWS_PROFILE=your-profile-name
# export PROJECT_DIR=/path/to/your/project

MICROSERVICES=("$@") # All arguments become array elements
echo "Test before!"
echo $MICROSERVICES
echo "Test after!"

for PROJECT_NAME in "${MICROSERVICES[@]}"; do
  echo "Checking ECR for microservice: $PROJECT_NAME"

  repo=$(aws ecr describe-repositories \
    --repository-names "$PROJECT_NAME" \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    2>/dev/null)

  if [[ -n "$repo" ]]; then
    echo "⚠️  Repository '$PROJECT_NAME' already exists."
    continue
  fi

  echo "📦 Creating repository for '$PROJECT_NAME'..."
  REPOSITORY_URI=$(aws ecr create-repository \
    --repository-name "$PROJECT_NAME" \
    --query 'repository.repositoryUri' \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --output text \
    2>/dev/null)

  echo "✅ Created repository: $REPOSITORY_URI"

  # Create .ecr file (optional per microservice, can name it dynamically if needed)
  cd "$PROJECT_DIR" || exit 1
  export REPOSITORY_URI
  envsubst <.ecr.tmpl >".ecr-$PROJECT_NAME"

  echo "📝 Created ECR config: .ecr-$PROJECT_NAME"
done
