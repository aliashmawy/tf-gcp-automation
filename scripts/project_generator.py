#!/usr/bin/env python3

import subprocess
from pathlib import Path
from typing import Dict, Set

from template_processor import filter_main_tf, filter_variables_tf, generate_tfvars


def generate_project_structure(project_name: str, output_dir: str, overwrite: bool = False) -> Path:
    """Generate project directory structure."""
    project_path = Path(output_dir) / project_name
    
    if project_path.exists():
        if not overwrite:
            print(f"Error: Project directory '{project_path}' already exists!")
            print(f"Use --overwrite flag to overwrite existing projects")
            return None
        else:
            print(f"Warning: Project directory '{project_path}' already exists. Overwriting...")
    
    project_path.mkdir(parents=True, exist_ok=True)
    print(f"Created project directory: {project_path}")
    return project_path


def copy_and_filter_templates(
    project_path: Path,
    template_dir: Path,
    selected_modules: Set[str],
    module_configs: Dict[str, Dict]
) -> None:
    """Copy and filter template files for the project."""
    TEMPLATE_MAIN_TF = "main.tf"
    TEMPLATE_VARIABLES_TF = "variables.tf"
    
    main_tf_template = template_dir / TEMPLATE_MAIN_TF
    if main_tf_template.exists():
        filtered_main = filter_main_tf(main_tf_template, selected_modules)
        with open(project_path / "main.tf", 'w') as f:
            f.write(filtered_main)
        print(f"Generated main.tf with {len(selected_modules)} modules")
    else:
        print(f"Error: Template file {TEMPLATE_MAIN_TF} not found")
        return
    
    variables_tf_template = template_dir / TEMPLATE_VARIABLES_TF
    if variables_tf_template.exists():
        filtered_vars = filter_variables_tf(variables_tf_template, selected_modules, module_configs)
        with open(project_path / "variables.tf", 'w') as f:
            f.write(filtered_vars)
        print(f"Generated variables.tf")
    else:
        print(f"Error: Template file {TEMPLATE_VARIABLES_TF} not found")
        return
    
    tfvars_content = generate_tfvars(module_configs)
    with open(project_path / "terraform.tfvars", 'w') as f:
        f.write(tfvars_content)
    print(f"Generated terraform.tfvars")


def run_terraform_init(project_dir: Path) -> bool:
    """Run terraform init in project directory."""
    print(f"Running terraform init in '{project_dir}'...")
    
    try:
        subprocess.run(
            ["terraform", "init"],
            cwd=project_dir,
            capture_output=True,
            text=True,
            check=True
        )
        print("Terraform init completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error: Terraform init failed: {e.stderr}")
        return False


def run_terraform_plan(project_dir: Path) -> bool:
    """Run terraform plan in project directory."""
    print(f"Running terraform plan in '{project_dir}'...")
    
    try:
        result = subprocess.run(
            ["terraform", "plan", "-no-color"],
            cwd=project_dir,
            capture_output=True,
            text=True,
            check=True
        )
        
        plan_file = project_dir / "plan.txt"
        with open(plan_file, 'w') as f:
            f.write(result.stdout)
        
        print(f"Terraform plan completed and saved to '{plan_file}'")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error: Terraform plan failed: {e.stderr}")
        
        plan_file = project_dir / "plan.txt"
        with open(plan_file, 'w') as f:
            f.write(f"PLAN FAILED\n\n{e.stderr}\n\n{e.stdout}")
        
        return False
