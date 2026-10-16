#!/bin/bash
# the chart is created in the home directory of the exam host
cd /home/candidate || exit 1
# Validate script for Question 9, Step 2: Check if Chart.yaml is modified correctly

# Check if the Chart.yaml file exists
if [ ! -f webapp/Chart.yaml ]; then
  echo "❌ Chart.yaml not found in webapp directory"
  exit 1
fi

# Check if the description is set correctly
description=$(grep "description:" webapp/Chart.yaml | sed 's/description: //g' | tr -d '"' | tr -d "'" | xargs)
if [ "$description" != "A simple web application" ]; then
  echo "❌ Chart description is not set to 'A simple web application'"
  echo "Current description: $description"
  exit 1
fi

# Check if the appVersion is set correctly
app_version=$(grep "appVersion:" webapp/Chart.yaml | sed 's/appVersion: //g' | tr -d '"' | tr -d "'" | xargs)
if [ "$app_version" != "1.2.3" ]; then
  echo "❌ Chart appVersion is not set to '1.2.3'"
  echo "Current appVersion: $app_version"
  exit 1
fi

echo "✅ Chart.yaml is modified correctly with the required metadata"
echo "Chart.yaml content:"
cat webapp/Chart.yaml
exit 0 