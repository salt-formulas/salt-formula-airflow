{%- if pillar.airflow is defined %}
include:
{%- if pillar.airflow.server is defined %}
- airflow.server
{%- endif %}
{%- if pillar.airflow.worker is defined %}
- airflow.worker
{%- endif %}
{%- endif %}
