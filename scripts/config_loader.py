#!/usr/bin/env python3

import yaml
from pathlib import Path
from typing import Dict, List


def load_yaml_configs(config_dir: str) -> List[Dict]:
    """Load all yaml files in config directory."""
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


def extract_selected_modules(config: Dict) -> Dict[str, Dict]:
    """Extract selected modules from a config."""
    project_name = config.get('project_name', 'unnamed-project')
    
    modules_config = config.get('modules', {})
    selected_modules_dict = {
        name: {k: v for k, v in mod_config.items() if k != 'selected'}
        for name, mod_config in modules_config.items()
        if mod_config.get('selected', False)
    }
    
    return selected_modules_dict

