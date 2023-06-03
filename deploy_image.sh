#!/bin/bash

# Variables
DOCKER_IMAGE_NAME="my-docker-image"
DOCKER_IMAGE_TAG="latest"
S3_BUCKET_NAME="my-s3-bucket"
S3_BUCKET_PATH="docker-images"
WATCH_DIRECTORY="/path/to/watch/directory"

# Function to deploy Docker image and push to S3
deploy_and_push() {
    # Build Docker image
    docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG .

    # Tag Docker image
    docker tag $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG

    # Push Docker image to a Docker registry (e.g., Docker Hub)
    docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG

    # Create a timestamped folder for the image in S3
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    S3_FOLDER="$S3_BUCKET_PATH/$TIMESTAMP"
    aws s3 cp --recursive /path/to/docker/images s3://$S3_BUCKET_NAME/$S3_FOLDER

    # Optional: Clean up Docker images
    docker rmi $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
}

# Function to detect file changes and trigger deployment
monitor_changes() {
    echo "Monitoring $WATCH_DIRECTORY for changes..."
    while true; do
        changes=$(inotifywait -r -e modify,create,delete $WATCH_DIRECTORY 2>/dev/null)
        if [[ $changes ]]; then
            echo "Changes detected. Deploying Docker image and pushing to S3..."
            deploy_and_push
            echo "Deployment complete."
        fi
    done
}

# Function to handle Git post-receive hook
git_hook() {
    while read oldrev newrev refname; do
        if [[ $refname = "refs/heads/master" ]]; then
            echo "Git push detected. Deploying Docker image and pushing to S3..."
            deploy_and_push
            echo "Deployment complete."
        fi
    done
}

# Start monitoring changes
monitor_changes &

# Listen for Git post-receive hook
git_hook

