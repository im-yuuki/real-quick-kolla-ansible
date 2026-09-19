# Runbook: Dựng Ceph cho OpenStack (cụm 3 node Ubuntu 24.04 mới)

> Mục tiêu: Ceph 3-node (3 MON + 3 MGR + 3 OSD) dùng làm backend cho
> Glance/Cinder/Nova qua Kolla-Ansible.
> Đúc kết từ lần dựng thực tế trước (gồm mọi lỗi đã gặp và cách fix).

---

## 0. Quy tắc chọn version Ceph — ĐỌC TRƯỚC, quyết định mọi thứ còn lại

Client RBD nằm **trong image Kolla** (không phải OS host). Kiểm tra version client
trong image đang dùng:

```sh
sudo docker run --rm quay.io/openstack.kolla/glance-api:<tag> dpkg -l librados2
# hoặc: .../nova-compute, cinder-volume — cùng 1 version
```

**Quy tắc: Ceph cluster CHỈ được hơn client tối đa 1 đời** (cơ chế rolling-upgrade
của Ceph chỉ đảm bảo N ↔ N+1). Nhảy 2 đời = auth gãy (`handle_auth_bad_method`,
`RADOS I/O error`) dù key/caps/mạng đúng hết — đã kiểm chứng thực tế
(Reef 18 → Tentacle 20 gãy; Reef → Squid OK theo thiết kế).

| Client trong image Kolla | Cluster nên dựng | Ghi chú |
|---|---|---|
| Debian trixie (Reef 18.2.x) | **Squid 19.2.x** | Cặp đã verify. Tránh Tentacle |
| Ubuntu Noble (Squid 19.2.x) | Squid 19.2.x (khớp đời) hoặc Tentacle 20.2.x | Ưu tiên khớp đời |
| Rocky/EL (Squid hoặc Tentacle, xem matrix Kolla) | Khớp đúng đời client | — |

> Squid EOL 09/2026 — chấp nhận được cho lab. Khi image Kolla lên client mới,
> upgrade cluster rolling (`ceph orch upgrade`) không mất data, key giữ nguyên.

Bản runbook này dùng **Squid 19.2.6** (mới nhất dòng 19.x tại thời điểm viết).

---

## 1. Chuẩn bị 3 host (lặp lại trên từng node)

Điền bảng địa chỉ trước:

| Node | SSH/mgmt IP | Internal IP (eth0) | Ổ OSD |
|---|---|---|---|
| openstack-node1 | `<NODE1_MGMT>` | `<NODE1_INT>` (vd 100.64.30.11/24) | `/dev/sdb` 1TB |
| openstack-node2 | `<NODE2_MGMT>` | `<NODE2_INT>` | `/dev/sdb` 1TB |
| openstack-node3 | `<NODE3_MGMT>` | `<NODE3_INT>` | `/dev/sdb` 1TB |

```sh
ssh <user>@<NODE_MGMT>

# 1.1 User deploy sudo không mật khẩu (cephadm --ssh-user cần)
sudo sh -c 'echo "<user> ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/<user> \
  && chmod 440 /etc/sudoers.d/<user> && visudo -c'

# 1.2 Ổ OSD trống, chưa mount, chưa partition
lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT   # sdb 1T, MOUNTPOINT trống

# 1.3 Đồng hồ (Ceph + DB rất nhạy clock skew — KHUYẾN NGHỊ làm, lần trước bỏ qua)
sudo apt update && sudo apt install -y chrony
sudo systemctl enable --now chrony
timedatectl status | grep synchronized  # phải ra "synchronized: yes"

# 1.4 Container engine + gói cephadm cần (Kolla đã cần docker sẵn)
sudo apt install -y lvm2          # BẮT BUỘC cho OSD
python3 --version                 # cần >= 3.6
docker --version                  # cephadm dùng docker có sẵn, khỏi podman

# 1.5 Ra internet (pull image quay.io + download.ceph.com)
curl -sI --max-time 10 https://quay.io | head -1
```

---

## 2. Lấy binary cephadm (PIN version — đừng dùng link chung)

