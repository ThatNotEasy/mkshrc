#!/bin/env sh

# ==UserScript==
# @name         tree
# @namespace    https://github.com/$USER/mkshrc/blob/main/docs/tree
# @version      1.6
# @description  Make an advanced shell environment for Android devices
# @author       $USER
# @match        Android
# @source       https://github.com/kddnewton/tree
# ==/UserScript==

# Initialize counters for directories and files
dir_count=0
file_count=0
status=0

# Function to traverse directories recursively
traverse() {
   # Increment the directory counter
   dir_count=$((dir_count + 1))
   local directory="$1"
   local prefix="$2"

   # Get list of children, handling empty directories
   local children=""
   if [ -d "$directory" ] && [ "$(ls -A "$directory" 2>/dev/null)" ]; then
     children=$(ls -1d "$directory"/* 2>/dev/null)
   fi

   # Get the last child in the directory
   local last_child=$(echo "$children" | tail -n 1)

   # Loop through each item in the directory
   echo "$children" | while IFS= read -r child; do
     [ -z "$child" ] && continue

     local child_prefix='│   '
     local pointer='├── '

     # Check if the current child is the last one in the directory
     if [ "$child" = "$last_child" ] || [ -z "$last_child" ]; then
       pointer='└── '
       child_prefix='    '
     fi

     # Display the current child with the tree structure
     local display="${prefix}${pointer}${child##*/}"
     # If the child is a symbolic link, append the target path
     [ -L "$child" ] && display+=" -> $(readlink "$child")"
     echo "$display"

     # If child is a directory, recurse into it
     if [ -d "$child" ]; then
       # Skip symbolic links to directories to avoid infinite loops
       if [ ! -L "$child" ]; then
         traverse "$child" "${prefix}$child_prefix"
       else
         dir_count=$((dir_count + 1))
       fi
     elif [ -e "$child" ]; then
       # Increment the file counter
       file_count=$((file_count + 1))
     fi
   done
}

# Set the root directory from the first argument, default to current directory if not provided
root="${1:-.}"

# Check if the root directory is accessible
if [ -d "$root" -a -r "$root" ]; then
  echo "$root"
  traverse "$root" ""
  # Decrement the directory counter to exclude the root directory from the count
  ((dir_count--))
else
  echo "$root  [error opening dir]"
  status=2
fi

# Display the count of directories and files
echo
echo "$dir_count directories, $file_count files"
exit $status
