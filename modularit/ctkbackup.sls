##
## CTKBackups
##

# TODO:

# Backup packages
backup-pkgs:
  pkg.installed:
    - pkgs:
      - rclone
      - duply

# safekeep is not on repos
safekeep-pkgs:
  pkg.installed:
    - sources:
      - safekeep-common: http://prdownloads.sourceforge.net/safekeep/safekeep-common_1.5.1_all.deb
      - safekeep-server: http://prdownloads.sourceforge.net/safekeep/safekeep-server_1.5.1_all.deb

# BTRFS subvolumes
subvol-Backups:
  cmd.run:
    - name: "btrfs subvol create /dat/bck/Backups"
    - unless: "btrfs subvol list /dat/bck  | grep 'path Backups'"
subvol-Volcados:
  cmd.run:
    - name: "btrfs subvol create /dat/bck/Volcados"
    - unless: "btrfs subvol list /dat/bck  | grep 'path Volcados'"
subvol-Safekeep:
  cmd.run:
    - name: "btrfs subvol create /dat/bck/Safekeep"
    - unless: "btrfs subvol list /dat/bck  | grep 'path Safekeep'"
# FIXME: TODO: Propietario de Volcados y Backups: writer
 
# Samba
samba-pks:
  pkg.installed:
    - name: samba

smbd-service:
  service.running:
    - name: smbd
    - enable: True
    - watch:
      - file: /etc/samba/smb.conf
      - file: /etc/samba/backup_shares.conf

samba-shares-config:
  file.managed:
    - name: /etc/samba/backup_shares.conf
    - source: salt://modularit/files/ctkbackup/backup_shares.conf
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - dir_mode: 755

samba-shares-include:
  file.append:
    - name: /etc/samba/smb.conf
    - text:
      - "# Include backup shares config"
      - "include = /etc/samba/backup_shares.conf"

# Backup users
writer-user:
  cmd.run:
    - name: "useradd writer && (echo writer_passwd; echo writer_passwd) | smbpasswd -as writer"
    - unless: "pdbedit -L | grep writer"
    
reader-user:
  cmd.run:
    - name: "useradd reader && (echo reader_passwd; echo reader_passwd) | smbpasswd -as reader"
    - unless: "pdbedit -L | grep reader"

## Snapshots management
snapshots-script:
  file.managed:
    - name: /root/bin/manage_snapshots.sh
    - source: salt://modularit/files/ctkbackup/manage_snapshots.sh
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - dir_mode: 755

snapshots-cron:
  cron.present:
    - name: /root/bin/manage_snapshots.sh
    - user: root
    - hour: "01"
    - minute: "01"

## rclone
rcolne-config:
  file.managed:
    - name: /root/.config/rclone/rclone.conf
    - source: salt://modularit/files/ctkbackup/rclone.conf.jinja
    - replace: false
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 600

rclone-script:
  file.managed:
    - name: /root/bin/rclone_backups.sh
    - source: salt://modularit/files/ctkbackup/rclone_backups.sh
    - makedirs: true
    - user: root
    - group: root
    - mode: 755
    - dir_mode: 755

rclone-cron:
  cron.present:
    - name: /root/bin/rclone_backups.sh
    - user: root
    - hour: "02"
    - minute: "01"

# Crontab ejecucion duply
# config duply (gpg etc)
# gpg-master-key

# Crontab snapshots btrfs
# TODO: usar snapper, nos permite definir retencion por tiempo (conservar snapshot horarios, 1 diario, 1 semanal, etc)

