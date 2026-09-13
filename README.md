# Real quick kolla-ansible :joy:

## Set up environment

```sh
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
kolla-ansible install-deps
```

Run Kolla-Ansible from a supported Linux deployment host. macOS is not a supported host operating system for Kolla-Ansible prechecks.

> [!TIP]
> To use any commands below you need to activate the virtual environment:
> 
> ```sh
> source .venv/bin/activate
> export KOLLA_CONFIG_PATH="$PWD/etc/kolla"
> ```

## Generate passwords and self-signed TLS certificates

Run this before deployment. It generates the test CA and certificates for the configured internal and external VIPs:

```sh
kolla-genpwd -p "$KOLLA_CONFIG_PATH/passwords.yml"
kolla-ansible certificates -i inventory.ini
```

## Deploy OpenStack

```sh
kolla-ansible bootstrap-servers -i inventory.ini
kolla-ansible prechecks         -i inventory.ini --use-test-images
kolla-ansible deploy            -i inventory.ini
kolla-ansible post-deploy       -i inventory.ini
```

The `post-deploy` command generates `etc/kolla/clouds.yaml` for the OpenStack client.

## Reconfigure OpenStack deployment

```sh
kolla-ansible reconfigure -i inventory.ini
```
