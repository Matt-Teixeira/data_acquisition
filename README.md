# Data Acquisition App — Implementation Guide

This document describes how to clone, configure, and run the **`hhm_data_acquisition`** application using Docker.  
It also explains the role of the runtime image (`Dockerfile.runtime`), compose services, permissions setup, and workflow.

---

## 🧩 Repository Setup

### 1. Clone Required Repositories
```bash
# Main data acquisition app
git clone git@github.com:Matt-Teixeira/hhm_data_acquisition.git

# Shared utilities repo
git clone git@github.com:AvanteHS-RTT/utils.git
```

### 2. Configure Git
```bash
git config --global user.email "matt.teixeira@avantehs.com"
git config --global user.name "Matt Teixeira"
```

---

## ⚙️ Environment Configuration

### 3. Update `.env`
Ensure your `.env` file contains all required variables (not displayed here).

### 4. Update `pgPool.js`
Integrate the updated pool configuration with the `PROD_staging-docker` branch.

### 5. Update Credentials
Run the credentials update script using the legacy Node 16 image (for encryption/decryption compatibility):
```bash
./run_scripts/update_db_creds.sh
```

This script uses `node:16.20.2` to ensure compatibility with existing encryption methods.

---

## 🧱 Permissions & Directory Setup

### 6. Adjust File Ownership
From the app root:
```bash
chgrp -R docker .
```

### 7. Create the `files` Directory
```bash
mkdir files
```

### 8. Make the Directory Writable
Ensure both your host user and service user (`svc-dev`) can modify files:
```bash
sudo chmod -R g+rwX /home/mattteixeira/app/hhm_data_acquisition/files
sudo chgrp -R docker .
```

> **Tip:** To make new files always group-writable and inherit the `docker` group:
> ```bash
> sudo find /home/mattteixeira/app/hhm_data_acquisition/files -type d -exec chmod 2775 {} +
> sudo setfacl -R -m g:docker:rwx -m d:g:docker:rwx /home/mattteixeira/app/hhm_data_acquisition/files
> ```

---

## 🚀 Runtime and Job Execution

### Docker Compose Overview

`app_tools` builds from `docker/Dockerfile.runtime`, which extends `node:lts` and pre-installs system packages (e.g., `rsync`, `lftp`) used for data jobs.

---

### 🔧 Build the Runtime Image
```bash
docker compose build app_tools
```

### 🏃 Run a Data Job

**Production (without dev dependencies):**
```bash
docker compose run --rm app_tools bash -lc "npm run job_name"
```

**Development (with fresh install):**
```bash
docker compose run --rm app_tools bash -lc "npm ci --omit=dev && npm run job_name"
```

#### Explanation

| Component | Description |
|------------|-------------|
| `--rm` | Automatically removes the container after it exits. |
| `app_tools` | The service name in `docker-compose.yaml` defining image, mounts, env, etc. |
| `bash -lc` | Runs a login shell (`-l`) and executes the command (`-c`) ensuring PATH and env setup. |
| `npm ci` | Performs a clean, reproducible install from `package-lock.json`. |
| `--omit=dev` | Skips development dependencies. |
| `npm run job_name` | Executes the job script defined in `package.json`. |

---

## 🗂️ Volumes and Caching

| Purpose | Host Path → Container Path | Notes |
|----------|----------------------------|-------|
| Project Source | `./:/workspace` | Live edit on host reflects in container. |
| Node Modules Cache (DEV) | `/opt/resources/node_mod_cache/dev/data_acquisition:/workspace/node_modules` | Cache survives container removal. |
| Node Modules Cache (STAGING/PROD) | `/opt/resources/node_mod_cache/staging/data_acquisition:/workspace/node_modules` | Update path per environment. |
| Run Logs | `/opt/run-logs/data_acquisition:/opt/run-logs/data_acquisition` | Centralized logging on host. Ensure directory exists and is writable. |

---

## 🧾 TODO

### Logging Path Improvements
Update **utils/logger** path handling to dynamically adjust for Docker vs non-Docker environments.

| Environment | Example Path |
|--------------|--------------|
| **Non-Docker (Local)** | `./utils/logger/${process.env.APP_NAME}-log.${process.env.LOGGER}.${run_id}.js` |
| **Docker - Local** | `./utils/logger/${process.env.APP_NAME}-log.${process.env.LOGGER}.${run_id}.js` |
| **Docker - Live** | `/opt/run-logs/${process.env.APP_NAME}/${process.env.APP_NAME}-log.${process.env.LOGGER}.${run_id}.js` |

---

## 🧠 Notes

- Jobs currently execute via shell scripts (`run_scripts/`), which pull a fresh `node:lts` image and install dependencies (`rsync`, `lftp`) as needed.
- The `Dockerfile.runtime` allows all required tools to be **baked once**, minimizing cold-start times.
- All containers use the **docker group (GID 995)** for file and log access, ensuring shared write/delete permissions between users (`svc-dev`, `mattteixeira`).

---

**Author:**  
_Matt Teixeira_  
Avante Health Solutions – RTT Team  
matt.teixeira@avantehs.com