> `https://download.ceph.com/cephadm` đã **404**. Mẫu đúng:
> `https://download.ceph.com/rpm-<VERSION>/el9/noarch/cephadm`

Trên **node1**:

```sh
CEPH_VER=19.2.6
curl -sL --max-time 180 https://download.ceph.com/rpm-${CEPH_VER}/el9/noarch/cephadm \
  -o /tmp/cephadm-squid
chmod +x /tmp/cephadm-squid
sudo /tmp/cephadm-squid version   # expect: 19.2.6 ... squid (stable)
```

---

## 3. Bootstrap cluster (node1)

```sh
# Mật khẩu dashboard: sinh 1 lần, lưu file
openssl rand -base64 -out ~/ceph-dashboard-pass.txt 16
chmod 600 ~/ceph-dashboard-pass.txt
DASH_PASS=$(cat ~/ceph-dashboard-pass.txt)

sudo /tmp/cephadm-squid bootstrap \
  --mon-ip <NODE1_INT> \
  --cluster-network <INT_CIDR> \          # vd 100.64.30.0/24 (public+replication chung vì hết NIC)
  --ssh-user <user> \
  --initial-dashboard-user admin \
  --initial-dashboard-password "$DASH_PASS" \
  --dashboard-password-noupdate
# mất 5-15 phút (pull image). Xong kiểm tra:
sudo /tmp/cephadm-squid shell -- ceph -s
# expect: 1 mon quorum, 1 mgr active, HEALTH_WARN (0 OSD) là bình thường
```

Ghi lại **FSID** in ra (`Cluster fsid: ...`) — mọi lệnh `shell` sau này nên kèm
`--fsid <FSID>` nếu máy từng có cluster cũ (tránh nhầm).

Dashboard: `https://<NODE1_INT>:8443` (admin + file trên).

---

## 4. Thêm node2/node3, scale MON/MGR, hạ RAM cho cụm converged

```sh
# 4.1 Phân phối SSH key cephadm tự sinh sang 2 node còn lại (chạy từ máy deploy)
sudo ceph cephadm get-pub-key > ~/ceph.pub   # trên node1 (hoặc: cephadm shell -- ceph cephadm get-pub-key)
ssh-copy-id -f -i ~/ceph.pub <user>@<NODE2_MGMT>
ssh-copy-id -f -i ~/ceph.pub <user>@<NODE3_MGMT>

# 4.2 Add host (trên node1)
sudo /tmp/cephadm-squid shell -- ceph orch host add openstack-node2 <NODE2_MGMT>
sudo /tmp/cephadm-squid shell -- ceph orch host add openstack-node3 <NODE3_MGMT>
sudo /tmp/cephadm-squid shell -- ceph orch host ls   # 3 host online

# 4.3 Label (lệnh này chỉ nhận 1 label/lần!)
for h in openstack-node2 openstack-node3; do
  sudo /tmp/cephadm-squid shell -- ceph orch host label add $h mon
  sudo /tmp/cephadm-squid shell -- ceph orch host label add $h mgr
  sudo /tmp/cephadm-squid shell -- ceph orch host label add $h _admin
done

# 4.4 Scale + giảm RAM (node chạy chung OpenStack → 0.2 thay vì default 0.7)
sudo /tmp/cephadm-squid shell -- ceph orch apply mon 3
sudo /tmp/cephadm-squid shell -- ceph orch apply mgr 3
sudo /tmp/cephadm-squid shell -- ceph config set mgr mgr/cephadm/autotune_memory_target_ratio 0.2
```

---

## 5. OSD trên ổ 1TB

