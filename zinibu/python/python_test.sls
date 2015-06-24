{% set user = salt['pillar.get']('zinibu_common:app_user', 'user') %}

python-test:
  cmd.run:
    - name: echo 'Python testing. This is the user variable passed via pillar {{ user }}'

# See pillar.get() vs salt['pillar.get']() at http://docs.saltstack.com/en/latest/topics/pillar/index.html

pillar-get:
  cmd.run:
    - name: echo 'pillar.get [ {% for pip_package in salt['pillar.get']('python:pip_packages', []) %}{{ pip_package }} {% endfor %}]'

pillar-dict:
  cmd.run:
    - name: echo 'pillar as dictionary [ {% for pip_package in pillar['python']['pip_packages'] %}{{ pip_package }} {% endfor %}]'
