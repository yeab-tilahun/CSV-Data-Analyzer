#!/bin/bash


# Get the CSV file name from the user
echo "Enter the CSV file name to analyze: "
read CSV_FILE
# CSV_FILE="sales.csv"

# Create the output file if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
  echo  "File doesn't exist:)"
fi
#Functions to handle the menu options
function option_1(){
# Use awk to count rows and columns
num_rows=$(awk 'END {print NR}' "$CSV_FILE")
num_columns=$(awk -F',' 'NR==1 {print NF}' "$CSV_FILE")

# Display the results
echo "Number of rows: $num_rows"
echo "Number of columns: $num_columns"
temp=$(echo -e "Number of rows: $num_rows\nNumber of columns: $num_columns.\n")

option_9 "$temp"
}

function option_2(){
# Prompt the user to enter the column number
read -p "Enter the column number: " column_number

# Use awk to extract unique values from the specified column
unique_values=$(awk -F',' -v col="$column_number" 'NR>1 {print $col}' "$CSV_FILE" | sort -u)

# Display the unique values
echo "Unique values in column $column_number:"
echo "$unique_values"
temp=$(echo -e "Unique values in column $column_number:\n$unique_values\n")

option_9 "$temp"
}
function option_3(){
# Use awk to extract and display the header (first row)
header=$(awk -F',' 'NR==1 {print}' "$CSV_FILE")

# Display the column names (header)
echo "Column names (header):"
echo "$header"
temp=$(echo -e "Column names (header):\n$header\n")

option_9 "$temp"
}
function option_4(){
header=$(awk -F',' 'NR==1 {print}' "$CSV_FILE")

# Initialize variables to store the column indices and numeric flags
numeric_columns=()
non_numeric_columns=()

# Use awk to check if each column is numeric or not
for ((i=1; i<=$(echo "$header" | awk -F',' '{print NF}'); i++)); do
    is_numeric=$(awk -F',' -v col="$i" 'NR>1 {if ($col ~ /^[0-9]+(\.[0-9]+)?$/) print "numeric"; else print "not_numeric"; exit}' "$CSV_FILE")
    
    if [ "$is_numeric" == "numeric" ]; then
        numeric_columns+=("$i")
    fi
done

# Display min max for numeric columns
echo "Min and Max values for numeric columns:"
str1=$(echo -e "Min and Max values for numeric columns:\n:")
temp="${str1}"
for col_index in "${numeric_columns[@]}"; do
    min_max=$(awk -F',' -v col="$col_index" 'NR>1 {if (min=="") min=max=$col; if ($col<min) min=$col; if ($col>max) max=$col} END {print min, max}' "$CSV_FILE")
    echo "Column $col_index: Min = ${min_max%% *}, Max = ${min_max##* }"
    str2=$(echo -e "Column $col_index: Min = ${min_max%% *}, Max = ${min_max##* }")
    temp="${temp}"$'\n'"${str2}"
done


option_9 "$temp"
}
function option_5(){
# Use awk to extract column names (header)
header=$(awk -F',' 'NR==1 {print}' "$CSV_FILE")

# Initialize variables to store the column indices and their most frequent values
categorical_columns=()

# Use awk to check if each column is categorical
for ((i=1; i<=$(echo "$header" | awk -F',' '{print NF}'); i++)); do
    is_categorical=$(awk -F',' -v col="$i" 'NR>1 {if ($col !~ /^[0-9]+(\.[0-9]+)?$/) print "categorical"; else print "not_categorical"; exit}' "$CSV_FILE")
    
    if [ "$is_categorical" == "categorical" ]; then
        categorical_columns+=("$i")
    fi
done

# Display the most frequent value for each categorical column
for col_index in "${categorical_columns[@]}"; do
    most_frequent_value=$(awk -F',' -v col="$col_index" 'NR>1 {a[$col]++} END {for (val in a) if (a[val]>max) {max=a[val]; most=val} print most}' "$CSV_FILE")
    echo "Column $col_index: Most frequent value = $most_frequent_value"
done
}
function option_6(){
# Use awk to extract column names (header)
header=$(awk -F',' 'NR==1 {print}' "$CSV_FILE")

# Initialize variables to store the column indices and their statistics
numeric_columns=()

# Use awk to check if each column is numeric
for ((i=1; i<=$(echo "$header" | awk -F',' '{print NF}'); i++)); do
    is_numeric=$(awk -F',' -v col="$i" 'NR>1 {if ($col ~ /^[0-9]+(\.[0-9]+)?$/) print "numeric"; else print "not_numeric"; exit}' "$CSV_FILE")
    
    if [ "$is_numeric" == "numeric" ]; then
        numeric_columns+=("$i")
    fi
done
str1=$(echo -e "Summary statistics (mean, median, standard deviation:)\n")
temp="${str1}"
# Calculate and display statistics for each numeric column
for col_index in "${numeric_columns[@]}"; do
    column_data=$(awk -F',' -v col="$col_index" 'NR>1 {print $col}' "$CSV_FILE")
    IFS=$'\n' read -ra values <<< "$column_data"
    num_values=${#values[@]}

    # Calculate mean
    sum=0
    for value in "${values[@]}"; do
        sum=$(echo "$sum + $value" | bc)
    done
    mean=$(echo "scale=2; $sum / $num_values" | bc)

    # Calculate median
    sorted_values=$(echo "${values[@]}" | tr ' ' '\n' | sort -n)
    middle=$((num_values / 2))
    median=$(echo "$sorted_values" | sed -n "$((middle + 1))p")

    # Calculate standard deviation
    if [ "$num_values" -gt 1 ]; then
        sum_sq=0
        for value in "${values[@]}"; do
            diff=$(echo "$value - $mean" | bc)
            sq_diff=$(echo "$diff * $diff" | bc)
            sum_sq=$(echo "$sum_sq + $sq_diff" | bc)
        done
        std_dev=$(echo "scale=2; sqrt($sum_sq / ($num_values - 1))" | bc)
    else
        std_dev="N/A"
    fi

    echo "Column $col_index:"
    echo "  Mean: $mean"
    echo "  Median: $median"
    echo "  Standard Deviation: $std_dev"
    str2=$(echo -e "Column $col_index:\n")
    temp="${temp}"$'\n'"${str2}"
    str2=$(echo -e "Mean: $mean\n")
    temp="${temp}"$'\n'"${str2}"
    str2=$(echo -e "Median: $median\n")
    temp="${temp}"$'\n'"${str2}"
    str2=$(echo -e "Standard Deviation: $std_dev\n")
    temp="${temp}"$'\n'"${str2}"
done
option_9 "$temp"
}
# function option_7(){
# # Prompt the user for the filter condition
# read -p "Enter the filter condition (e.g., \$1 = "Asia"): " filter_condition

# # Extract and display matching rows and columns based on the filter condition
# awk -F',' -v filter="$filter_condition" 'NR==1 {print $1, $2} NR>1 && ('"$filter_condition"') {print $1, $2}' "$CSV_FILE"


# }
function option_7() {
    # Prompt the user for the filter condition
    read -p "Enter the filter condition (e.g., \$1 = \"Asia\"): " filter_condition

    # Use a variable to store the matching rows
    matching_rows=$(awk -F',' -v filter="$filter_condition" 'NR==1 {print $1, $2} NR>1 && ('"$filter_condition"') {print $1, $2}' "$CSV_FILE")

    # Check if any rows matched the filter
    if [ -n "$matching_rows" ]; then
        echo -e "\nMatching rows:\n"
        # Display the matching rows stored in the variable
        echo -e "$matching_rows\n"
        str1=$(echo -e "Matching rows:\n")
        str2=$(echo -e "$matching_rows\n")
        temp="${str1}"$'\n'"${str2}"
        option_9 "$temp"
    else
        echo "No matching rows found."
    fi
}

function option_8() {
    # Prompt the user for the column to sort by (e.g., "Total Profit")
    read -p "Enter the column to sort by (e.g., Total Profit): " sort_column

    # Sort the CSV data based on the specified column in ascending order
    sorted_data=$(tail -n +2 "$CSV_FILE" | sort -t$'\t' -k $(echo "$(head -n 1 "$CSV_FILE" | tr '\t' '\n' | grep -n "$sort_column" | cut -d':' -f1)"))

    # Check if the sorted data is not empty
    if [ -n "$sorted_data" ]; then
        echo "Sorted data based on '$sort_column' column in ascending order:"
        # Display the sorted data
        echo "$sorted_data"
        str1=$(echo -e "\nSorted data based on '$sort_column' column in ascending order:\n")
        str2=$(echo -e "\n$sorted_data")
        temp="${str1}"$'\n'"${str2}"
        option_9 "$temp"
    else
        echo "No data to sort or no matching column found."
    fi
}

function option_0(){
    echo "Exiting..."
    clear
   exit
}

function option_9(){
  #prompt user if they want to save the file
  read -p "Do you want to save the output? (y/n): " save_file
  if [ "$save_file" == "y" ]; then
  #prompt user for the file name
  read -p "Enter the file name: " file_name
  touch $file_name
  #echo "$1"
  echo "$1" >> $file_name
  echo "File saved successfully!"
  dir="Backup"
  mkdir -p $dir
  timestamp=$(date +%Y%m%d%H%M%S)
  backup_file="${dir}/backup_${timestamp}.tar.gz"
  echo "Backup In Progress..."
  tar -czf "$backup_file" "$file_name"
  echo "Backup Complete!"
  else
    echo "File not saved!"
  fi
}

# Function to display the menu using dialog
display_menu() {
  dialog --clear --title "CSV Data Analysis Tool" --menu "Select an option:" 20 100 9 \
    1 "Display number of rows and columns" \
    2 "List unique values in a specified column" \
    3 "Display column names (header)" \
    4 "Minimum and maximum values for numeric columns" \
    5 "The most frequent value for categorical columns" \
    6 "Calculating summary statistics (mean, median, standard deviation) for numeric columns" \
    7 "Filtering and extracting rows and column based on user-defined conditions" \
    8 "Sorting the CSV file based on a specific column" \
    0 "Exit" 2>&1 >/dev/tty
}

# Main loop
while true; do
  # Display the menu and get the user's choice using dialog
  CHOICE=$(display_menu)

  # Perform the selected operation based on the user's choice
  case $CHOICE in
    1)
      clear
      option_1
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    2)
      clear
      option_2
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    3)
      clear
      option_3
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    4)
      clear
      option_4
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    5)
      clear
      option_5
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    6)
      clear
      option_6
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    7)
      clear
      option_7
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    8)
      clear
      option_8
      read -n 1 -s -r -p "Press any key to continue..."
      clear
      ;;
    0)
      clear
      option_0
      echo "Exiting the program."
      exit 0
      ;;
    *)
      clear
      echo "Invalid option" 
      echo "Press any key to continue..."
      read -n 1 -s -r
      clear
      ;;
  esac
done
