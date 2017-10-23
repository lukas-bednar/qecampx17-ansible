# qecampx17-ansible

This repository holds several examples for purposes of QECampX 2017 in Brno.
You can find things related to my talk about *Ansible role which test your roles*.

The Ansible is https://github.com/chrismeyersfsu/provision_docker

I was sharing my experience with this role and giving useful hints which
can help others to get started with this role and test their roles.

I also recomend to read following blog post which is very useful when you want to integrate with Travis CI.

https://www.ansible.com/blog/testing-ansible-roles-with-docker


## Trivial Example

You can find all examples used in a talk under `trivial` directory.


## Challenges

As I promissed put all chalanges here so that you can easily overcome them.

### Can not run under non-root user

* There is an open issue https://github.com/chrismeyersfsu/provision_docker/issues/58
* There is problem with DNF Ansible module, which requires root permission even in case that desired package is already installed on system.

```yaml
# requirements.yml
---
- src: https://github.com/rhevm-qe-automation/provision_docker.git
  name: provision_docker
# Can not use chrismeyersfsu/provision_docker directly because of issue
# https://github.com/chrismeyersfsu/provision_docker/issues/58
```


### Can not start system service

* When you pull CentOS or RHEL docker image it contains different packages for systemd
  * systemd-container
  * systemd-container-libs
* You will need do some tuning of Dockerfile to get over it
* You can find it in product documentation of Red Hat Enterprise Linux Atomic
  * **3.2. Starting services within a container using systemd**
* You can also check the dockerfile provided by provision\_docker role https://github.com/chrismeyersfsu/provision_docker/blob/master/files/Dockerfile.centos_7

**Following images are already tuned**
* chrismeyers/centos6
* chrismeyers/centos7
* *to access tuned images for rhel please contact lukas-bednar*


### Some task don't work in container

I have only three ways here

* If the task is not crucial, add the tag **docker-test-breaker** and skip these when running tests
* If you can not skip that task, then try to find some work around - always consider whether worth that
* In the worst case you will have to go with other way to test your role / playbook :-(

### Can not see any network interfaces

* You need to tell docker to use some netwok driver
* There is an option to set **provision_docker_network**

```yaml
# test.yml
---
- name: Provision docker containers
  hosts: localhost
  roles:
    - role: provision_docker
      provision_docker_inventory_group: "{{ groups['cattles'] }}"
      provision_docker_use_docker_connection: true
      provision_docker_network: "host"  # or 'bridge' or other driver

- include: playbook.yml
```

### Can not edit /etc/hosts

For some reason some files inside of container are mounted with bind option.

```bash
$ mount --bind /path/to/file1 /path/to/file2
```
That causes problem to rename such file.

And unfortunately some of Ansible modules tends to do that: **lineinfile**

```yaml
# roles/myrole/tasks/main.yml
---
- name: Add my.example.com to /etc/hosts
  lineinfile:
    path: /etc/hosts
    line: "{{ ansible_default_ipv4.address}} my.example.com"
    unsafe_writes: "{{ running_in_container }}"
```

Usually such tasks provides unsafe\_writes option which bypass this operation and rewrite the file directly.

It might be really unsafe but if you use some variable like here. you can simple make it unsafe just for testing.

### I need to link two containers / add volume

There is missing documentation about some features, like linking.

You can find whole set of hidden parameters in role itself.

```yaml
---
# Trimmed content of tasks/inc_cloud_iface.yml
- name: Bring up list of hosts
  docker_container:
    restart: "{{ item.restart|default(True) }}"
    expose: "{{ item.expose|default(['1-65535']) }}"
    command: "{{ item.command|default(omit) }}"
    env: "{{ item.env|default(omit) }}"
    links: "{{ item.links|default(omit) }}"
    volumes: "{{ item.provision_docker_volumes|default(omit) }}"
    volumes_from: "{{ item.provision_docker_volumes_from|default(omit) }}"
    pull: "{{ item.pull|default(omit) }}"
```


# NOTES

* The provision\_docker might become internal ansible module
