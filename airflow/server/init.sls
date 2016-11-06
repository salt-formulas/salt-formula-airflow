{%- from "airflow/map.jinja" import server with context %}

{%- if server.enabled %}
airflow_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

airflow_user:
  user.present:
  - name: airflow
  - shell: /bin/bash
  - system: true
  - home: {{ server.dir.home }}

airflow_dirs:
  file.directory:
  - names:
    - /srv/airflow
    - /var/log/airflow
    - /srv/airflow/flags
  - makedirs: true
  - group: airflow
  - user: airflow
  - require:
    - user: airflow

{{ server.dir.home }}:
  virtualenv.manage:
  - requirements: salt://airflow/files/requirements.txt
  - python: /usr/bin/python3
  - user: airflow
  - require:
    - pkg: airflow_packages

airflow_dag_source:
  git.latest:
  - name: {{ server.source.address }}
  - target: /srv/airflow/app
  - rev: {{ server.source.get('rev', server.source.get('revision', 'master')) }}
  - force_reset: True
  - require:
    - file: airflow_dirs

/var/log/airflow/access.log:
  file.managed:
  - mode: 666
  - user: airflow
  - group: airflow
  - require:
    - file: airflow_dirs

/var/log/airflow/error.log:
  file.managed:
  - mode: 666
  - user: airflow
  - group: airflow
  - require:
    - file: airflow_dirs


{{ server.dir.home }}/airflow.cfg:
  file.managed:
  - source: salt://airflow/files/config.cfg
  - template: jinja
  - user: airflow
  - group: airflow
  - mode: 644
  - require:
    - file: airflow_dirs

/srv/airflow/bin/start-service.sh:
  file.managed:
  - source: salt://airflow/files/start-service.sh
  - mode: 700
  - template: jinja
  - user: airflow
  - group: airflow
  - require:
    - file: airflow_dirs
    - virtualenv: /srv/airflow

airflow_init_db:
  cmd.run:
  - name: /srv/airflow/bin/airflow initdb
  - cwd: /srv/airflow
  - env:
    - PYTHONPATH: '/srv/airflow'
    - AIRFLOW_HOME: {{ server.dir.home }}
  - user: airflow
  - group: airflow
  - require:
    - file: airflow_dirs
    - virtualenv: /srv/airflow

/srv/airflow/bin/create_user.py:
  file.managed:
  - source: salt://airflow/files/create_user.py
  - mode: 700
  - template: jinja
  - user: airflow
  - group: airflow
  - require:
    - cmd: airflow_init_db

{%- for user_name, user in server.auth.user.iteritems() %}
airflow_create_user_{{ user_name }}:
  cmd.run:
  - name: source /srv/airflow/bin/activate && /srv/airflow/bin/python /srv/airflow/bin/create_user.py {{ user.username }} {{ user.email }} {{ user.password }}
  - cwd: /srv/airflow
  - user: airflow
  - group: airflow
  - env:
    - PYTHONPATH: '/srv/airflow'
    - AIRFLOW_HOME: {{ server.dir.home }}
  - require:
    - cmd: airflow_init_db
{%- endfor %}

airflow_permissions:
  cmd.run:
  - name: chown airflow:airflow . -R
  - cwd: /srv/airflow
  - user: root
  - require:
    - file: /srv/airflow/bin/create_user.py
    - virtualenv: /srv/airflow

{%- endif %}
