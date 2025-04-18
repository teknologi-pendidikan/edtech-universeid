import os

# Define folders you want to include
INCLUDE_FOLDERS = ["data", "scripts", "docs", "utils"]

def generate_tree(base_path, prefix=""):
    tree = ""
    try:
        entries = sorted(os.listdir(base_path))
        for index, entry in enumerate(entries):
            full_path = os.path.join(base_path, entry)
            connector = "└── " if index == len(entries) - 1 else "├── "
            if os.path.isdir(full_path):
                tree += f"{prefix}{connector}**{entry}/**\n"
                extension = "    " if index == len(entries) - 1 else "│   "
                tree += generate_tree(full_path, prefix + extension)
            else:
                tree += f"{prefix}{connector}{entry}\n"
    except PermissionError:
        pass  # skip directories you can't access
    return tree

def list_directories(base_path="."):
    result = ["# Repository Structure\n"]
    for folder in sorted(INCLUDE_FOLDERS):
        path = os.path.join(base_path, folder)
        if os.path.isdir(path):
            result.append(f"## `{folder}/`")
            result.append("```")
            result.append(generate_tree(path))
            result.append("```")
    return "\n".join(result)

if __name__ == "__main__":
    directory_md = list_directories()
    with open("DIRECTORY.md", "w", encoding="utf-8") as f:
        f.write(directory_md)
