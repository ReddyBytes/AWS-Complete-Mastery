# Linux — Disk Management

> Disk issues are the most common production emergency. A full disk brings down any service. Know how to check, manage, and expand storage before it happens to you.

---

## 1. The Analogy — Filing Cabinets in an Office

Your server's disk is like a row of filing cabinets:

- The **physical disk** is the cabinet
- **Partitions** are drawers — divide the cabinet into sections
- **Filesystems** are the filing system inside each drawer (alphabetical, numerical...)
- **Mounting** is opening a drawer and making it accessible at a location
- **df** shows how full each drawer is
- **du** shows which files are taking up the most space

---

## 2. Checking Disk Space

```bash
# Disk space on all mounted filesystems
df -h

# Output:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1        50G   18G   32G  36% /
# /dev/sdb1       100G   45G   55G  45% /data
# tmpfs           1.9G     0  1.9G   0% /dev/shm

# Show only real disks (no tmpfs/overlay)
df -h --exclude-type=tmpfs --exclude-type=devtmpfs

# Check inode usage (running out of inodes = can't create files)
df -i
```

**Critical:** At 90%+ disk usage, many applications start failing silently. At 100%, everything breaks.

---

## 3. Finding What's Using Disk Space

```bash
# Size of a directory
du -sh /var/log/

# Size of all items in a directory
du -sh /var/log/*

# Find the top 10 largest directories in /
du -sh /* 2>/dev/null | sort -rh | head -10

# Find the top 10 largest files on the whole system (slow on large disks)
find / -type f -printf '%s %p\n' 2>/dev/null | sort -rn | head -10

# Find large log files
find /var/log -name "*.log" -size +100M

# Find files larger than 1GB
find / -size +1G -type f 2>/dev/null

# Quickly see what's biggest in the current directory
du -sh * | sort -rh | head -20
```

---

## 4. Listing Disks and Partitions

```bash
# List all block devices (disks and partitions)
lsblk

# Output:
# NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda       8:0    0   50G  0 disk
# ├─sda1    8:1    0   49G  0 part /
# └─sda2    8:2    0    1G  0 part [SWAP]
# sdb       8:16   0  100G  0 disk
# └─sdb1    8:17   0  100G  0 part /data

# Show partition table
sudo fdisk -l /dev/sda
sudo parted /dev/sda print

# Show all disks with model and size
sudo fdisk -l | grep "Disk /dev"

# Show mounted filesystems
mount | grep -v tmpfs
cat /proc/mounts
```

---

## 5. Adding a New Disk (AWS EBS Volume Example)

When you add a new EBS volume to an EC2 instance, it appears as `/dev/xvdf` or `/dev/nvme1n1` — a raw disk with no filesystem.

```bash
# Step 1: See the new disk
lsblk
# Should see: xvdf  202:80  0  20G  0 disk

# Step 2: Create a filesystem on it
sudo mkfs.ext4 /dev/xvdf       # format as ext4
# or for XFS (better for large files):
sudo mkfs.xfs /dev/xvdf

# Step 3: Create a mount point
sudo mkdir -p /data

# Step 4: Mount it
sudo mount /dev/xvdf /data

# Step 5: Verify
df -h /data

# Step 6: Make it persist across reboots (/etc/fstab)
# Get the UUID (more reliable than /dev/xvdf which can change)
sudo blkid /dev/xvdf
# UUID="a1b2c3d4-..." TYPE="ext4"

sudo nano /etc/fstab
# Add this line:
UUID=a1b2c3d4-...  /data  ext4  defaults,nofail  0  2
# 'nofail' means system still boots even if this disk is missing

# Test the fstab entry (without rebooting)
sudo mount -a
```

---

## 6. Mounting and Unmounting

```bash
# Mount a disk/partition
sudo mount /dev/sdb1 /mnt/external

# Mount with specific options
sudo mount -o ro /dev/sdb1 /mnt/backup       # read-only
sudo mount -o remount,rw /mnt/backup         # remount as read-write

# Mount a USB drive
sudo mount /dev/sdc1 /mnt/usb

# Unmount (the device must not be in use)
sudo umount /mnt/external

# If "device is busy":
lsof /mnt/external           # who has files open?
sudo fuser -v /mnt/external  # what processes are using it?
cd ~                          # leave the mount point first
sudo umount /mnt/external

# Show all mounts
mount
findmnt                      # cleaner tree view
```

---

## 7. Expanding Disk Space on AWS

**Scenario:** Your EC2 root volume is 90% full. You expanded the EBS volume from 20GB to 40GB in the AWS Console. Now tell Linux.

```bash
# Step 1: Check current state (disk shows 40GB, partition shows 20GB)
lsblk
# xvda    202:0   0   40G  0 disk
# └─xvda1 202:1   0   20G  0 part /   ← still old size!

# Step 2: Expand the partition to use all disk space
sudo growpart /dev/xvda 1      # install: sudo apt install cloud-utils

# Step 3: Expand the filesystem
sudo resize2fs /dev/xvda1      # for ext4
# or for XFS:
sudo xfs_growfs /               # for XFS (Amazon Linux default)

# Step 4: Verify
df -h /
# Now shows 40GB
```

---

## 8. Swap Space

Swap is disk space used as overflow when RAM is full. Slow, but prevents crashes.

```bash
# Check current swap
free -h
swapon --show

# Create a swap file (if no swap partition)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make swap permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Check swap usage
vmstat 1          # si/so columns = swap in/out
```

---

## 9. Emergency: Disk Full — What To Do

```bash
# Step 1: Confirm disk is full
df -h

# Step 2: Find what's taking space
du -sh /* 2>/dev/null | sort -rh | head -10

# Step 3: Common culprits:
du -sh /var/log/*        # old logs
du -sh /tmp/*            # temp files
du -sh /var/cache/apt/*  # apt package cache

# Step 4: Quick wins:
# Clear apt cache
sudo apt clean            # removes all cached .deb files
sudo apt autoremove -y    # remove unused packages

# Clear old journal logs
sudo journalctl --vacuum-size=100M

# Clear temp files
sudo rm -rf /tmp/*

# Clear old logs
sudo find /var/log -name "*.gz" -delete
sudo find /var/log -name "*.1" -delete

# Step 5: Check for deleted files still held open
lsof | grep deleted | sort -k7 -rn | head    # col 7 = file size

# If a large deleted log file is still held open by nginx:
sudo systemctl restart nginx    # closes the file handle, frees space immediately
```

---

## 10. Summary

```
Checking space:
  df -h               disk usage on all filesystems
  df -i               inode usage
  du -sh dir/         size of directory
  du -sh /* | sort -rh   find biggest directories

Disk info:
  lsblk               list disks and partitions
  sudo fdisk -l       partition tables
  blkid               UUIDs and filesystem types

Adding/mounting:
  sudo mkfs.ext4 /dev/xvdf   format disk
  sudo mount /dev/xvdf /data  mount
  /etc/fstab                  persistent mounts

Emergency (disk full):
  sudo apt clean
  sudo journalctl --vacuum-size=100M
  lsof | grep deleted          find held-open deleted files

Expanding EBS on AWS:
  sudo growpart /dev/xvda 1
  sudo resize2fs /dev/xvda1
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Logs and journalctl](./logs_and_journalctl.md) &nbsp;|&nbsp; **Next:** [Linux Interview Questions →](../99_interview_master/linux_questions.md)

**Related Topics:** [systemd Services](./systemd_services.md) · [Logs and journalctl](./logs_and_journalctl.md)
