## You run:
```sh
docker compose run --rm app_tools bash -lc "npm run <job_name>"
```
# EntryPoint:
- Copies bundle → /home/svcDev/.ssh

## SSH connects to MMB
- If it’s new, it prompts:
    Are you sure you want to continue connecting (yes/no/[fingerprint])?
- You type yes.
- SSH appends the host key to /home/svcDev/.ssh/known_hosts.

## When the command exits, entrypoint:
- Copies /home/svcDev/.ssh/known_hosts → /opt/ssh_bundles/data_acquisition/known_hosts

## Next run:
- That updated known_hosts is copied in.
- MMB/SMExxxxx is already trusted → no more prompt.
- And the bundle on the host stays your single source of truth.

## MAKE FILE WRITABLE
chmod 660 /opt/resources/ssh_bundles/data_acquisition/known_hosts
chmod 640 /opt/resources/ssh_bundles/data_acquisition/config