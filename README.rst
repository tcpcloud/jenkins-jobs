============
Jenkins jobs
============

This is jenkins-job-builder_ setup for tcpcloud Jenkins jobs.

.. _jenkins-job-builder: http://docs.openstack.org/infra/jenkins-job-builder/

Installation
============

First install jenkins-job-builder.

.. code-block:: bash

    pip install jenkins-job-builder

Edit ``/etc/jenkins_jobs/jenkins_jobs.ini`` with access to running jenkins
instance:

.. code-block:: ini

    [job_builder]
    recursive=True

    [jenkins]
    user=admin
    password=<jenkins_admin_password>
    url=http://localhost:8080

Clone repository, fix variables (especially `defaults.yaml`), possibly setup
projects as you like. ``git grep -e FIXME -e example`` is your friend :-)

Finally you can create jenkins jobs.

.. code-block:: bash

    jenkins-jobs --flush-cache update `pwd`

Available jobs
==============

Aptly
-----

.. list-table::

    *  - **aptly-publish-nightly**
       - Run `aptly-publisher` to update `nightly` publish from latest
         snapshots.
         Executed after `aptly-snapshot-repo`
    *  - **aptly-promote-{name}**
       - Run `aptly-publisher` to promote snapshots/packages from source
         publish to target (eg. nightly -> testing)
    *  - **aptly-diff-{name}**
       - Run `aptly-publisher` to diff changes between publishes
    *  - **aptly-snapshot-repo**
       - Create snapshot of given repository
    *  - **aptly-cleanup-snapshots**
       - Cleanup old snapshots which are not used for any publish.
         Executed after `aptly-publish-nightly`

For more informations, see Aptly_ and aptly-publisher_.

.. _Aptly: http://www.aptly.info/
.. _aptly-publisher: https://github.com/tcpcloud/python-aptly

Debian package builds
---------------------

Following jobs are using jenkins-debian-glue_ (which uses cowbuilder) to build
packages.

.. _jenkins-debian-glue: http://jenkins-debian-glue.org/

.. list-table::

    *  - **debian-build-{cowbuilder_namespace}-{name}-source**
       - Build source package from Git repository
    *  - **debian-build-{cowbuilder_namespace}-{name}-binary**
       - Build package from source package.
         Executed after `*-source` build
    *  - ** debian-build-{cowbuilder_namespace}-{name}-upload**
       - Upload binary package into Aptly repository.
         Executed after successful `*-binary` build
    *  - **debian-build-{cowbuilder_namespace}-{name}-upload-ppa**
       - Upload source package into Launchpad PPA repository (to be built by
         Launchpad).
         Executed after successful `*-binary` build

For more informations see:

* `Using pbuilder <https://fpy.cz/wiki/howto/pbuilder>`_
* `Debian packaging slides <https://fpy.cz/pub/slides/debian-packaging>`_

Contrail package builds
-----------------------

.. list-table::

    *  - **contrail-build-{name}-source**
       - Build source package using magical ``contrail_build_source.sh``
         script
    *  - **contrail-build-{name}-binary**
       - Use jenkins-debian-glue to build binary package.
         Executed after `*-source` build
    *  - **contrail-build-{name}-upload**
       - Upload binary package to Aptly.
         Executed after `*-binary` build
    *  - **contrail-build-{name}-upload-ppa**
       - Upload source package to Launchpad PPA repository.
         Executed after `*-binary` build
