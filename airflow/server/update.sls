{%- from "airflow/map.jinja" import server with context %}

{%- if server.enabled %}

include:
- airflow.server

airflow_services:
  supervisord.running:
    - names:
      - airflow_airflow
      - airflow_scheduler
      - airflow_worker
    - restart: True

{%- endif %}
