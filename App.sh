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

database_menu() {

    while true; do

        echo "Database Menu:"
        echo "1. Create Table"
        echo "2. List All Tables"
        echo "3. Disconnect (Return to Main Menu)"
        read -p "Choose an option (1-3): " db_choice

        case $db_choice in
            1) create_table ;;
            2) list_tables ;;
            3) echo "Disconnecting from database..."; cd ..; break ;;
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
