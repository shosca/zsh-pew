Pew Autoswitch Virtualenv
=========================

A very simple plugin that sets up and manages virtualenvs using `pew`, automatically switches virtualenvs as you move
directories

Install
-------

ZPlug_

::

  zplug "shosca/zsh-pew"

Settings
--------

- ``DISABLE_PEW_AUTOACTIVATE`` will disable autoactivation on load

- ``PEW_DEFAULT_PYTHON`` sets the default python to use for virtualenv

- ``PEW_DEFAULT_REQUIREMENTS`` a requirements file for python packages to be installed by default

Commands
--------

- ``mkvirtualenv`` creates a virtualenv using `pew` for a project

- ``rmvirtualenv`` destorys a virtualenv for a project using `pew`

- ``install_requirements`` installs python requirements found in the project

- ``workon`` manually activates virtualenv

- ``enable_pew_autoactivate`` and ``disable_pew_autoactivate`` toggles pew autoactivation

.. _Zplug: https://github.com/zplug/zplug
