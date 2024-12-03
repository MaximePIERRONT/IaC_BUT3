[defaults]
host_key_checking = False
inventory = gcp_compute.yml
interpreter_python = auto_silent
remote_user = ${replace(replace(remote_user, ".", "_"), "@", "_")}

[inventory]
enable_plugins = gcp_compute, auto, host_list, yaml, ini, toml, script