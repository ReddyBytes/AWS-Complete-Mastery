# Stage 04b — EBS & EFS: Block and File Storage

> Persistent storage that stays alive after your EC2 instance stops — and shared storage for multiple instances.

## 1. EBS — Elastic Block Store

### Core Intuition

EBS is a network-attached "virtual hard drive" for your EC2 instance. It persists your data even when the instance stops — unlike instance store, which is ephemeral.

```
EC2 Instance (Your computer)
    │
    │ Network attachment (very fast, ~sub-ms latency)
    │
EBS Volume (Your hard drive, stored in AWS's storage systems)

Properties:
  ✅ Persists after instance stop/start
  ✅ Can take snapshots (point-in-time backups to S3)
  ✅ Can be detached and attached to another EC2 (same AZ!)
  ✅ Encryption at rest (KMS)
  ❌ One AZ only (cannot cross AZ boundaries directly)
  ❌ One instance at a time (except io2 multi-attach)
```

### EBS Volume Types

```
gp3 — General Purpose SSD (USE THIS DEFAULT)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IOPS: 3,000 baseline, up to 16,000 (configure independently!)
Throughput: 125 MB/s baseline, up to 1,000 MB/s
Price: ~$0.08/GB-month
Upgrade from gp2: same performance or better, ~20% cheaper
Best for: Root volumes, web servers, development, most databases
Console: Select "gp3" when adding storage to EC2

gp2 — General Purpose SSD (Legacy, use gp3 instead)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IOPS: 3 IOPS/GB (100-16,000), tied to volume size!
Price: ~$0.10/GB-month
Note: You can't configure IOPS independently — must resize volume to get more IOPS

io2 Block Express — Highest Performance SSD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IOPS: up to 256,000 IOPS
Latency: sub-millisecond, consistent
Multi-attach: yes (up to 16 instances in same AZ)
Price: $0.125/GB + $0.065 per provisioned IOPS
Best for: SAP HANA, Oracle DB, mission-critical, large I/O

st1 — Throughput Optimized HDD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Throughput: up to 500 MB/s
Price: ~$0.045/GB-month
Cannot be boot volume
Best for: Sequential data: log files, Kafka data, ETL, data warehousing
NOT for random access

sc1 — Cold HDD (cheapest)
━━━━━━━━━━━━━━━━━━━━━━━━━
Throughput: up to 250 MB/s
Price: ~$0.015/GB-month
Best for: Archive data, infrequently accessed cold data
```

### EBS Snapshots

```
Snapshot = Point-in-time backup of an EBS volume, stored in S3

Properties:
  ✅ Incremental: first snapshot is full, subsequent only changed blocks
  ✅ Stored durably in S3 (multi-AZ, 11 9s durability)
  ✅ Copy to another region (for DR or migration)
  ✅ Share with other AWS accounts
  ✅ Create AMI from snapshot
  ✅ Restore creates a new EBS volume (can be in any AZ!)

Console: EC2 → Volumes → Select Volume → Actions → Create snapshot

Snapshot pricing:
  $0.05 per GB-month stored (only changed blocks after first)
  10 GB volume with 1 GB changes/day:
    First snapshot: 10 GB
    Daily incremental: ~1 GB each
    After 30 days: ~10 + 30 = 40 GB stored

EBS Snapshot Archive:
  Move snapshots to archive tier: $0.0125/GB-month (75% cheaper)
  Restore takes 24-72 hours
  Use for: compliance archives, rarely needed recovery points
```

### Modifying EBS Volumes (Elastic Volumes)

```
You can modify gp3/io2 volumes WITHOUT stopping EC2:
  • Increase size (cannot decrease!)
  • Change volume type (gp2 → gp3)
  • Increase IOPS
  • Increase throughput

Console: EC2 → Volumes → Select → Modify

After modifying size: you must ALSO expand the filesystem inside EC2
  # Check current size
  lsblk

  # Extend filesystem (for Linux ext4)
  sudo resize2fs /dev/xvda1

  # Or for XFS (Amazon Linux default)
  sudo xfs_growfs -d /
```

## 2. EFS — Elastic File System

### Core Intuition

