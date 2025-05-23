"""
Script to run the create_tags.py file without using input redirection.
This helps avoid encoding issues in PowerShell.
"""

import os
import sys
import importlib.util

# Get the absolute path to the create_tags.py script
script_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'create_tags.py')

# Load the script as a module
spec = importlib.util.spec_from_file_location("create_tags", script_path)
create_tags_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(create_tags_module)

# Run the create_tags function from the loaded module
if hasattr(create_tags_module, 'create_tags'):
    create_tags_module.create_tags()
else:
    print("Error: create_tags function not found in the module")
