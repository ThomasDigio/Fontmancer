import os
import subprocess
import shutil

def find_svn_command():
    # Check if svn is in the PATH
    if shutil.which("svn"):
        return "svn"
    
    # Check common SlikSVN installation paths
    possible_paths = [
        r"C:\Program Files\SlikSvn\bin\svn.exe",
        r"C:\Program Files (x86)\SlikSvn\bin\svn.exe"
    ]
    for path in possible_paths:
        if os.path.exists(path):
            return path
    return None

def main():
    # Ensure we are running in the script's directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    yaml_file = 'pkgmeta.yaml'
    if not os.path.exists(yaml_file):
        print(f"Error: {yaml_file} not found in {script_dir}")
        return

    print(f"Reading {yaml_file}...")
    
    externals = {}
    in_externals_section = False
    
    # Simple parser for the pkgmeta.yaml format
    with open(yaml_file, 'r') as f:
        for line in f:
            # Remove trailing newline
            raw_line = line.rstrip()
            stripped_line = raw_line.strip()
            
            if not stripped_line or stripped_line.startswith('#'):
                continue
            
            # Detect section headers (lines with no indentation)
            is_indented = raw_line.startswith(' ') or raw_line.startswith('\t')
            
            if not is_indented:
                if stripped_line == 'externals:':
                    in_externals_section = True
                    continue
                else:
                    in_externals_section = False
            
            # Parse entries within the externals section
            if in_externals_section and is_indented and ':' in stripped_line:
                path, url = stripped_line.split(':', 1)
                externals[path.strip()] = url.strip()

    if not externals:
        print("No externals found to install.")
        return

    svn_cmd = find_svn_command()
    if not svn_cmd:
        print("Error: 'svn' not found. Please ensure SlikSVN is installed and added to your PATH.")
        return

    print(f"Found {len(externals)} libraries. Starting installation with SlikSVN...")

    for path, url in externals.items():
        local_path = os.path.normpath(path)
        print(f"Processing {local_path}...")
        
        # If the folder exists and is an SVN repo, update it; otherwise checkout
        if os.path.exists(local_path) and os.path.isdir(os.path.join(local_path, '.svn')):
            subprocess.run([svn_cmd, 'update', local_path], shell=False)
        else:
            subprocess.run([svn_cmd, 'checkout', url, local_path], shell=False)

    print("Done.")

if __name__ == "__main__":
    main()
