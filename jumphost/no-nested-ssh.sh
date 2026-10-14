# Exam hosts: no SSH from one exam host to another, like the real CKA
if [[ $- == *i* ]]; then
  ssh() {
    echo "Nested SSH is not supported. Type 'exit' to go back to base, then ssh to the next host." >&2
    return 1
  }
fi
