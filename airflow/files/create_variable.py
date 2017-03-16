
from __future__ import print_function

import sys
from airflow import models

key = sys.argv[1]
value = sys.argv[2]
create = eval(sys.argv[3])


def get_variable(key):
    """Returns variable from Variable or config defaults"""

    return models.Variable.get(key)


def create_variable(key, value):
    """Create variable"""

    return models.Variable.set(key, value)


if create and not get_variable(key):
    create_variable(key, value)
else:
    create_variable(key, value)

exit()
