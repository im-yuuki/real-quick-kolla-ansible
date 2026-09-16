`kolla-ansible deploy -i INVENTORY` is used to deploy and start all Kolla containers.

`kolla-ansible destroy -i INVENTORY` is used to clean up containers and volumes in the cluster.

`kolla-ansible mariadb-recovery -i INVENTORY` is used to recover a completely stopped mariadb cluster.

`kolla-ansible prechecks -i INVENTORY` is used to check if all requirements are met before deployment for each of the OpenStack services.

`kolla-ansible post-deploy -i INVENTORY` is used to do post deploy on deploy node to get the admin openrc file.

`kolla-ansible pull -i INVENTORY` is used to pull all images for containers.

`kolla-ansible reconfigure -i INVENTORY` is used to reconfigure OpenStack service.

`kolla-ansible upgrade -i INVENTORY` is used to upgrades existing OpenStack Environment.

`kolla-ansible stop -i INVENTORY` is used to stop running containers.

`kolla-ansible deploy-containers -i INVENTORY` is used to check and if necessary update containers, without generating configuration.

`kolla-ansible prune-images -i INVENTORY` is used to prune orphaned Docker images on hosts.

`kolla-ansible genconfig -i INVENTORY` is used to generate configuration files for enabled OpenStack services, without then restarting the containers so it is not applied right away.

`kolla-ansible validate-config -i INVENTORY` is used to validate generated configuration files of enabled OpenStack services. By default, the results are saved to /var/log/kolla/config-validate when issues are detected.

`kolla-ansible ... -i INVENTORY1 -i INVENTORY2` Multiple inventories can be specified by passing the --inventory or -i command line option multiple times. This can be useful to share configuration between multiple environments. Any common configuration can be set in INVENTORY1 and INVENTORY2 can be used to set environment specific details.

`kolla-ansible gather-facts -i INVENTORY` is used to gather Ansible facts, for example to populate a fact cache.