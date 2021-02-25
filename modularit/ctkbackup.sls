##
## CTKBackups
##
{% from "modularit/map.jinja" import modularit with context %}
{% from "modularit/map.jinja" import ctkbackup with context %}

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
      - safekeep-common: {{ ctkbackup.safekeep_common_url }}
      - safekeep-server: {{ ctkbackup.safekeep_server_url }}

# BTRFS subvolumes
subvol-Backups:
  cmd.run:
    - name: "btrfs subvol create /dat/bck/Backups && chmod 777 /dat/bck/Backups"
    - unless: "btrfs subvol list /dat/bck  | grep 'path Backups'"
subvol-Volcados:
  cmd.run:
    - name: "btrfs subvol create /dat/bck/Volcados && chmod 777 /dat/bck/Volcados"
    - unless: "btrfs subvol list /dat/bck  | grep 'path Volcados'"
subvol-Safekeep:
  cmd.run:
    - name: "btrfs subvol create /dat/bck/Safekeep"
    - unless: "btrfs subvol list /dat/bck  | grep 'path Safekeep'"
 
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
    - name: "useradd writer && (echo {{ ctkbackup.writer_password }} ; echo {{ ctkbackup.writer_password }}) | smbpasswd -as writer"
    - unless: "pdbedit -L | grep writer"
    
reader-user:
  cmd.run:
    - name: "useradd reader && (echo {{ ctkbackup.reader_password }} ; echo {{ ctkbackup.reader_password }}) | smbpasswd -as reader"
    - unless: "pdbedit -L | grep reader"

## Snapshots management
# TODO: usar snapper, nos permite definir retencion por tiempo (conservar snapshot horarios, 1 diario, 1 semanal, etc)
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
rclone-config:
  file.managed:
    - name: /root/.config/rclone/rclone.conf
    - source: salt://modularit/files/ctkbackup/rclone.conf.jinja
    - replace: false
    - template: jinja
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 700
    - context:
        ctkbackup: {{ ctkbackup }}

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

## Duply

# Import GPG KEYS
# TODO: Make source configurable
cktbackup-gpg-master-key:
  file.managed:
    - name: /root/ctkbackup-master_pub.asc
    - source: salt://modularit/files/ctkbackup/ctkbackup-master_pub.asc
    - user: root
    - group: root
    - mode: 600
cktbackup-gpg-master-key-import:
  cmd.run:
    - name: "gpg --import /root/ctkbackup-master_pub.asc && echo '{{ ctkbackup.gpg_master_key_id }}:6:' | gpg --import-ownertrust"
    - unless: "gpg --list-keys | grep {{ ctkbackup.gpg_master_key_id }}"

# Configs
duply-conf-Safekeep:
  file.managed:
    - name: /root/.duply/Safekeep/conf
    - source: salt://modularit/files/ctkbackup/duply.conf.jinja
    - template: jinja
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 700
    - context:
        volume: "Safekeep"
        ctkbackup: {{ ctkbackup }}
duply-exclude-Safekeep:
  file.managed:
    - name: /root/.duply/Safekeep/exclude
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 700
    - contents:
        - "# Files to exclude"
        - "- **/rdiff-backup-data"

duply-conf-Volcados:
  file.managed:
    - name: /root/.duply/Volcados/conf
    - source: salt://modularit/files/ctkbackup/duply.conf.jinja
    - template: jinja
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 700
    - context:
        volume: "Volcados"
        ctkbackup: {{ ctkbackup }}
duply-exclude-Volcados:
  file.managed:
    - name: /root/.duply/Volcados/exclude
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 700
    - contents:
        - "# Files to exclude"

duply-incremental-cron:
  cron.present:
    - name: /usr/bin/duply Safekeep incr ; /usr/bin/duply Volcados incr
    - user: root
    - hour: "01"
    - minute: "30"
    - dayweek: "1-6"

duply-full-cron:
  cron.present:
    - name: /usr/bin/duply Safekeep full ; /usr/bin/duply Volcados full
    - user: root
    - hour: "01"
    - minute: "30"
    - dayweek: "7"

# Safekeep config
safekeep-backup-template:
  file.managed:
    - name: /etc/safekeep/backup.d/cliente.nodo1.backup.template
    - source: salt://modularit/files/ctkbackup/safekeep.backup.template
    - makedirs: true
    - user: root
    - group: root
    - mode: 600
    - dir_mode: 700

# Postfix - send email through sendgrid
postfix-pkg:
  pkg.installed:
    - name: postfix

postfix-service:
  service.running:
    - name: postfix
    - enable: True
    - watch:
      - file: /etc/postfix/main.cf
      - file: /etc/postfix/sasl_passwd

postfix-main-cf:
  file.append:
    - name: /etc/postfix/main.cf
    - text:
      - ""
      - "# Use sendgrid as relayhost"
      - smtp_sasl_auth_enable = yes
      - smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
      - smtp_sasl_security_options = noanonymous
      - smtp_sasl_tls_security_options = noanonymous
      - smtp_tls_security_level = encrypt
      - header_size_limit = 4096000
      - relayhost = [smtp.sendgrid.net]:587

postfix-sasl-cf:
  file.managed:
    - name: /etc/postfix/sasl_passwd
    - user: root
    - group: root
    - mode: 600
    - contents:
        - "[smtp.sendgrid.net]:587 apikey:{{ modularit.sendgrid_api_key }}"

postmap:
  cmd.run:
    - name: "postmap /etc/postfix/sasl_passwd; postfix reload"
    - onchanges:
      - file: /etc/postfix/sasl_passwd

