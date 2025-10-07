#!/usr/bin/env python3

import subprocess
import pydot
from typing import Dict, List


def get_terraform_graph(tf_dir: str) -> str:
    """Return terraform graph result."""
    result = subprocess.run(
        ["terraform", "graph"],
        cwd=tf_dir,
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout


def parse_terraform_graph(dot_output: str) -> Dict[str, List[str]]:
    """Extract dependency output between modules using pydot."""
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


def load_dependency_map(template_dir: str) -> Dict[str, List[str]]:
    """Generate dependency map by using terraform graph."""
    from pathlib import Path
    
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
        dot_output = get_terraform_graph(str(template_path))
        dependencies = parse_terraform_graph(dot_output)
        return dependencies
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to generate dependency graph: {e}")
        return {}


def validate_dependencies(
    selected_modules: Dict[str, Dict],
    dependency_map: Dict[str, List[str]]
) -> tuple[bool, List[str]]:
    """Make sure that all modules and its dependencies exist by comparing selected modules and the dependency map."""
    errors = []
    selected_names = set(selected_modules.keys())
    
    for module_name in selected_names:
        if module_name not in dependency_map:
            print(f"Warning: Module '{module_name}' not found in dependency map")
            continue
        
        required_deps = dependency_map[module_name]
        for dep in required_deps:
            if dep not in selected_names:
                error_msg = f"Module '{module_name}' requires '{dep}' to be selected"
                errors.append(error_msg)
    
    is_valid = len(errors) == 0
    return is_valid, errors

