#!/usr/bin/env python3

import os
import sys
import subprocess
import yaml
import pydot
import re
from pathlib import Path
from typing import Dict, List, Tuple, Set


MODULES_DIR = "modules"
CONFIGS_DIR = "configs"
OUTPUT_DIR = "generated_projects"
TEMPLATE_DIR = "."
TEMPLATE_MAIN_TF = "main.tf"
TEMPLATE_VARIABLES_TF = "variables.tf"

#return terraform graph result
def get_terraform_graph(tf_dir):
    result = subprocess.run(
        ["terraform", "graph"],
        cwd=tf_dir,
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout

#Extract dependency output between modules using pydot
def parse_terraform_graph(dot_output):
    graphs = pydot.graph_from_dot_data(dot_output)
    graph = graphs[0]

    dependencies = {}

    for edge in graph.get_edges():
        src = edge.get_source().strip('"')
        dst = edge.get_destination().strip('"')

        if src.startswith("module.") and dst.startswith("module."):
            src_module = src.split('.')[1]
            dst_module = dst.split('.')[1]
            dependencies.setdefault(src_module, []).append(dst_module)

    for node in graph.get_nodes():
        name = node.get_name().strip('"')
        if name.startswith("module."):
            mod = name.split('.')[1]
            dependencies.setdefault(mod, [])

    for mod, deps in dependencies.items():
        unique_deps = sorted(set(d for d in deps if d != mod))
        dependencies[mod] = unique_deps

    return dependencies

#load all yaml files in config directory
def load_yaml_configs(config_dir: str) -> List[Dict]:
    configs = []
    config_path = Path(config_dir)
    
    if not config_path.exists():
        print(f"Error: Configuration directory '{config_dir}' does not exist")
        return configs
    
    yaml_files = list(config_path.glob("*.yaml")) + list(config_path.glob("*.yml"))
    
    if not yaml_files:
        print(f"Warning: No YAML files found in '{config_dir}'")
        return configs
    
    for yaml_file in yaml_files:
        try:
            with open(yaml_file, 'r') as f:
                config = yaml.safe_load(f)
                config['_source_file'] = yaml_file.name
                configs.append(config)
                print(f"Loaded configuration from '{yaml_file.name}'")
        except Exception as e:
            print(f"Error: Failed to load '{yaml_file.name}': {e}")
    
    return configs

#generate dependency map by using the first 2 functions above
def load_dependency_map(template_dir: str) -> Dict[str, List[str]]:
    print(f"Loading dependency map from template: {template_dir}")
    
    template_path = Path(template_dir)
    
    if not template_path.exists():
        print(f"Error: Template directory '{template_dir}' does not exist")
        return {}
    
    if not (template_path / "main.tf").exists():
        print(f"Error: No main.tf found in template directory '{template_dir}'")
        return {}
    
    if not (template_path / ".terraform").exists():
        print(f"Template not initialized. Running terraform init...")
        try:
            subprocess.run(
                ["terraform", "init"],
                cwd=template_path,
                capture_output=True,
                text=True,
                check=True
            )
            print("Template initialized successfully")
        except subprocess.CalledProcessError as e:
            print(f"Error: Failed to initialize template: {e.stderr}")
            return {}
    
    try:
        print("Generating dependency graph from template...")
        dot_output = get_terraform_graph(str(template_path))
        dependencies = parse_terraform_graph(dot_output)
        print(f"Dependency map loaded: {dependencies}")
        return dependencies
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to generate dependency graph: {e}")
        return {}

#Make sure that all modules and its dependencies exist by comparing selected modules and the dependency map
def validate_dependencies(
    selected_modules: Dict[str, Dict],
    dependency_map: Dict[str, List[str]]
) -> Tuple[bool, List[str]]:
    errors = []
    selected_names = set(selected_modules.keys())
    
    for module_name in selected_names:
        #continue if a module name in yaml is not found in the dependency map (doesn't exist in the template)
        if module_name not in dependency_map:
            print(f"Warning: Module '{module_name}' not found in dependency map")
            continue
        
        required_deps = dependency_map[module_name]
        #loop through dependecies of the module_name itself
        for dep in required_deps:
            if dep not in selected_names:
                error_msg = f"Module '{module_name}' requires '{dep}' to be selected"
                errors.append(error_msg)
    
    is_valid = len(errors) == 0
    return is_valid, errors


def filter_main_tf(template_path: Path, selected_modules: Set[str]) -> str:
    with open(template_path, 'r') as f:
        content = f.read()
    
    filtered_lines = []
    lines = content.split('\n')
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        if stripped.startswith('module "'):
            match = re.match(r'module\s+"([^"]+)"', stripped)
            if match:
                module_name = match.group(1)
                
                block_lines = [line]
                brace_count = line.count('{') - line.count('}')
                i += 1
                
                while i < len(lines) and brace_count > 0:
                    current_line = lines[i]
                    
                    if 'source' in current_line and './modules/' in current_line:
                        current_line = current_line.replace('./modules/', '../../modules/')
                    
                    block_lines.append(current_line)
                    brace_count += current_line.count('{') - current_line.count('}')
                    i += 1
                
                if module_name in selected_modules:
                    filtered_lines.extend(block_lines)
                    filtered_lines.append('')
                
                continue
        
        filtered_lines.append(line)
        i += 1
    
    result = []
    prev_blank = False
    for line in filtered_lines:
        is_blank = line.strip() == ''
        if not (is_blank and prev_blank):
            result.append(line)
        prev_blank = is_blank
    
    return '\n'.join(result)


def filter_variables_tf(template_path: Path, selected_modules: Set[str], module_configs: Dict[str, Dict]) -> str:
    with open(template_path, 'r') as f:
        content = f.read()
    
    needed_vars = set()
    needed_vars.update(['project_id', 'region', 'project_name'])
    
    for module_name, config in module_configs.items():
        if module_name in selected_modules:
            for var_name in config.keys():
                if var_name != 'selected':
                    needed_vars.add(var_name)
    
    filtered_lines = []
    lines = content.split('\n')
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        if stripped.startswith('variable "'):
            match = re.match(r'variable\s+"([^"]+)"', stripped)
            if match:
                var_name = match.group(1)
                
                block_lines = [line]
                brace_count = line.count('{') - line.count('}')
                i += 1
                
                while i < len(lines) and brace_count > 0:
                    block_lines.append(lines[i])
                    brace_count += lines[i].count('{') - lines[i].count('}')
                    i += 1
                
                if var_name in needed_vars:
                    filtered_lines.extend(block_lines)
                    filtered_lines.append('')
                
                continue
        
        if not stripped.startswith('variable '):
            filtered_lines.append(line)
        i += 1
    
    result = []
    prev_blank = False
    for line in filtered_lines:
        is_blank = line.strip() == ''
        if not (is_blank and prev_blank):
            result.append(line)
        prev_blank = is_blank
    
    return '\n'.join(result)


def format_tfvars_value(value) -> str:
    if isinstance(value, bool):
        return str(value).lower()
    elif isinstance(value, str):
        return f'"{value}"'
    elif isinstance(value, (int, float)):
        return str(value)
    elif isinstance(value, list):
        items = [format_tfvars_value(item) for item in value]
        return '[' + ', '.join(items) + ']'
    elif isinstance(value, dict):
        items = [f'{k} = {format_tfvars_value(v)}' for k, v in value.items()]
        return '{\n  ' + '\n  '.join(items) + '\n}'
    else:
        return str(value)


def generate_tfvars(selected_modules: Dict[str, Dict]) -> str:
    lines = []
    
    all_vars = {}
    for module_name, module_config in selected_modules.items():
        for var_name, var_value in module_config.items():
            if var_name != 'selected':
                all_vars[var_name] = var_value
    
    for var_name, var_value in sorted(all_vars.items()):
        lines.append(f'{var_name} = {format_tfvars_value(var_value)}')
    
    return '\n'.join(lines)


def generate_project_structure(project_name: str, output_dir: str, overwrite: bool = False) -> Path:
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


def process_project(
    config: Dict,
    dependency_map: Dict[str, List[str]],
    output_dir: str,
    template_dir: str,
    overwrite: bool = False
) -> bool:
    project_name = config.get('project_name', 'unnamed-project')
    print(f"\n{'='*60}")
    print(f"Processing project: {project_name}")
    print(f"{'='*60}")
    
    modules_config = config.get('modules', {})
    selected_modules_dict = {
        name: {k: v for k, v in mod_config.items() if k != 'selected'}
        for name, mod_config in modules_config.items()
        if mod_config.get('selected', False)
    }
    
    if not selected_modules_dict:
        print(f"Warning: No modules selected for project '{project_name}'. Skipping.")
        return False
    
    selected_modules_set = set(selected_modules_dict.keys())
    print(f"Selected modules: {list(selected_modules_set)}")
    
    is_valid, errors = validate_dependencies(selected_modules_dict, dependency_map)
    
    if not is_valid:
        print(f"Error: Dependency validation failed for '{project_name}':")
        for error in errors:
            print(f"  - {error}")
        return False
    
    print("Dependency validation passed")
    
    project_path = generate_project_structure(project_name, output_dir, overwrite)
    
    if project_path is None:
        print(f"Error: Failed to create project directory for '{project_name}'")
        return False
    
    copy_and_filter_templates(
        project_path,
        Path(template_dir),
        selected_modules_set,
        selected_modules_dict
    )
    
    if not run_terraform_init(project_path):
        print(f"Error: Failed to initialize Terraform for '{project_name}'")
        return False
    
    if not run_terraform_plan(project_path):
        print(f"Error: Terraform plan failed for '{project_name}'")
        return False
    
    print(f"Project '{project_name}' generated successfully ✓")
    return True


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate Terraform projects from YAML configurations')
    parser.add_argument('--overwrite', action='store_true', help='Overwrite existing project directories')
    args = parser.parse_args()
    
    print("Starting Terraform Project Generator")
    print(f"Template directory: {TEMPLATE_DIR}")
    print(f"Configs directory: {CONFIGS_DIR}")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"Overwrite mode: {'ENABLED' if args.overwrite else 'DISABLED'}")
    
    configs = load_yaml_configs(CONFIGS_DIR)
    
    if not configs:
        print("Error: No configurations found. Exiting.")
        sys.exit(1)
    
    print(f"Found {len(configs)} configuration(s)")
    
    dependency_map = load_dependency_map(TEMPLATE_DIR)
    
    if not dependency_map:
        print("Error: Failed to load dependency map from template. Exiting.")
        sys.exit(1)
    
    results = []
    for config in configs:
        success = process_project(config, dependency_map, OUTPUT_DIR, TEMPLATE_DIR, args.overwrite)
        results.append((config.get('project_name', 'unknown'), success))
    
    print(f"\n{'='*60}")
    print("GENERATION SUMMARY")
    print(f"{'='*60}")
    
    for project_name, success in results:
        status = "✓ SUCCESS" if success else "✗ FAILED"
        print(f"{project_name}: {status}")
    
    successful = sum(1 for _, success in results if success)
    print(f"\nTotal: {successful}/{len(results)} projects generated successfully")
    
    if successful < len(results):
        sys.exit(1)


if __name__ == "__main__":
    main()