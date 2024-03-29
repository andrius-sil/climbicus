#!/bin/bash

set -e

show_help() {
echo """
Commands

dev-server   : Start Flask development server
main-server  : Start uwsgi & nginx server
recreate-db  : Recreate the database
create-user  : Create new user with provided credentials
create-gym   : Create new gym
routes       : List all Flask endpoints
shell        : Start Bash shell
help         : Show this message
"""
}

case "$1" in
    dev-server)
        flask run --host=0.0.0.0
    ;;
    main-server)
        /usr/bin/supervisord
    ;;
    recreate-db)
        shift;
        flask recreate-db "$@"
    ;;
    create-user)
        shift;
        flask create-user "$@"
    ;;
    create-gym)
        shift;
        flask create-gym "$@"
    ;;
    routes)
        flask routes
    ;;
    shell)
        /bin/bash
    ;;
    help)
        show_help
    ;;
    *)
        exec "$@"
    ;;
esac
