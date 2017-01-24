#!/bin/bash
{%- from "airflow/map.jinja" import server with context %}

. {{ server.dir.home }}/bin/activate

export AIRFLOW_HOME="{{ server.dir.home }}"

# do not load /etc/boto.cfg with Python 3 incompatible plugin
# https://github.com/travis-ci/travis-ci/issues/5246#issuecomment-166460882
export BOTO_CONFIG=/doesnotexist

exec $1