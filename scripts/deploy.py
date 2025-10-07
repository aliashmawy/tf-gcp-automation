#!/usr/bin/env python3

import sys
import argparse
from pathlib import Path
from typing import Dict

# Import our organized modules
from terraform_utils import load_dependency_map, validate_dependencies
from config_loader import load_yaml_configs, extract_selected_modules
from project_generator import (
    generate_project_structure, 
    copy_and_filter_templates,
    run_terraform_init,
    run_terraform_plan
)

# Configuration constants
CONFIGS_DIR = "configs"
OUTPUT_DIR = "generated_projects"
TEMPLATE_DIR = "."

def process_project(
    config: Dict,
    dependency_map: Dict[str, list],
    output_dir: str,
    template_dir: str,
    overwrite: bool = False
) -> bool:
    """Process a single project configuration."""
    project_name = config.get('project_name', 'unnamed-project')
    
    selected_modules_dict = extract_selected_modules(config)
    
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
    
    print(f"Project '{project_name}' generated successfully")
    return True


def main():
    """Main function to orchestrate the deployment process."""
    parser = argparse.ArgumentParser(description='Generate Terraform projects from YAML configurations')
    parser.add_argument('--overwrite', action='store_true', help='Overwrite existing project directories')
    args = parser.parse_args()
    
    # Load YAML configurations
    configs = load_yaml_configs(CONFIGS_DIR)
    
    if not configs:
        print("Error: No configurations found. Exiting.")
        sys.exit(1)
    
    # Load dependency map from terraform graph
    dependency_map = load_dependency_map(TEMPLATE_DIR)
    
    if not dependency_map:
        print("Error: Failed to load dependency map from template. Exiting.")
        sys.exit(1)
    
    # Process each configuration
    results = []
    for config in configs:
        success = process_project(config, dependency_map, OUTPUT_DIR, TEMPLATE_DIR, args.overwrite)
        results.append((config.get('project_name', 'unknown'), success))
    
    # Print summary
    print(f"\n{'='*60}")
    print("GENERATION SUMMARY")
    print(f"{'='*60}")
    
    for project_name, success in results:
        status = "SUCCESS" if success else "FAILED"
        print(f"{project_name}: {status}")
    
    successful = sum(1 for _, success in results if success)
    print(f"\nTotal: {successful}/{len(results)} projects generated successfully")
    
    if successful < len(results):
        sys.exit(1)


if __name__ == "__main__":
    main()