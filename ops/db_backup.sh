#!/bin/bash

set -e

set -o allexport
source ../${ENV}_secrets.env
set +o allexport

LOG_TIMESTAMP=`date +'%Y_%m_%d_%H_%M_%S'`

PGPASSWORD=${POSTGRES_PASSWORD} pg_dump --create --username=${POSTGRES_USER} --host=localhost --port=${POSTGRES_PORT} --file=${HOME}/backups/climbicusdb_stag_local_${LOG_TIMESTAMP}_dump.sql

