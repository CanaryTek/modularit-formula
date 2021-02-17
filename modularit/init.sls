# Includes
{% if not grains['os_family'] == "Windows" %}
include:
  - openssh
  - modularit.noc_user
  - modularit.misc
{% endif %}
