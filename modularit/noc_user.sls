#
# noc user for system administration
#
# noc user
noc:
  user.present:
    - fullname: ModularIT NOC
    - shell: /bin/bash
    - home: /home/noc
    - system: true

# noc sudoers file
/etc/sudoers.d/noc:
  file.managed:
    - source: salt://modularit/files/sudoers_noc
    - user: root
    - group: root
    - mode: 400

# SSH keys
sshkey-ctk:
  ssh_auth.present:
    - user: noc
    - names: {{ pillar['noc-ssh-keys'] }}
    - requires:
      - user: noc

