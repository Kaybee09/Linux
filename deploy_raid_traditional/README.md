# Native Linux RAID1 with a Hot Spare (mdadm)

Links: [AlmaLinux / RHEL](https://almalinux.org) | [Ubuntu / Debian](https://ubuntu.com) | [mdadm docs](https://raid.wiki.kernel.org/index.php/Linux_Raid)

A host-level storage project using `mdadm` to build a mirrored (RAID1) array with a dedicated hot spare, then testing that it actually survives a disk failure.

## Table of Contents

- [Architecture](#architecture)
- [Environment](#environment)
- [What the script does](#what-the-script-does)
- [Testing a failure](#testing-a-failure)
- [Skills demonstrated](#skills-demonstrated)
- [Full write-up](#full-write-up)

---

## Architecture

```mermaid
graph TD
    PV1[Raw Disk /dev/sdb] --> MD0[RAID1 Array /dev/md0]
    PV2[Raw Disk /dev/sdc] --> MD0
    PV3[Hot Spare /dev/sda] -.->|Auto Failover & Sync| MD0
    MD0 -->|Formatted XFS Filesystem| MountPath[/mnt/secure_vault]
```

`/dev/sdb` and `/dev/sdc` are the active mirror. `/dev/sda` sits idle as the hot spare until a mirror disk fails, at which point the kernel promotes it automatically. A fourth disk, `/dev/sdd`, is present on the host but isn't part of this array.

---

## Environment

- OS: AlmaLinux or Ubuntu
- Disks: `/dev/sda`, `/dev/sdb`, `/dev/sdc` (raw, used by the array)
- Filesystem: XFS
- Tooling: `mdadm`

---

## What the script does

`deploy_raid.sh` runs through the setup end to end:

1. Installs `mdadm` and `xfsprogs`.
2. Wipes `/dev/sdb`, `/dev/sdc`, and `/dev/sda`, then creates `/dev/md0` as a RAID1 array with `sdb`/`sdc` active and `sda` as spare.
3. Formats `/dev/md0` with XFS, mounts it at `/mnt/secure_vault`, and writes the config into `/etc/fstab` and `/etc/mdadm.conf` so it survives a reboot.
4. Prints the array state and confirms the test file is readable.

```bash
sudo ./deploy_raid.sh
```

---

## Testing a failure

Fail one of the active mirror disks and watch the spare take over:

```bash
mdadm --manage /dev/md0 --fail /dev/sdc
cat /proc/mdstat
```

The filesystem stays mounted and readable the whole time. Once the failed disk is dealt with, drop it and re-add it — it rejoins as the new spare:

```bash
mdadm --manage /dev/md0 --remove /dev/sdc
mdadm --manage /dev/md0 --add /dev/sdc
mdadm --detail /dev/md0
```

---

## Skills demonstrated

- Linux storage administration
- `mdadm` software RAID (RAID1, hot spares)
- XFS filesystems
- `/etc/fstab` and `/etc/mdadm.conf` persistence
- Fault injection and recovery testing

---

## Full write-up

📝 [Read the full breakdown on my blog](https://kaybeelog.com)
