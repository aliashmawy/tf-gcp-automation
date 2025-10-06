import sys
import yaml
import os

yaml_file = sys.argv[1]
with open(yaml_file) as f:
    config = yaml.safe_load(f)

tfvars_path = os.path.join(os.path.dirname(yaml_file), "config.tfvars")
with open(tfvars_path, "w") as f:
    for k, v in config.items():
        if isinstance(v, str):
            f.write(f'{k} = "{v}"\n')
        elif isinstance(v, list):
            f.write(f'{k} = {v}\n')
        elif isinstance(v, dict):
            f.write(f'{k} = {{')
            f.write(", ".join(f'{kk} = "{vv}"' for kk, vv in v.items()))
            f.write("}\n")

os.system(f"terraform init")
os.system(f"terraform apply -var-file={tfvars_path} -auto-approve")
