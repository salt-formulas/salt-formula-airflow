
=======
Airflow
=======

The Airflow Platform is a tool for describing, executing, and monitoring workflows.


Sample pillars
==============

Single airflows service

.. code-block:: yaml

    airflow:
      server:
        enabled: true
        backup: true
        debug: true
        auth:
          engine: password
          enabled: true
          user:
            test:
              username: test
              email: email@test.cz
              password: test
        bind:
          address: localhost
          protocol: tcp
          port: 8000
        enabled: true
        worker: true
        secret_key: secret
        dag:
          dagbag:
            engine: git
            address: git@gitlab.com:group/dags.git
            rev: master
        plugin:
          pack-one:
            engine: git
            address: git@gitlab.com:group/dags.git
            rev: master
        database:
          engine: postgres
          host: 127.0.0.1
          name: airflow_prd
          password: password
          user: airflow_prd
        broker:
          engine: redis
          host: 127.0.0.1
          port: 6379
          number: 10
        logging:
          engine: sentry
          dsn: dsn

    supervisor:
      server:
        service:
          airflow:
            name: airflow
            type: airflow
          airflow_scheduler:
            name: scheduler
            type: airflow
          airflow_worker:
            name: worker
            type: airflow


Read more
=========

* links
