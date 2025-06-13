############### ssh keys ###########

key_protocol := "ed25519"

[private]
default:
  just -f {{ justfile() }} --list

# do this first
create_ssh_key username keyname:
  ssh-keygen -q -t {{key_protocol}} -C {{keyname}} -f ~/.ssh/id_{{key_protocol}}_{{keyname}} -N ""

[private, script("uv", "run", "--script")]
add_ssh_key_to_config username host keyname:
  # /// script
  # requires-python = ">=3.11"
  # dependencies = ["sshconf>=0.2.7"]
  # ///
  from pathlib import Path
  from subprocess import run
  from sshconf import empty_ssh_config_file, read_ssh_config
  key_path = Path.home() / f".ssh/id_{{key_protocol}}_{{keyname}}"
  config_path = Path.home() / ".ssh/config"
  config = (
    read_ssh_config(config_path) if config_path.exists() else empty_ssh_config_file()
  )
  options: dict[str, str] {"User" : {{username}}, "HostName" : "{{host}}", "IdentityFile" : str(key_path)
  func = (
    config.set if options["HostName"] in config.hosts() else config.add
  )
  func(options["HostName"], **options)
  config.write(config_path)

send_ssh_key_to_hpc username keyname: (add_ssh_key_to_config (username) (username+".hpc.einsteinmed.edu") keyname)
  ssh-copy-id -i ~/.ssh/id_{{key_protocol}}_{{keyname}}.pub {{username}}@{{username}}.hpc.einsteinmed.edu

send_ssh_key_to_gh keyname: (add_ssh_key_to_config "git" "git@github.com" keyname)
  gh auth login -p ssh -h github.com -w

