#!/usr/bin/env python3
"""
Add template synchronization fields to Langflow's Flow model.
This script patches the installed Langflow package to add EnGarde template fields.
"""

import os
import sys

def add_template_fields_to_model():
    """Add template fields to Flow model SQLAlchemy definition"""

    # Find Langflow installation path
    import langflow
    langflow_path = os.path.dirname(langflow.__file__)
    flow_model_path = os.path.join(langflow_path, "services", "database", "models", "flow", "model.py")

    if not os.path.exists(flow_model_path):
        print(f"ERROR: Flow model not found at {flow_model_path}")
        sys.exit(1)

    print(f"Found Flow model at: {flow_model_path}")

    # Read the file
    with open(flow_model_path, 'r') as f:
        content = f.read()

    # Check if fields already exist
    if 'is_admin_template' in content:
        print("✓ Template fields already exist, skipping")
        return

    # Find the location to add fields (after existing fields, before relationships)
    # Look for a good insertion point - typically after basic fields

    template_fields = '''
    # EnGarde Template Synchronization Fields
    is_admin_template = Column(Boolean, default=False, nullable=False, index=True)
    template_source_id = Column(UUID(as_uuid=True), nullable=True, index=True)
    template_version = Column(String, nullable=True)
    custom_settings = Column(JSON, nullable=True)
    last_synced_at = Column(DateTime(timezone=True), nullable=True)
'''

    # Find insertion point after the last Column definition before relationships
    # Look for patterns like "folder_id = Column" or similar

    import re

    # Find the last Column definition before relationships or class end
    # We'll insert before the first relationship definition or __table_args__
    insertion_markers = [
        'folder_id = Column',
        '__table_args__',
        'folder: Mapped',
        'user: Mapped',
    ]

    insertion_point = -1
    for marker in insertion_markers:
        pos = content.find(marker)
        if pos != -1:
            insertion_point = pos
            break

    if insertion_point == -1:
        print("ERROR: Could not find suitable insertion point")
        sys.exit(1)

    # Insert the template fields
    modified_content = content[:insertion_point] + template_fields + '\n    ' + content[insertion_point:]

    # Write back
    with open(flow_model_path, 'w') as f:
        f.write(modified_content)

    print("✓ Added template fields to Flow model")
    print("  - is_admin_template")
    print("  - template_source_id")
    print("  - template_version")
    print("  - custom_settings")
    print("  - last_synced_at")

def main():
    try:
        print("="*60)
        print("Adding EnGarde Template Fields to Langflow Flow Model")
        print("="*60)

        add_template_fields_to_model()

        print("\n✅ Template fields added successfully!")
        print("\nNote: Database migration will be needed to create these columns.")
        print("Run: alembic revision --autogenerate -m 'add_template_fields'")

    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
