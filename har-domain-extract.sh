#!/bin/bash

# Check if a filename is provided as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "File $1 not found!"
    exit 1
fi

# Extract domain names from the .har file
jq '.log.entries[].request | {method,url}' "$1" | \
jq 'if .method=="GET" then .url else "" end' | \
grep -Eo "http(s?)://([^/]+)/?" | \
sed 's/^https\?:\/\///;s/\/$//' | \
sort | \
uniq
