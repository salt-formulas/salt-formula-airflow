{%- from "airflow/map.jinja" import server with context %}

{%- if server.enabled %}

include:
- airflow.server.common

{%- endif %}
