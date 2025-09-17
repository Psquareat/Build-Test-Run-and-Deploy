#!/bin/bash

#strict mode: exit on errors, undefined vars, pipeline errors
set -euo pipefail  

# ===== FUNCTIONS ===== 

log () {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_permissions() {
	local file=$1
	local perm_sym
	perm_sym=$(stat -c "%A" "$file")

	local owner=${perm_sym:1:2}
	local group=${perm_sym:4:3}
	local others=${perm_sym:7:3}

	if [[ "$owner" != *"r"* || "$owner" != *"w"* ]]; then
		log "SECURITY WARNING: $file owner missing read/write"
		return 1
	elif [[ "$group" != "---" || "$others" != "---" ]]; then
		log "SECURITY WARNING: $file group/others have access"
		return 1
	else
		log "Permissions for $file are fully secure"
		return 0
	fi
}

	deploy_files() { 
		local files=("$@")
		local	dest="/tmp/devsecops_deploy"
		mkdir -p "$dest"
		cp -p "${files[@]}" "$dest"
		log "Files deployed to $dest"
	}


# ===== PIPELINE ===== 
log "Starting DevSecOps pipeline..."

# Stage 1: Syntax check for lab.sh
bash -n lab.sh || { log "Syntax error found! Exiting."; exit 1; }


# Stage 2: Test
log "Stage 2: Running lab.sh"
./lab.sh


# Stage 3: Security
log "Stage 3: Security Check"
check_permissions secret.txt || { log "Security check failed! Exiting."; exit 1; }

# Stage 4: Deploy
log "Stage 4: Deploying files"
deploy_files lab.sh secret.txt

log "Pipeline completed successfully!"