```sh
# 5.1 Xác nhận ổ sạch trên cả 3 node (Available = Yes, sda/partitions bị loại là đúng)
sudo /tmp/cephadm-squid shell -- ceph orch device ls

# 5.2 Nếu ổ báo NOT Available do tàn dư cluster cũ (LVM/FileSystem):
#     kiểm tra zombie trước: systemctl list-units 'ceph-<OLD_FSID>*' + docker ps
#     stop+disable unit cũ, kill process ceph-osd sót, rồi:
sudo /tmp/cephadm-squid shell -- ceph orch device zap <host> /dev/sdb --force

# 5.3 Tạo OSD (mỗi node 1 cái, chỉ đúng ổ data — KHÔNG dùng --all-available-devices
#     nếu chưa chắc chắn, lệnh explicit an toàn hơn)
sudo /tmp/cephadm-squid shell -- ceph orch daemon add osd openstack-node1:/dev/sdb
sudo /tmp/cephadm-squid shell -- ceph orch daemon add osd openstack-node2:/dev/sdb
sudo /tmp/cephadm-squid shell -- ceph orch daemon add osd openstack-node3:/dev/sdb

sudo /tmp/cephadm-squid shell -- ceph osd df   # 3 OSD up/in, ~1TB mỗi cái
```

> **Bài học xương máu**: `cephadm rm-cluster` có thể để sót systemd unit
> (`ceph-<fsid>@*.service`, `Restart=always`) → daemon cũ sống lại, giữ LV
> (`Device or resource busy`, `lvchange` báo in use) và chiếm port 8443/3000.
> Dọn: `systemctl stop/disable` từng unit cũ + `rm` container + zap lại.
> Kiểm tra kẻ giữ ổ: `fuser /dev/dm-N`, `ps -C ceph-osd`.

---

## 6. Pool + user cho OpenStack

```sh
C=/tmp/cephadm-squid; S="shell --"
for p in images volumes backups vms; do
  sudo $C $S ceph osd pool create $p
  sudo $C $S ceph osd pool set $p pg_autoscale_mode on
  sudo $C $S ceph osd pool set $p size 3
  sudo $C $S ceph osd pool set $p min_size 2
  sudo $C $S ceph osd pool application enable $p rbd
  sudo $C $S rbd pool init $p
done

# Nova dùng chung user cinder (default của Kolla: ceph_nova_user = ceph_cinder_user)
sudo $C $S ceph auth get-or-create client.glance \
  mon "profile rbd" osd "profile rbd pool=images" mgr "profile rbd pool=images"
sudo $C $S ceph auth get-or-create client.cinder \
  mon "profile rbd" \
  osd "profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images" \
  mgr "profile rbd pool=volumes, profile rbd pool=vms"
sudo $C $S ceph auth get-or-create client.cinder-backup \
  mon "profile rbd" osd "profile rbd pool=backups" mgr "profile rbd pool=backups"

sudo $C $S ceph -s    # expect HEALTH_OK, 3 mon quorum, 3 osd up/in
sudo $C $S ceph df    # 4 pool + .mgr, ~3TB avail
```

---

## 7. Nối vào Kolla-Ansible

### 7.1 File config (đặt trên máy deploy, repo Kolla, `KOLLA_CONFIG_PATH=kolla/`)

```sh
# ceph.conf — lấy từ node1. ⚠️ KHÔNG thụt đầu dòng (tab/space)!
# merge_configs của Kolla (parser oslo_config) coi dòng thụt đầu dòng là
# "continuation" -> lỗi "Unexpected continuation line". Format đúng:
#   [global]
#   fsid = ...
#   mon_host = ...
ssh <user>@<NODE1_MGMT> "sudo cat /etc/ceph/ceph.conf" > kolla/config/glance/ceph.conf
cp kolla/config/glance/ceph.conf kolla/config/cinder/ceph.conf
cp kolla/config/glance/ceph.conf kolla/config/nova/ceph.conf

# Keyring — 4 file ở 4 vị trí (cinder-backup cần CẢ 2 keyring!):
ssh <user>@<NODE1_MGMT> "sudo ceph auth get client.glance" \
  > kolla/config/glance/ceph.client.glance.keyring
ssh <user>@<NODE1_MGMT> "sudo ceph auth get client.cinder" \
  > kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring
cp kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring \
   kolla/config/nova/ceph.client.cinder.keyring
cp kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring \
   kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring
ssh <user>@<NODE1_MGMT> "sudo ceph auth get client.cinder-backup" \
  > kolla/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring
```

> `/kolla/` đã gitignore nên keyring không lọt lên git. Đừng commit file `*.keyring`.

### 7.2 `kolla/globals.yml` (phần Ceph)

