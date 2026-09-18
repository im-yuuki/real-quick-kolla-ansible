_kolla_ansible()
{
  local cur prev words
  COMPREPLY=()
  _get_comp_words_by_ref -n : cur prev words

  # Command data:
  cmds='bootstrap-servers certificates check complete deploy deploy-bifrost deploy-containers deploy-servers destroy gather-facts genconfig help install-deps mariadb-backup mariadb-recovery migrate-container-engine nova-libvirt-cleanup octavia-certificates post-deploy prechecks prune-images pull rabbitmq-reset-state reconfigure stop upgrade upgrade-bifrost validate-config'
  cmds_bootstrap_servers='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_certificates='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_check='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_complete='-h --help --name --shell'
  cmds_deploy='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_deploy_bifrost='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_deploy_containers='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_deploy_servers='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_destroy='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords --yes-i-really-really-mean-it --include-dev --include-images'
  cmds_gather_facts='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_genconfig='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_help='-h --help'
  cmds_install_deps='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_mariadb_backup='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords --full --incremental'
  cmds_mariadb_recovery='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_migrate_container_engine='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_nova_libvirt_cleanup='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_octavia_certificates='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords --check-expiry'
  cmds_post_deploy='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_prechecks='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords --use-test-images'
  cmds_prune_images='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords --yes-i-really-really-mean-it'
  cmds_pull='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_rabbitmq_reset_state='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_reconfigure='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_stop='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords --yes-i-really-really-mean-it --ignore-missing'
  cmds_upgrade='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_upgrade_bifrost='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'
  cmds_validate_config='-h --help -b --become -C --check -D --diff -e --extra-vars -i --inventory -l --limit --skip-tags -t --tags -lt --list-tasks -p --playbook --vault-id --vault-password-file --vault-pass-file -J --ask-vault-password --ask-vault-pass --configdir --passwords'

  dash=-
  underscore=_
  cmd=""
  words[0]=""
  completed="${cmds}"
  for var in "${words[@]:1}"
  do
    if [[ ${var} == -* ]] ; then
      break
    fi
    if [ -z "${cmd}" ] ; then
      proposed="${var}"
    else
      proposed="${cmd}_${var}"
    fi
    local i="cmds_${proposed}"
    i=${i//$dash/$underscore}
    local comp="${!i}"
    if [ -z "${comp}" ] ; then
      break
    fi
    if [[ ${comp} == -* ]] ; then
      if [[ ${cur} != -* ]] ; then
        completed=""
        break
      fi
    fi
    cmd="${proposed}"
    completed="${comp}"
  done

  if [ -z "${completed}" ] ; then
    COMPREPLY=( $( compgen -f -- "$cur" ) $( compgen -d -- "$cur" ) )
  else
    COMPREPLY=( $(compgen -W "${completed}" -- ${cur}) )
  fi
  return 0
}
complete -F _kolla_ansible kolla-ansible
