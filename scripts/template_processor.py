#!/usr/bin/env python3

import re
from pathlib import Path
from typing import Dict, Set


def filter_main_tf(template_path: Path, selected_modules: Set[str]) -> str:
    """Filter main.tf template to include only selected modules."""
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
    """Filter variables.tf template to include only needed variables."""
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
    """Format a value for terraform.tfvars file."""
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
    """Generate terraform.tfvars content from selected modules."""
    lines = []
    
    all_vars = {}
    for module_name, module_config in selected_modules.items():
        for var_name, var_value in module_config.items():
            if var_name != 'selected':
                all_vars[var_name] = var_value
    
    for var_name, var_value in sorted(all_vars.items()):
        lines.append(f'{var_name} = {format_tfvars_value(var_value)}')
    
    return '\n'.join(lines)

