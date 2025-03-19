#!/bin/bash

split_file_per_line_with_newlines() {
  input_file="$1"
  output_prefix="$2"
  line_number=1

  while IFS= read -r line; do
    word_count=0
    output_content=""
    for word in $line; do
      output_content+="$word "
      word_count=$((word_count + 1))
      if [ $word_count -eq 3 ]; then
        output_content+="\n"
        word_count=0
      fi
    done
    echo -e "$output_content" > "${output_prefix}-${line_number}.txt"
    line_number=$((line_number + 1))
  done < "$input_file"
}

show_help() {
  echo "Usage: $0 [--help] input_file output_prefix"
  echo
  echo "Arguments:"
  echo "  --help         Show this help message and exit"
  echo "  input_file     The input text file to be split"
  echo "  output_prefix  The prefix for the output files"
}

# Check for --help argument
if [ "$1" == "--help" ]; then
  show_help
  exit 0
fi

# Call the function with arguments
split_file_per_line_with_newlines "$1" "$2"

# Usage: split_file_per_line_with_newlines input.txt output
