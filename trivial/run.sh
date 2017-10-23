#!/usr/bin/env bash

set -e

if ! test -d .venv ;
then
    virtualenv .venv
fi

source .venv/bin/activate

pip install requirements.txt

rm -rf roles ; mkdir roles
ansible-galaxy install -r requirements.yml -p roles/

ansible-playbook -i "inventory" "test.yml"

deactivate
