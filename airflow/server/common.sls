{%- from "airflow/map.jinja" import server with context %}

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

{%- if server.source is defined and server.source.engine == "git" %}
airflow_installation:
  pip.installed:
  {%- if server.source.get('engine', 'git') == 'git' %}
  - editable: "git+{{ server.source.address }}@{{ server.source.get("rev", "master") }}#egg=airflow"
  {%- elif server.source.engine == 'pip' %}
  - name: airflow {%- if server.version is defined %}=={{ server.version }}{% endif %}
  {%- endif %}
  - name: mbot
  - bin_env: /srv/airflow
  - exists_action: w
  - require:
    - virtualenv: /srv/airflow
{%- endif %}

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
  - name: {{ plugin_source.address }}
  - target: /srv/airflow/plugins/{{ plugin_name }}
  - rev: {{ plugin_source.get('rev', plugin_source.get('revision', 'master')) }}
  - force_reset: True
  - require:
    - file: airflow_dirs

airflow_plugin_install_{{ plugin_name }}:
  cmd.run:
  - name: . /srv/airflow/bin/activate; make update
  - cwd: /srv/airflow/plugins/{{ plugin_name }}
  - env:
    - AIRFLOW_HOME: {{ server.dir.home }}/app
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


{{ server.dir.home }}/app/airflow.cfg:
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
    - PYTHONPATH: {{ server.dir.home }}/app
    - AIRFLOW_HOME: {{ server.dir.home }}/app
  - require:
    - file: airflow_dirs
    - virtualenv: /srv/airflow

/srv/airflow/bin/create_user.py:
  file.managed:
  - source: salt://airflow/files/create_user.py
  - mode: 700
  - template: jinja
  - require:
    - cmd: airflow_init_db

/srv/airflow/bin/create_connection.py:
  file.managed:
  - source: salt://airflow/files/create_connection.py
  - mode: 700
  - template: jinja
  - require:
    - cmd: airflow_init_db

/srv/airflow/bin/create_variable.py:
  file.managed:
  - source: salt://airflow/files/create_variable.py
  - mode: 700
  - template: jinja
  - require:
    - cmd: airflow_init_db

{%- if server.connection is defined %}
{%- for conn_name, conn in server.connection.iteritems() %}
{% if conn.password is defined %}
{%- if conn.database is defined %}
{%- set db = '/' + conn.get('database', None) %}
{%- else %}
{%- set db = None %}
{%- endif %}
{%- if conn.port is defined %}
{%- set port = ':' + conn.get('port', '')|string %}
{%- else %}
{%- set port = '' %}
{%- endif %}
{%- set uri = conn.type + '://' + conn.user + ':' + conn.password + '@' + conn.host + port + db %}
{%- else %}
{%- set uri = None %}
{%- endif %}
airflow_create_conn_{{ conn_name }}:
  cmd.run:
  - name: . /srv/airflow/bin/activate && /srv/airflow/bin/python /srv/airflow/bin/create_connection.py {{ conn.get('name', conn_name) }} {{ conn.type }} {{ uri }} '{{ conn.get('extra', {})|json }}' {{ conn.get("update", False)|python }}
  - cwd: /srv/airflow
  - env:
    - PYTHONPATH: '/srv/airflow'
    - AIRFLOW_HOME: {{ server.dir.home }}/app
  - require:
    - cmd: airflow_init_db
{%- endfor %}
{%- endif %}

{%- if server.variable is defined %}
{%- for var_name, var in server.variable.iteritems() %}
airflow_create_variable_{{ var_name }}:
  cmd.run:
  - name: . /srv/airflow/bin/activate && /srv/airflow/bin/python /srv/airflow/bin/create_variable.py {{ var.get('name', var_name) }} {{ var.value }} {{ var.get("update", False)|python }}
  - cwd: /srv/airflow
  - env:
    - PYTHONPATH: '/srv/airflow'
    - AIRFLOW_HOME: {{ server.dir.home }}/app
  - require:
    - cmd: airflow_init_db
{%- endfor %}
{%- endif %}


{%- for user_name, user in server.auth.user.iteritems() %}
airflow_create_user_{{ user_name }}:
  cmd.run:
  - name: . /srv/airflow/bin/activate && /srv/airflow/bin/python /srv/airflow/bin/create_user.py {{ user.username }} {{ user.email }} {{ user.password }}
  - cwd: /srv/airflow
  - env:
    - PYTHONPATH: '/srv/airflow'
    - AIRFLOW_HOME: {{ server.dir.home }}/app
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
