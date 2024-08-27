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
        echo "Database menu not implemented yet."
    else
        echo "Database '$db_name' does not exist."
    fi

}

while true; do

    echo "Main Menu:"
    echo "1. Create New Database"
    echo "2. List All Databases"
    echo "3. Connect to Database"
    echo "4. Exit Program"
    read -p "Choose an option (1-4): " choice

    case $choice in
        1) create_database ;;
        2) list_databases ;;
        3) connect_to_database ;;
        4) echo "Exiting program..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac

    echo

done
