#!/bin/bash
{%- from "airflow/map.jinja" import server with context %}

. {{ server.dir.home }}/bin/activate

export AIRFLOW_HOME="{{ server.dir.home }}"

exec $1