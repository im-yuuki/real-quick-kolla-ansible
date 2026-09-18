# Real quick kolla-ansible :joy:

## Set up environment

### Install kolla-ansible and dependencies

```sh
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
kolla-ansible install-deps
```

### Create configuration files from templates

Required:
```sh
mkdir kolla
cp .venv/share/kolla-ansible/etc_examples/kolla/globals.yml   kolla/globals.yml
cp .venv/share/kolla-ansible/etc_examples/kolla/passwords.yml kolla/passwords.yml
kolla-genpwd -p "$PWD/kolla/passwords.yml"
```

If using all-in-one node:
```sh
cp .venv/share/kolla-ansible/ansible/inventory/all-in-one inventory.ini
```

If using multinode:
```sh
cp .venv/share/kolla-ansible/ansible/inventory/multinode inventory.ini
```

Check my `examples/globals.yml` for a minimal configuration.

## Deploy OpenStack

> [!TIP]
> To use any functions below you need to activate the virtual environment:
> 
> ```sh
> source .venv/bin/activate
> export KOLLA_CONFIG_PATH="$PWD/kolla"
> ```

### Bootstrap

Run this before deployment. It generates the test CA and certificates for the configured internal and external VIPs:

```sh
kolla-ansible certificates      -i inventory.ini
kolla-ansible bootstrap-servers -i inventory.ini
```

### Prechecks

```sh
kolla-ansible prechecks -i inventory.ini --use-test-images
```

### Deploy

```sh
kolla-ansible deploy      -i inventory.ini
kolla-ansible post-deploy -i inventory.ini
```

The `post-deploy` command generates `kolla/clouds.yaml` for the OpenStack client.

### Validate configurations of enabled services

```sh
kolla-ansible validate-config -i inventory.ini
```

### Reconfigure

```sh
kolla-ansible reconfigure -i inventory.ini
kolla-ansible deploy      -i inventory.ini
```

### Upgrade

```sh
kolla-ansible pull      -i inventory.ini
kolla-ansible prechecks -i inventory.ini
kolla-ansible upgrade   -i inventory.ini
```