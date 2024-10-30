#!/bin/bash

NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"

# Function to list all available sites and show if they are enabled
list_sites() {
    echo "Available Sites:"
    printf "%-30s %-10s\n" "Site Name" "Enabled"
    echo "----------------------------------------------"
    for site in "$NGINX_AVAILABLE"/*; do
        site_name=$(basename "$site")
        if [ -L "$NGINX_ENABLED/$site_name" ]; then
            enabled_status="Yes"
        else
            enabled_status="No"
        fi
        printf "%-30s %-10s\n" "$site_name" "$enabled_status"
    done
}

# Function to enable a site
enable_site() {
    local site_name="$1"
    if [ ! -f "$NGINX_AVAILABLE/$site_name" ]; then
        echo "Site $site_name does not exist in $NGINX_AVAILABLE"
        exit 1
    fi

    if [ -L "$NGINX_ENABLED/$site_name" ]; then
        echo "Site $site_name is already enabled."
    else
        ln -s "$NGINX_AVAILABLE/$site_name" "$NGINX_ENABLED/$site_name"
        echo "Site $site_name enabled."
    fi

    # Reload NGINX to apply changes
    sudo systemctl reload nginx
}

# Function to disable a site
disable_site() {
    local site_name="$1"
    if [ ! -L "$NGINX_ENABLED/$site_name" ]; then
        echo "Site $site_name is not enabled."
    else
        rm "$NGINX_ENABLED/$site_name"
        echo "Site $site_name disabled."
    fi

    # Reload NGINX to apply changes
    sudo systemctl reload nginx
}

# Function to change server_name and/or port
change_site() {
    local site_name="$1"
    local option="$2"
    local value="$3"

    if [ ! -f "$NGINX_AVAILABLE/$site_name" ]; then
        echo "Site $site_name does not exist."
        exit 1
    fi

    # Parse the option and perform the relevant change
    case "$option" in
        --name)
            # Change the server_name
            sudo sed -i "s/server_name .*/server_name $value;/g" "$NGINX_AVAILABLE/$site_name"
            echo "Updated server_name to $value."
            ;;
        --port)
            # Change the port
            sudo sed -i "s/listen [0-9]*/listen $value/g" "$NGINX_AVAILABLE/$site_name"
            echo "Updated listen port to $value."
            ;;
        *)
            echo "Invalid option. Use --name or --port."
            exit 1
            ;;
    esac

    # Reload NGINX to apply changes
    sudo systemctl reload nginx
}

# Help function
usage() {
    echo "Usage: $0 {list|enable|disable|change} site_name [--name new_server_name] [--port new_port]"
    echo
    echo "Commands:"
    echo "  list                    List all available NGINX sites and their status (enabled/disabled)."
    echo "  enable site_name         Enable the specified NGINX site."
    echo "  disable site_name        Disable the specified NGINX site."
    echo "  change site_name --name new_server_name  Change the server_name of an existing site."
    echo "  change site_name --port new_port         Change the port of an existing site."
    echo
    exit 1
}

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Main logic
case "$1" in
    list)
        list_sites
        ;;
    enable)
        if [ -z "$2" ]; then
            usage
        fi
        enable_site "$2"
        ;;
    disable)
        if [ -z "$2" ]; then
            usage
        fi
        disable_site "$2"
        ;;
    change)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            usage
        fi
        change_site "$2" "$3" "$4"
        ;;
    *)
        usage
        ;;
esac
