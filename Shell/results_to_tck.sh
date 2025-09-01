#!/bin/bash

split_file_per_line_with_newlines() {
  input_file="$1"
  temp_dir="$2"
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
    echo -e "$output_content" > "${temp_dir}/temp-${line_number}.txt"
    line_number=$((line_number + 1))
  done < "$input_file"
}

show_help() {
  echo "Usage: $0 [--help] input_file output_file template_file"
  echo
  echo "Arguments:"
  echo "  --help         Show this help message and exit"
  echo "  input_file     The input text file to be split"
  echo "  output_file    The output file for the tckconvert command"
  echo "  template_file  The template file for the tckconvert command"
}

# Check for --help argument
if [ "$1" == "--help" ]; then
  show_help
  exit 0
fi

# Check for the correct number of arguments
if [ "$#" -ne 3 ]; then
  show_help
  exit 1
fi

# Generate a UUID for the temporary directory
uuid=$(uuidgen)
temp_dir="/tmp/${uuid}"

# Create the temporary directory
mkdir -p "$temp_dir"

echo "temp dir::::"
echo $temp_dir

# Call the function with arguments
split_file_per_line_with_newlines "$1" "${temp_dir}"

# Run the tckconvert command
tckconvert ${temp_dir}/temp-'[]'.txt "$2" -voxel2scanner "$3" -force

# Clean up the temporary directory
rm -r "$temp_dir"
