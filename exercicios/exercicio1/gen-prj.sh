#!/bin/bash

# Check if the project name was provided as an argument
if [ -z "$1" ]; then
 echo "Error: please provide the project name."
 echo "Usage: ./gen-prj.sh <project_name>"
 exit 1
fi

PRJ_NAME=$1
BASE_DIR="prj/$PRJ_NAME"

# Check if the project directory already exists
if [ -d "$BASE_DIR" ]; then
 echo "Error: project '$PRJ_NAME' already exists."
 exit 1
fi

# Create project directory structure
mkdir -p "$BASE_DIR/rtl"
mkdir -p "$BASE_DIR/tb"
mkdir -p "$BASE_DIR/docs"

# Create placeholder files to keep directories in version control
touch "$BASE_DIR/rtl/.empty"
touch "$BASE_DIR/tb/.empty"

# Create an empty README file
touch "$BASE_DIR/docs/README.md"

echo "Project '$PRJ_NAME' successfully created inside prj/"