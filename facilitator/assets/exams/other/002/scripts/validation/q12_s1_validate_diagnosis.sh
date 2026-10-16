#!/bin/bash
# Validate script for Question 12, Step 1: Check if diagnosis file is created with analysis

# Check if the diagnosis file exists
if [ ! -f /tmp/exam/q12/diagnosis.txt ]; then
  echo "❌ Diagnosis file does not exist at /tmp/exam/q12/diagnosis.txt"
  exit 1
fi

# Check if the file has content
if [ ! -s /tmp/exam/q12/diagnosis.txt ]; then
  echo "❌ Diagnosis file exists but is empty"
  exit 1
fi

# Check if the file contains debugging information
# Look for common debugging terms and commands that would be used
if ! grep -E -i "(error|issue|problem|failed|debug|helm|not found|missing|incorrect)" /tmp/exam/q12/diagnosis.txt > /dev/null; then
  echo "❌ Diagnosis file does not appear to contain debugging analysis"
  echo "Expected to find error/issue descriptions"
  echo "File content:"
  cat /tmp/exam/q12/diagnosis.txt
  exit 1
fi

# the diagnosis must name the cause: the image / its tag
if ! grep -E -i "(image|tag|nonexistenttag|pull)" /tmp/exam/q12/diagnosis.txt > /dev/null; then
  echo "❌ Diagnosis does not name the cause (the container image tag)"
  cat /tmp/exam/q12/diagnosis.txt
  exit 1
fi

echo "✅ Diagnosis file has been created with debugging analysis"
echo "File content:"
cat /tmp/exam/q12/diagnosis.txt
exit 0 