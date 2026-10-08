#!/bin/bash
# Setup for Question 10
mkdir -p /tmp/exam/q10 && chmod 777 /tmp/exam /tmp/exam/q10

openssl req -new -newkey rsa:2048 -nodes -subj "/CN=john/O=developers" \
  -keyout /tmp/exam/q10/john.key -out /tmp/exam/q10/john.csr >/dev/null 2>&1
chmod 666 /tmp/exam/q10/john.key /tmp/exam/q10/john.csr

echo "Setup completed for Question 10"
exit 0
