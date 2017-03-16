
from __future__ import print_function

import sys
from airflow import models, settings

name = sys.argv[1]
c_type = sys.argv[2]
uri = sys.argv[3]
extra = sys.argv[4]
create = eval(sys.argv[5])


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


if create:
    get_or_update_conn(
        name, uri=uri, extra=extra)
else:
    get_or_create_conn(
        name, uri=uri, extra=extra)


exit()
