#!/bin/bash


# Get the CSV file name from the user
#echo "Enter the CSV file name to analyze: "
#read CSV_FILE
CSV_FILE="sales.csv"
# Create the output file if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
  echo  "File doesn't exist:)"
fi

# Display the menu
echo "Select an option:"
echo "1. Display number of rows and columns"
echo "2. List unique values in a specified column"
echo "3. Display column names (header)"
echo "4. Minimum and maximum values for numeric columns"
echo "5. The most frequent value for categorical columns"
echo "6. Calculating summary statistics (mean, median, standard deviation) for numeric columns"
echo "7. Filtering and extracting rows and column based on user-defined conditions"
echo "8. Sorting the CSV file based on a specific column"
echo "0. Exit"

# Get the user's choice
read choice

# Perform the selected operation
case $choice in
  1)
# Use awk to count rows and columns
num_rows=$(awk 'END {print NR}' "$CSV_FILE")
num_columns=$(awk -F',' 'NR==1 {print NF}' "$CSV_FILE")

# Display the results
echo "Number of rows: $num_rows"
echo "Number of columns: $num_columns"
    ;;
  2)
# Prompt the user to enter the column number
read -p "Enter the column number: " column_number

# Use awk to extract unique values from the specified column
unique_values=$(awk -F',' -v col="$column_number" 'NR>1 {print $col}' "$CSV_FILE" | sort -u)

# Display the unique values
echo "Unique values in column $column_number:"
echo "$unique_values"
    ;;
  3)
# Use awk to extract and display the header (first row)
header=$(awk -F',' 'NR==1 {print}' "$CSV_FILE")

# Display the column names (header)
echo "Column names (header):"
echo "$header"
    ;;
  4)
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
for col_index in "${numeric_columns[@]}"; do
    min_max=$(awk -F',' -v col="$col_index" 'NR>1 {if (min=="") min=max=$col; if ($col<min) min=$col; if ($col>max) max=$col} END {print min, max}' "$CSV_FILE")
    echo "Column $col_index: Min = ${min_max%% *}, Max = ${min_max##* }"
done
    ;;
  5)
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
    ;;
  6)
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
done
    ;;
  7)
# Prompt the user for the filter condition
read -p "Enter the filter condition (e.g., Unit Price > 400): " filter_condition

# Extract and display matching rows and columns based on the filter condition
awk -F',' -v filter="$filter_condition" 'NR==1 {print $1, $2} NR>1 && ('"$filter_condition"') {print $1, $2}' "$CSV_FILE"
    ;;
  8)
# Prompt the user for the column to sort by (e.g., "Total Profit")
read -p "Enter the column to sort by (e.g., Total Profit): " sort_column

# Sort the CSV file based on the specified column in ascending order
tail -n +2 "$CSV_FILE" | sort -t$'\t' -k $(echo "$(head -n 1 "$CSV_FILE" | tr '\t' '\n' | grep -n "$sort_column" | cut -d':' -f1)")
    ;;
  0)
    echo "Exiting..."
    clear
   exit
    ;;
esac
