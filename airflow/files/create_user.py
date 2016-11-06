
from __future__ import print_function

import sys
from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser

user = PasswordUser(models.User())
user.username = sys.argv[1]
user.email = sys.argv[2]
user.password = sys.argv[3]
session = settings.Session()
session.add(user)
try:
    session.commit()
except:
    print("User already exists.")
session.close()
exit()
