#!/bin/bash

# Global variable to hold the current database name
current_db=""

create_database() {

    read -p "Enter database name: " db_name

    if [ -d "$db_name" ]; then
        echo "Database '$db_name' already exists."
    else
        mkdir "$db_name"
        echo "Database '$db_name' created successfully."
    fi

}

list_databases() {

    echo "All available databases:"
    ls -d */ 2>/dev/null || echo "No databases found."

}

connect_to_database() {

    read -p "Enter database name to connect: " db_name
    
    if [ -d "$db_name" ]; then
        echo "Connected to database '$db_name' successfully."
        cd "$db_name"
        current_db="$db_name"
        database_menu
    else
        echo "Database '$db_name' does not exist."
    fi

}

drop_database() {
 
    read -p "Enter database name to drop: " db_name
 
    if [ -d "$db_name" ]; then
        rm -r "$db_name"
        echo "Database '$db_name' dropped successfully."
    else
        echo "Database '$db_name' does not exist."
    fi

}

create_table() {

    read -p "Enter table name: " table_name
    
    if [ -f "$table_name" ]; then
        echo "Table '$table_name' already exists."
    else
        valid_data_types=("int" "string" "boolean" "double")
        
        while true; do
            
            read -p "Enter columns (name:type) separated by commas: " columns
            
            columns_valid=true
            IFS=',' read -r -a column_array <<< "$columns"
            
            for column_def in "${column_array[@]}"; do
                column_type=$(echo "$column_def" | cut -d: -f2)
                
                if [[ ! " ${valid_data_types[@]} " =~ " $column_type " ]]; then
                    echo "Invalid data type '$column_type'. Available types: int, string, boolean, double."
                    columns_valid=false
                    break
                fi

            done
            
            if $columns_valid; then
                break
            fi

        done

        read -p "Enter primary key column: " primary_key

        # Validate primary key
        if [[ ! "$columns" =~ $primary_key ]]; then
            echo "Primary key must be one of the columns."
            return
        fi

        # Save table schema
        echo "$columns" > "$table_name.meta"
        echo "PRIMARY_KEY=$primary_key" >> "$table_name.meta"
        touch "$table_name"
        echo "Table '$table_name' created with columns: '$columns'"
    
    fi

}

list_tables() {

    echo "Available tables:"
    ls *.meta 2>/dev/null | sed 's/.meta$//' || echo "No tables found."

}

drop_table() {

    read -p "Enter table name to drop: " table_name
    
    if [ -f "$table_name" ]; then
        rm "$table_name" "$table_name.meta"
        echo "Table '$table_name' dropped successfully."
    else
        echo "Table '$table_name' does not exist."
    fi

}

