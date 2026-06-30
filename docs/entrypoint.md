# Entrypoint

## What it is now

The entrypoint is **baked into the image** from the tracked [`docker/entrypoint.sh`](../docker/entrypoint.sh)
(`COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh` in [`docker/Dockerfile`](../docker/Dockerfile)).
It does exactly one thing — drop privileges to `RUN_USER` and exec your command:

```bash
#!/bin/bash
set -e
RUN_USER="${RUN_USER:-svc}"     # default to the svc service account
export HOME="/home/$RUN_USER"   # so npm/ssh write under the right home
exec gosu "$RUN_USER" "$@"      # run the command as that user
```

> **Deprecated:** the old global `/opt/resources/entrypoint.sh` is no longer mounted or
> used. The script above is committed in this repo and baked at build time.

## You run

```sh
docker compose run --rm app_tools bash -lc "npm run <job_name>"
```

The container starts as root, the entrypoint drops to `RUN_USER` (default `svc`), and your
`npm run <job>` executes as that user with `HOME=/home/<RUN_USER>`.

## SSH to MMB / remote hosts

SSH material comes from the **shared, read-only** bundle mounted at `/opt/resources/ssh/`:

```
/opt/resources/ssh/
├── config        # ssh client config
├── id_dev        # private key (path referenced by the .env SSH_KEY var)
├── known_hosts   # accumulated host keys
└── known_hosts.bak
```

Compose mounts it `- /opt/resources/ssh:/opt/resources/ssh:ro` and `.env` sets `SSH_KEY`
to the key inside it (used by `rsync_mmb.sh`). Because the mount is **read-only**, the
entrypoint does **not** copy the bundle into `~/.ssh` and does **not** write
`known_hosts` back out on exit — host keys are managed on the host directly.

To add/refresh a host key (run on the host, not in the container):

```bash
# known_hosts is group-writable (660, group docker) so it can be appended to
ssh-keyscan -H <remote_host> >> /opt/resources/ssh/known_hosts
```

## Permissions (host side)

```bash
sudo chgrp -R docker /opt/resources/ssh
chmod 640 /opt/resources/ssh/config
chmod 600 /opt/resources/ssh/id_dev          # private key: owner-only
chmod 660 /opt/resources/ssh/known_hosts     # group-writable to append host keys
```

> **History:** an earlier design used per-app `/opt/resources/ssh_bundles/<app>/` bundles
> that the entrypoint copied into `~/.ssh` and synced `known_hosts` back out of. That is
> no longer how it works — the current system uses the single flat read-only
> `/opt/resources/ssh/` bundle above and a gosu-only entrypoint.
