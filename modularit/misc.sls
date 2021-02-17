# Misc stuff

# Some propaganda
/etc/motd:
  file.managed:
    - source: salt://modularit/files/motd
    - user: root
    - group: root
    - mode: 644
