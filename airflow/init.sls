{%- if pillar.airflow is defined %}
include:
{%- if pillar.airflow.server is defined %}
- airflow.server
{%- endif %}
{%- endif %}
