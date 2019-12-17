#!/bin/bash

set -e

show_help() {
echo """
Commands

dev          : Start Flask development server
prod         : Start uswgi & nginx server
recreate-db  : Recreate the database
shell        : Start Bash shell
help         : Show this message
"""
}

case "$1" in
    dev)
        flask run --host=0.0.0.0
    ;;
    prod)
        /usr/bin/supervisord
    ;;
    recreate-db)
        flask recreate-db
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
