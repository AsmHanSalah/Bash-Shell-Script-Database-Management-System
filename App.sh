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

while true; do

    echo "Main Menu:"
    echo "1. Create New Database"
    echo "2. List All Databases"
    echo "3. Exit Program"
    read -p "Choose an option (1-3): " choice

    case $choice in
        1) create_database ;;
        2) echo "Function not implemented yet." ;;
        3) echo "Exiting program..."; exit 0 ;;
        *) echo "Invalid option, please try again." ;;
    esac

    echo

done