```
Problem EFS Solves:
  You have 10 EC2 instances in an Auto Scaling Group.
  All of them need to read/write the SAME shared files
  (user uploads, shared configs, media assets).

  EBS can only attach to ONE instance.
  Solution: EFS — a shared NFS filesystem all EC2s can mount.

EFS = Network-attached file system, like a NAS in the cloud
  Mount same EFS on ALL your EC2 instances simultaneously
  All see the same files
  Auto-scales: starts at 0 bytes, grows to petabytes automatically
```

### EFS vs EBS Comparison

```
                    EBS             EFS
Attach to:          1 EC2           Many EC2s simultaneously
Protocol:           Block (iSCSI)   NFS v4.1
AZ:                 One AZ          Multi-AZ (regional)
Scaling:            Manual (resize) Automatic
Pricing:            $0.08/GB-mo     $0.30/GB-mo (3.5x more expensive)
Performance:        Up to 16,000    Bursting up to 3 GB/s
                    IOPS (io2)      (scales with file system size)
Use case:           OS disk, DB     Shared content, web farms, ML
```

### EFS Performance Modes

```
General Purpose (default):
  Lowest latency (~1-3ms)
  Max 35,000 IOPS
  Best for: web servers, content management, home directories

Max I/O:
  Higher throughput but slightly higher latency (~6ms)
  Unlimited IOPS (scales to thousands of clients)
  Best for: big data, media processing, many parallel clients

Throughput Modes:
  Bursting: throughput scales with storage size
             50 MB/s/TB + burst to 100+ MB/s
  Provisioned: set specific throughput regardless of storage size
               Good when you need consistent high throughput
  Elastic (recommended): auto-scales throughput on demand
```

### EFS Storage Classes

```
Standard:          $0.30/GB-month   → Frequently accessed files
Standard-IA:       $0.025/GB-month  → Infrequently accessed (retrieval fee)
One Zone:          $0.16/GB-month   → Single AZ (lower cost, less HA)
One Zone-IA:       $0.0133/GB-month → Cheapest option

Lifecycle Policy: automatically move files to IA after 30/60/90/180 days
Console: EFS → File system → Storage classes → Lifecycle management
```

### EFS Console Walkthrough

```
Console: EFS → Create file system

Step 1: Name your file system
  Name: shared-web-content

Step 2: Network
  VPC: your VPC
  AZ and Subnets: select private subnets in each AZ
  Security group: efs-sg (allow NFS 2049 from EC2 security groups)

Step 3: Performance
  Performance mode: General Purpose (default)
  Throughput mode: Elastic (auto-scales)

Step 4: Storage
  Lifecycle management: Transition to IA after 30 days

After creation:
  Click "Attach" to get mount instructions:
  # On EC2 (Amazon Linux):
  sudo yum install -y amazon-efs-utils
  sudo mount -t efs -o tls fs-0abc123def456:/  /mnt/efs

  # In /etc/fstab for auto-mount on boot:
  fs-0abc123def456:/ /mnt/efs efs defaults,tls 0 0
```

## 3. Interview Perspective

**Q: What is the difference between EBS and EFS?**
EBS is block storage attached to a single EC2 instance in a single AZ. It provides high-performance storage for OS, databases, and application data. EFS is a shared NFS file system that can be mounted by many EC2 instances simultaneously across multiple AZs. Use EBS for single-instance workloads (most databases); EFS for shared content (web farms, shared configs, ML training data).

**Q: What is gp3 and why should you use it over gp2?**
gp3 is the latest generation general-purpose SSD. Unlike gp2 (where IOPS = 3 × volume size in GB), gp3 allows you to set IOPS and throughput independently from the volume size. gp3 is ~20% cheaper than gp2 for the same size and provides the same or better performance. There's no reason to use gp2 for new volumes.

**Q: Can you attach an EBS volume to multiple EC2 instances?**
Standard EBS (gp3, gp2, st1, sc1) can only attach to one instance at a time. The exception is io2 Block Express volumes with the "Multi-Attach" feature, which can attach to up to 16 instances in the same AZ simultaneously. This requires a cluster-aware file system (not standard ext4/XFS).

**Back to root** → [../README.md](../README.md)
