######### git config ###############

existing_name := `git config --global --default none user.name`
existing_email := `git config --global --default none user.email`

[private]
default:
  just -f {{justfile()}} --list

[script("uv", "run", "--script")]
set_name name force="False":
  import sys
  from subprocess import run
  if force.lower() in ["false", "f", "no", "n"] and {{ existing_name }} != "none":
    sys.exit("user.name already set. Use 'force=True' to override.")
  run(["git", "config", "--global" "user.name", {{name}}], check=True)

[script("uv", "run", "--script")]
set_email email force="False":
  import sys
  from subprocess import run
  if force.lower() in ["false", "f", "no", "n"] and {{ existing_email }} != "none":
    sys.exit("user.email already set. Use 'force=True' to override.")
  run(["git", "config", "--global" "user.email", email], check=True)


