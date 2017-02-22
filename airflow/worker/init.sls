{%- from "airflow/map.jinja" import worker with context %}

{%- if worker.enabled %}

include:
- airflow.server.common

{%- endif %}