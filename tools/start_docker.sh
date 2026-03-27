#!/usr/bin/env bash

if ! docker info > /dev/null 2>&1; then
  echo "This script uses docker, and it isn't running - please start docker and try again!"
  exit 1
fi

############################################################
# Help                                                     #
############################################################
Help()
{
  # Display Help
  echo "Bootstraps a docker image for contributing changes to gentlewind-nvim"
  echo
  echo "Syntax: ./start_docker.sh [-b <branch_name>]"
  echo "options:"
  echo "-b     Create a new branch for the contribution"
  echo "-h     Shows this help menu"
  echo
}

# Get directory of script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Default options
BRANCH_NAME=gentlewind-nvim-contrib # Branch to checkout / create

while getopts "b:h" option; do
  case $option in
    b) # set branch name
      BRANCH_NAME=$OPTARG
      echo "Setting branchname to $OPTARG"
      ;;
    h) # display Help
      Help
      exit;;
    *)
      Help
      exit;;
  esac
done

cd "$SCRIPT_DIR" || exit

# Create the worktree if it doesn't already exist
if [[ ! -d "$SCRIPT_DIR"/gentlewind-nvim-contrib ]]; then
  echo "0. Creating new git worktree of gentlewind-nvim at $SCRIPT_DIR/gentlewind-nvim-contrib"
  if git show-ref --quiet refs/heads/"$BRANCH_NAME"; then
    git worktree add ./gentlewind-nvim-contrib "$BRANCH_NAME"
  else
    git worktree add ./gentlewind-nvim-contrib origin/main -b "$BRANCH_NAME"
  fi
fi

# CD into worktree
cd ./gentlewind-nvim-contrib || exit

echo "1. Setting up branch"
# If branch exists just check it out
if ! git symbolic-ref -q HEAD; then
  echo "In detached HEAD state, not moving branch"
elif git show-ref --quiet refs/heads/"$BRANCH_NAME"; then
  if [[ ! $( git rev-parse --abbrev-ref HEAD ) == "$BRANCH_NAME" ]]; then
    echo " - Checking out branch $BRANCH_NAME..."
    git checkout "$BRANCH_NAME"
  fi
else
  # Pull latest version of main
  echo " - Creating new branch off main..."
  git checkout -b "$BRANCH_NAME" main
  git fetch --quiet
  # If changes between local and origin, get latest changes
  if [[ ! $( git rev-list main...origin/main --count ) -eq 0 ]]; then
    echo " - WARN: There are upstream changes to main branch.  Please pull latest changes"
    read -p "   Do you want to continue creating $BRANCH_NAME? (y/n) " -n 1 -r
  fi
  # Create new branch for feature and check it out
  echo " - Creating new branch $BRANCH_NAME..."
  git checkout -b "$BRANCH_NAME"
fi

cd .. || exit
echo " - Success!  Checked out $BRANCH_NAME branch at:"
echo "   $SCRIPT_DIR/gentlewind-nvim-contrib"
echo ""

echo "2. Setting up docker environment"
# Ensure docker image exists
if [[ ! "$(docker images -q gentlewind-nvim-contrib)" ]]; then
  echo " - Docker image does not exist.  Building docker image..."
  docker build -t gentlewind-nvim-contrib .
fi

if [ "$(docker ps -aq -f status=exited -f name=gentlewind-nvim-contrib-container)" ]; then
  echo " - Cleaning up old container..."
  # cleanup
  docker rm gentlewind-nvim-contrib-container >> /dev/null
fi

# Create docker container if haven't already
echo " - Success! Running docker container gentlewind-nvim-contrib-container..."
docker run \
  -it \
  -e UID="1000" \
  -e GID="1000" \
  -v "$SCRIPT_DIR"/gentlewind-nvim-contrib:/home/gentlewind/.config/nvim \
  -v "$SCRIPT_DIR"/workspace:/home/gentlewind/workspace \
  --name gentlewind-nvim-contrib-container \
  --user gentlewind \
  gentlewind-nvim-contrib


