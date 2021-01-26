#!/bin/bash

set -u
# SINGULARITY_IMAGE="singularity run shub://granek/crne_transposon:rstudio --app rstudio"
# SINGULARITY_DIR="$HOME/container_images"

SESSION_INFO_DIR="$HOME/.session_info"
mkdir -p $SESSION_INFO_DIR

# # SINGULARITY_IMAGE="shub://granek/mar1_rnaseq:rstudio"
# SINGULARITY_IMAGE="${1:-$SINGULARITY_DIR/mar1_rstudio.simg}"
# 
# # DATA_BASE_DIR="${DATA_BASE_DIR:-$HOME}"
# # WORKSPACE_BASE_DIR="${WORKSPACE_BASE_DIR:-$HOME}"
# 
# DATA="$DATA_BASE_DIR/hts2018/rawdata"
# WORKSPACE="$WORKSPACE_BASE_DIR/hts2018/workspace"
# 
#  
# if [ -d "${DATA}" ]; then
#     # BIND_ARGS="--bind ${DATA}:/data:ro"
#     BIND_ARGS="--bind ${DATA}:/data"
# else
#     echo "Make sure DATA exists: $DATA"
# fi
# 
# if [ -d "${WORKSPACE}" ]; then
#     BIND_ARGS="$BIND_ARGS --bind ${WORKSPACE}:/workspace"
# else
#     echo "Make sure WORKSPACE exists: $WORKSPACE"
# fi
# 
# mkdir -p $SINGULARITY_PULLFOLDER $SINGULARITY_CACHEDIR
#--------------------------------------------------------------------------------

# Look for an open port to use in range $LOWERPORT to $UPPERPORT
LOWERPORT=50000 
UPPERPORT=65535
for RSTUDIO_PORT in $(seq $LOWERPORT $UPPERPORT);
do
    # RSTUDIO_PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`"
    echo "Testing port: $RSTUDIO_PORT"
    ss -lpn | grep -q ":$RSTUDIO_PORT " || break
done

# SESSION_INFO_FILE="$SESSION_INFO_DIR/session_info_$(basename $SINGULARITY_IMAGE)_${RSTUDIO_PORT}.txt"
SESSION_INFO_FILE="$SESSION_INFO_DIR/session_info_port_${RSTUDIO_PORT}_`hostname | cut -f1 -d' '`.txt"
echo $SESSION_INFO_FILE
#export RSTUDIO_PASSWORD="`openssl rand -base64 16 | colrm 20`"
export RSTUDIO_PASSWORD

# Make $SESSION_INFO_FILE only readable by owner
rm -f $SESSION_INFO_FILE; touch $SESSION_INFO_FILE; chmod 600 $SESSION_INFO_FILE
grep IMAGE /.singularity.d/labels.json >> $SESSION_INFO_FILE
# jq  .IMAGE_VERSION /.singularity.d/labels.json
# jq  .IMAGE_NAME /.singularity.d/labels.json
printf "\n\nRStudio URL:\t\thttp://`hostname -A | cut -f1 -d' '`:${RSTUDIO_PORT}/\n" >> $SESSION_INFO_FILE
printf "\nRStudio Username:\t$USER\n"  >> $SESSION_INFO_FILE
printf "RStudio Password:\t$RSTUDIO_PASSWORD\n" >> $SESSION_INFO_FILE

cat $SESSION_INFO_FILE
export TMPDIR="$(mktemp -d)"
trap "{ rm -rf $SESSION_INFO_FILE $TMPDIR; }" EXIT


#singularity run  --app rstudio $BIND_ARGS $SINGULARITY_IMAGE 
# Setting '--auth-minimum-user-id $UID' to fix error "Unable to connect to service"
# by default RStudio gives this error when it is run by a user with UID less than 1000
# this hack sets the minimum to the UID of the current user!
# RSERVER_OPTIONS=" 
# RSERVER_OPTIONS="--auth-none 0 --auth-pam-helper rstudio_auth --www-port $RSTUDIO_PORT"

rserver --auth-none 0 \
	--auth-pam-helper-path rstudio_auth \
	--www-port 8787 \
	--auth-minimum-user-id "$UID" \
	--server-data-dir "${TMPDIR}" \
	--secure-cookie-key-file "${TMPDIR}/rstudio-server/secure-cookie-key"

	
#   exec rserver "${@}"

# rserver \
#   --auth-pam-helper-path "${RSTUDIO_AUTH}" \
#   --auth-encrypt-password 0 \
#   --rsession-path "${RSESSION_WRAPPER_FILE}" \