```yaml
enable_cinder: true            # default false, phải bật tay
glance_backend_ceph: true
cinder_backend_ceph: true
cinder_backup_driver: "ceph"   # backup vào pool backups
nova_backend_ceph: true        # ephemeral vào pool vms (live-migration OK)
enable_valkey: true            # cinder-ceph bắt buộc coordination
cinder_cluster_name: "cinder"  # cinder-volume HA 3 bản bắt buộc tên cluster
```

---

## 8. Verify end-to-end (sau `kolla-ansible deploy`)

```sh
# 8.1 Trong container glance (client Reef/Squid thật): connect + list pool
sudo docker exec glance_api python3 -c \
  "import rados; c=rados.Rados(conffile='/etc/ceph/ceph.conf',name='client.glance'); \
   c.connect(timeout=10); print(sorted(c.pool_list())); c.shutdown()"
# expect: [..., 'backups', 'images', 'volumes', 'vms', ...] — KHÔNG lỗi EIO/auth

# 8.2 Upload image thật (qua Horizon hoặc CLI)
openstack image create --disk-format qcow2 --container-format bare \
  --file cirros.img cirros-test
openstack image show cirros-test -f value -c status   # expect: active
rbd -p images ls                                       # thấy image UUID

# 8.3 Volume + boot VM từ image + live-migrate giữa 2 node còn lại
openstack volume create --size 10 test-vol
openstack server create --image cirros-test --flavor m1.tiny \
  --network <net> test-vm
openstack server migrate --live <node-khac> test-vm

# 8.4 HA: reboot 1 node → ceph -s vẫn OK, API + VM sống
```

---

## 9. Về sau: upgrade Ceph khi image Kolla lên đời

```sh
# Khi client trong image đã là Squid/Tentacle:
sudo cephadm shell -- ceph orch upgrade check quay.io/ceph/ceph:v<NEW>
sudo cephadm shell -- ceph orch upgrade start quay.io/ceph/ceph:v<NEW>
# rolling từng daemon, không mất data, key/pool giữ nguyên
```

---

## 10. Troubleshooting nhanh (lỗi đã gặp thật)

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `download.ceph.com/cephadm` → 404 | Link chung đã chết | Dùng `https://download.ceph.com/rpm-<VER>/el9/noarch/cephadm` |
| `handle_auth_bad_method`, RADOS EIO dù key/caps/mạng đúng | Client ↔ cluster cách nhau ≥ 2 đời (Reef → Tentacle) | Align version theo mục 0 |
| `Unexpected continuation line: '\tfsid...'` ở task ceph Glance/Cinder/Nova | `ceph.conf` thụt đầu dòng (tab) | Viết lại không thụt dòng (mục 7.1) |
| Thiếu `ceph.client.cinder.keyring` trong `cinder-backup/` | Task loop 2 backend, cần cả 2 keyring | Copy thêm như mục 7.1 |
| `HEALTH_ERR`, port 8443/3000 bận, daemon lạ `Up ...` | Unit systemd cluster cũ sống lại (`Restart=always`) | `stop/disable` hết unit fsid cũ, `rm` container, zap lại (mục 5.2) |
| Zap báo `Device or resource busy` | Process `ceph-osd` sót giữ LV | `ps -C ceph-osd` → `kill` → `lvchange -an` → zap lại |
| `Please enable valkey or etcd` (prechecks) | Cinder-ceph bắt buộc coordination | `enable_valkey: true` |
| `cinder_cluster_name is not set` (prechecks) | cinder-volume HA 3 bản | `cinder_cluster_name: "cinder"` |
| Upload image CORS (browser) | Glance thiếu `allow_headers` cho `X-CSRFToken` | Override `kolla/config/glance/glance-api.conf` section `[cors]` + reconfigure |
| Upload image `410 store disabled` | RBD store init fail (xem `/var/log/kolla/glance/glance-api.log`) | Fix gốc (thường là connect/auth Ceph), restart glance |
| Magnum bootstrap fail collation `1267` | Migration cũ + MariaDB 11.x default mới | Convert bảng về `utf8mb3_general_ci` + retry (DB fresh, an toàn) |
