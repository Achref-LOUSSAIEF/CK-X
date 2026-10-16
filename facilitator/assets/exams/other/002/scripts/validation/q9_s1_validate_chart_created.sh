#!/bin/bash
# the chart is created in the home directory of the exam host
cd /home/candidate || exit 1
# Validate script for Question 9, Step 1: Check if chart structure is created

# Check if the chart directory exists
if [ ! -d webapp ]; then
  echo "❌ Chart directory 'webapp' not found in current directory"
  echo "Current directory contents:"
  ls -la
  exit 1
fi

# Check for standard Helm chart files and directories
required_files=("Chart.yaml" "values.yaml" "templates/deployment.yaml" "templates/service.yaml")
for file in "${required_files[@]}"; do
  if [ ! -f "webapp/$file" ]; then
    echo "❌ Required chart file 'webapp/$file' not found"
    echo "Chart structure is incomplete"
    exit 1
  fi
done

# Check for Helm chart helper files
if [ ! -f "webapp/templates/_helpers.tpl" ] || [ ! -f "webapp/templates/NOTES.txt" ]; then
  echo "❌ Chart helper files not found"
  echo "Expected 'webapp/templates/_helpers.tpl' and 'webapp/templates/NOTES.txt'"
  exit 1
fi

echo "✅ Helm chart 'webapp' created with the correct structure"
echo "Chart structure:"
find webapp -type f | sort
exit 0 