{%- from "airflow/map.jinja" import worker with context %}

{%- if worker.enabled %}

include:
- airflow.server

airflow_worker_services_dead:
  supervisord.dead:
    - name: airflow_worker

airflow_worker_services:
  supervisord.running:
    - names:
      - airflow_worker
    - restart: True
    - require:
      - supervisord: airflow_worker_services_dead

{%- endif %}
