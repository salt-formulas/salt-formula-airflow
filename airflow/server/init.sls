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
    - /srv/airflow/app
    - /srv/airflow/plugins
    - /srv/airflow/dags
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

{%- for dag_name, dag_source in server.dag.items() %}
airflow_dag_source_{{ dag_name }}:
  git.latest:
  - name: {{ dag_source.address }}
  - target: /srv/airflow/dags/{{ dag_name }}
  - rev: {{ dag_source.get('rev', dag_source.get('revision', 'master')) }}
  - force_reset: True
  - require:
    - file: airflow_dirs
{%- endfor %}

{%- for plugin_name, plugin_source in server.plugin.items() %}
airflow_plugin_source_{{ plugin_name }}:
  git.latest:
  - name: {{ dag_source.address }}
  - target: /srv/airflow/plugins/{{ plugin_name }}
  - rev: {{ plugin_source.get('rev', plugin_source.get('revision', 'master')) }}
  - force_reset: True
  - require:
    - file: airflow_dirs

airflow_plugin_install_{{ plugin_name }}:
  cmd.run:
  - name: make update
  - cwd: /srv/airflow/plugins/{{ plugin_name }}
  - env:
    - AIRFLOW_HOME: {{ server.dir.home }}
  - user: airflow
  - group: airflow
  - require:
    - file: airflow_dirs
    - git: airflow_plugin_source_{{ plugin_name }}
{%- endfor %}

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
  - name: . /srv/airflow/bin/activate && /srv/airflow/bin/python /srv/airflow/bin/create_user.py {{ user.username }} {{ user.email }} {{ user.password }}
  - cwd: /srv/airflow
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
