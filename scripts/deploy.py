import subprocess
import pydot


def get_terraform_graph(tf_dir):

    result = subprocess.run(
        ["terraform", "graph"],
        cwd=tf_dir,
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout


import pydot

def parse_terraform_graph(dot_output):

    graphs = pydot.graph_from_dot_data(dot_output)
    graph = graphs[0]

    dependencies = {}

    # Build dependency graph from edges
    for edge in graph.get_edges():
        src = edge.get_source().strip('"')
        dst = edge.get_destination().strip('"')

        # Only consider module-to-module edges
        if src.startswith("module.") and dst.startswith("module."):
            src_module = src.split('.')[1]
            dst_module = dst.split('.')[1]
            dependencies.setdefault(src_module, []).append(dst_module)

    # Ensure every module appears (even if it has no dependencies)
    for node in graph.get_nodes():
        name = node.get_name().strip('"')
        if name.startswith("module."):
            mod = name.split('.')[1]
            dependencies.setdefault(mod, [])

    # Clean duplicates and remove self-dependencies
    for mod, deps in dependencies.items():
        unique_deps = sorted(set(d for d in deps if d != mod))
        dependencies[mod] = unique_deps

    return dependencies




if __name__ == "__main__":
    tf_dir = "./"
    dot_output = get_terraform_graph(tf_dir)
    deps = parse_terraform_graph(dot_output)

    print("\n########### Module Dependency Map ###########")
    for mod, deps_list in deps.items():
        print(f"{mod} → {deps_list}")
