{%- from "airflow/map.jinja" import server with context %}

{%- if server.enabled %}

include:
- airflow.server

airflow_webserver_services_dead:
  supervisord.dead:
    - names:
      - airflow_webserver

airflow_webserver_services:
  supervisord.running:
    - names:
      - airflow_webserver
      - airflow_scheduler
    - restart: True
  - require:
    - supervisord: airflow_webserver_services_dead

{%- endif %}
