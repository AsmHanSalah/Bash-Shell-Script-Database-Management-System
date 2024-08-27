#!/bin/bash

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

while true; do

    echo "Main Menu:"
    echo "1. Create New Database"
    echo "2. List All Databases"
    echo "3. Exit Program"
    read -p "Choose an option (1-3): " choice

    case $choice in
        1) create_database ;;
        2) list_databases ;;
        3) echo "Exiting program..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac

    echo

done
