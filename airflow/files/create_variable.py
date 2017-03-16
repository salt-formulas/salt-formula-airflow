
from __future__ import print_function

import sys

from airflow import models, settings

session = settings.Session()

key = sys.argv[1]
value = sys.argv[2]
create = eval(sys.argv[3])


def get_variable(key):
    """Returns variable from Variable or config defaults"""

    return session.query(
        models.Variable).filter_by(
        key=key).first()


def create_variable(key, value):
    """Create variable"""

    return models.Variable.set(key, value)


var = get_variable(key)

if create and not var:
    create_variable(key, value)
else:
    if var:
        var.value = value
        session.commit()
    else:
        create_variable(key, value)

exit()
