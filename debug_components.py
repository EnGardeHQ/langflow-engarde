
import os
import sys
import glob

print(f"Python version: {sys.version}")
print(f"Current Directory: {os.getcwd()}")
print("Listing /app/custom_components recursively:")

for root, dirs, files in os.walk("/app/custom_components"):
    level = root.replace("/app/custom_components", "").count(os.sep)
    indent = " " * 4 * (level)
    print(f"{indent}{os.path.basename(root)}/")
    subindent = " " * 4 * (level + 1)
    for f in files:
        print(f"{subindent}{f}")

print("\nChecking httpx dependency:")
try:
    import httpx
    print(f"✅ httpx is installed: {httpx.__version__}")
except ImportError:
    print("❌ httpx is NOT installed")

print("\nChecking loading modules:")
try:
    sys.path.append("/app/custom_components")
    import engarde_agents
    print("✅ Successfully imported engarde_agents package")
    import walker_agents
    print("✅ Successfully imported walker_agents package")
except Exception as e:
    print(f"❌ Error importing packages: {e}")
