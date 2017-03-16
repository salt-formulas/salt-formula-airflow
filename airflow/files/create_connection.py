

from __future__ import print_function

import yaml
import json
import sys
from airflow import models, settings

connections = {}

with open(sys.argv[1], "r") as file:
    connections = yaml.load(file)['connections']

session = settings.Session()


def get_connection(conn_id):
    """Returns a connection by id
    """

    return session.query(
        models.Connection).filter_by(
        conn_id=conn_id).first()


def get_or_create_conn(name, **kwargs):
    """Returns a connection by id
    """

    con = get_connection(name)

    if not con:
        con = models.Connection(name, **kwargs)
        session.add(con)
        session.commit()

    return con


def get_or_update_conn(name, **kwargs):
    """Returns a connection by id
    """

    con = get_connection(name)

    if not con:
        con = models.Connection(name, **kwargs)
        session.add(con)
        session.commit()
    else:

        for key, value in kwargs.items():

            if key == "extra":
                con.set_extra(value)
            else:
                setattr(con, key, value)

        session.commit()

    return con


for conn_name, conn in connections.items():

    uri = None

    extra = conn.get('extra', {})
    type = conn.get('type', {})

    if 'password' in conn and 'host' in conn:
        db = ''
        port = ''
        if 'database' in conn:
            db = '/' + conn.get('database', '')
        if 'port' in conn:
            port = ':%s' % conn.get('port', '')
        uri = (conn['type'] + '://' + conn['user'] +
               ':' + conn['password'] + '@' + conn['host'] + port + db)

    if conn.get("update", False):
        get_or_update_conn(
            conn_name, type=type, uri=uri, extra=json.dumps(extra))
    else:
        get_or_create_conn(
            conn_name, type=type, uri=uri, extra=json.dumps(extra))


exit()