insert_into_table() {
    
    read -p "Enter table name: " table_name
    
    if [ ! -f "$table_name" ]; then
        echo "Table $table_name does not exist."
        return
    fi

    # Correctly construct the path to the .meta file
    meta_file="$table_name.meta"
    if [ ! -f "$meta_file" ]; then
        echo "Metadata file for table $table_name does not exist."
        return
    fi

    # Load table schema without using source
    columns=$(grep -v "PRIMARY_KEY" "$meta_file")
    primary_key=$(grep "PRIMARY_KEY" "$meta_file" | cut -d'=' -f2)
    IFS=',' read -r -a column_array <<< "$columns"
    primary_key_index=-1

    # Prepare to insert
    row=""
    for i in "${!column_array[@]}"; do

        column_name=$(echo "${column_array[$i]}" | cut -d: -f1)
        column_type=$(echo "${column_array[$i]}" | cut -d: -f2)

        if [[ "$column_name" == "$primary_key" ]]; then
            primary_key_index=$i
        fi

        while true; do

            read -p "Enter value for $column_name ($column_type): " value
            
            # Validate data type
            if [[ "$column_type" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "Invalid input, expected integer for $column_name."
            elif [[ "$column_type" == "string" && "$value" =~ [^a-zA-Z] ]]; then
                echo "Invalid input, expected string for $column_name."
            elif [[ "$column_type" == "boolean" && ! "$value" =~ ^(true|false)$ ]]; then
                echo "Invalid input, expected boolean (true/false) for $column_name."
            elif [[ "$column_type" == "double" && ! "$value" =~ ^-?[0-9]*\.[0-9]+$ ]]; then
                echo "Invalid input, expected double (floating-point number) for $column_name."
            else
                break
            fi

        done

        row="$row$value,"

    done

    row=${row%,}

    # Check primary key uniqueness
    if [[ $primary_key_index -ne -1 ]]; then

        primary_key_value=$(echo "$row" | cut -d, -f$((primary_key_index + 1)))
        if grep -q "^$primary_key_value," "$table_name"; then
            echo "Primary key value $primary_key_value already exists."
            return
        fi

    fi

    echo "$row" >> "$table_name"
    echo "Row inserted into '$table_name' successfully."

}

select_from_table() {

    read -p "Enter table name: " table_name
    
    if [ ! -f "$table_name" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    echo "Contents of table '$table_name':"
    cat "$table_name"

}

delete_from_table() {

    read -p "Enter table name: " table_name
    
    if [ ! -f "$table_name" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    read -p "Enter condition (e.g., column=value) for deletion: " condition
    
    column=$(echo "$condition" | cut -d= -f1)
    value=$(echo "$condition" | cut -d= -f2)

    # Find the column index using the metadata file
    columns=$(grep -v "PRIMARY_KEY" "$table_name.meta")
    IFS=',' read -r -a column_array <<< "$columns"
    column_index=-1
    
    for i in "${!column_array[@]}"; do
        
        col_name=$(echo "${column_array[$i]}" | cut -d: -f1)
        if [[ "$col_name" == "$column" ]]; then
            column_index=$((i + 1))
            break
        fi

    done

    if [[ $column_index -eq -1 ]]; then
        echo "Column '$column' does not exist."
        return
    fi

    # Perform the deletion based on the condition
    match_found=false
    awk -F, -v col="$column_index" -v val="$value" '
    {
        if ($col != val) {
            print $0
        } else {
            match_found = 1
        }
    } END { if (match_found == 0) print "No matching rows found." }' "$table_name" > tmp

    mv tmp "$table_name"

    if ! grep -q "No matching rows found." "$table_name"; then
        echo "Rows matching '$condition' deleted from '$table_name'."
    else
        echo "No matching rows found."
        sed -i '/No matching rows found./d' "$table_name"  # Remove the message from the file if no match
    fi

}

update_from_table() {

    read -p "Enter table name: " table_name
    
    if [ ! -f "$table_name" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    read -p "Enter condition (e.g., column=value) for updating: " condition
    read -p "Enter updates (e.g., column=new_value) separated by commas: " updates

    # Extract column to update and value to set
    IFS=',' read -r -a update_array <<< "$updates"
    declare -A update_dict
    
    for update in "${update_array[@]}"; do
        
        col_name=$(echo "$update" | cut -d= -f1)
        new_val=$(echo "$update" | cut -d= -f2)
        update_dict[$col_name]=$new_val
    
    done

    # Extract condition column and value
    condition_column=$(echo "$condition" | cut -d= -f1)
    condition_value=$(echo "$condition" | cut -d= -f2)

    # Find the column index using the metadata file
    columns=$(grep -v "PRIMARY_KEY" "$table_name.meta")
    IFS=',' read -r -a column_array <<< "$columns"
    condition_index=-1
    update_indices=()
    update_values=()
    
    for i in "${!column_array[@]}"; do
        
        col_name=$(echo "${column_array[$i]}" | cut -d: -f1)
        if [[ "$col_name" == "$condition_column" ]]; then
            condition_index=$((i + 1))
        fi
        
        if [[ ${update_dict[$col_name]+_} ]]; then
            update_indices+=("$((i + 1))")
            update_values+=("${update_dict[$col_name]}")
        fi

    done

    if [[ $condition_index -eq -1 ]]; then
        echo "Condition column $condition_column does not exist."
        return
    fi

    # Perform the update using a loop to handle each update
    match_found=false
    awk -F, -v OFS=, -v cond_col="$condition_index" -v cond_val="$condition_value" \
        -v update_cols="${update_indices[*]}" -v update_vals="${update_values[*]}" '
    BEGIN {
        split(update_cols, cols, " ")
        split(update_vals, vals, " ")
    }
    {
        if ($cond_col == cond_val) {
            match_found = 1
            for (i in cols) {
                $cols[i] = vals[i]
            }
        }
        print $0
    } END { if (match_found == 0) print "No matching rows found." }' "$table_name" > tmp

    mv tmp "$table_name"

    if ! grep -q "No matching rows found." "$table_name"; then
        echo "Rows matching '$condition' updated in '$table_name'."
    else
        echo "No matching rows found."
        sed -i '/No matching rows found./d' "$table_name"  # Remove the message from the file if no match
    fi

}

database_menu() {

    while true; do

        echo "Database Menu:"
        echo "1. Create Table"
        echo "2. List All Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select From Table"
        echo "6. Delete From Table"
        echo "7. Update From Table"
        echo "8. Disconnect (Return to Main Menu)"
        read -p "Choose an option (1-8): " db_choice

        case $db_choice in
            1) create_table ;;
            2) list_tables ;;
            3) drop_table ;;
            4) insert_into_table ;;
            5) select_from_table ;;
            6) delete_from_table ;;
            7) update_from_table ;;
            8) echo "Disconnecting from database..."; cd ..; break ;;
            *) echo "Invalid option, please try again." ;;
        esac

        echo
        
    done

}

while true; do

    echo "Main Menu:"
    echo "1. Create New Database"
    echo "2. List All Databases"
    echo "3. Connect to Database"
    echo "4. Drop Database"
    echo "5. Exit Program"
    read -p "Choose an option (1-5): " choice

    case $choice in
        1) create_database ;;
        2) list_databases ;;
        3) connect_to_database ;;
        4) drop_database ;;
        5) echo "Exiting program..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac

    echo

done
