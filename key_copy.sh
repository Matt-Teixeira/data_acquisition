scp -3 avante-debian:/home/matt-teixeira/.ssh/mmb_google_deb \
    staging-db:/home/mattteixeira/.ssh/mmb_google_deb


scp -3 avante-debian:/home/matt-teixeira/.ssh/mmb_google_deb.pub \
    staging-db:/home/mattteixeira/.ssh/mmb_google_deb.pub

## Works now: Need To Create Configs
ssh -i ~/.ssh/mmb_google_deb avante@172.31.3.51

Host SME15805
    HostName 172.31.3.51
    User avante
    IdentityFile ~/.ssh/mmb_google_deb
    IdentitiesOnly yes


## Process To Create Volume For SSH Keys/Copnfigs

# This directory becomes the “portable .ssh” that every app_tools container will see.
mkdir -p /home/user_name/docker_ssh_bundle

cp ~/.ssh/mmb_google_deb        /opt/resources/ssh_bundles/data_acquisition
cp ~/.ssh/mmb_google_deb.pub    /opt/resources/ssh_bundles/data_acquisition
cp ~/.ssh/config                /opt/resources/ssh_bundles/data_acquisition   # if you use it
cp ~/.ssh/known_hosts           /opt/resources/ssh_bundles/data_acquisition   # if you want to pre-trust hosts

chmod 700 /opt/resources/ssh_bundles/data_acquisition
chmod 600 /opt/resources/ssh_bundles/data_acquisition/*

# Then in your .env (same one used by compose), add:
SSH_BUNDLE_DIR=/opt/resources/ssh_bundles/data_acquisition

# Update docker-compose.yml to mount this into the container

x-common-mounts: &common_mounts
  working_dir: /workspace
  volumes:
    # 1) Project source → live edit on host reflects in container
    - ./:/workspace

    # 2) Cache node_modules on host (survives container removal)
    - ${NODE_MOD_CACHE_DEV}:/workspace/node_modules

    # 3) Centralized run logs on host (ensure directory exists/writable - .env)
    - ${RUN_LOGS_DIR}

    # 4) Read-only SSH bundle (keys, config, known_hosts) for passwordless SSH
    - ${SSH_BUNDLE_DIR}:/ssh:ro



##  GIVe PERMISSIONS
# Give secDev ownership of the container
sudo chown -R 999:995 /opt/resources/ssh_bundles/data_acquisition

# Leave ownership as svc-dev:docker for container compatibility, and then give yourself full rights:
~ sudo setfacl -R -m u:mattteixeira:rwx /opt/resources/ssh_bundles/data_acquisition







