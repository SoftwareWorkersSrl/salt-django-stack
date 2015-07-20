{% set user = salt['pillar.get']('zinibu_common:app_user', 'user') %}
{% set group = salt['pillar.get']('zinibu_common:app_group', 'group') %}

user_{{ group }}_group:
  group:
  - name: {{ group }}
  - present

user_{{ user }}_user:
  user:
  - name: {{ user }}
  - present
  - require:
    - group: user_{{ group }}_group
