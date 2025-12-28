
import os
import datetime

def force_refresh_files(root_dir):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    count = 0
    errors = 0
    
    print(f"Starting force refresh for {root_dir}")
    print(f"Timestamp: {timestamp}")
    
    for subdir, dirs, files in os.walk(root_dir):
        # Skip pycache
        if "__pycache__" in subdir:
            continue
            
        for file in files:
            if file.endswith(".py"):
                filepath = os.path.join(subdir, file)
                try:
                    with open(filepath, "r") as f:
                        content = f.read()
                    
                    # Check if file ends with newline
                    if not content.endswith("\n"):
                        content += "\n"
                        
                    # Append comment
                    refresh_comment = f"\n# Force refresh: {timestamp}\n"
                    
                    # Write back
                    with open(filepath, "w") as f:
                        f.write(content + refresh_comment)
                        
                    count += 1
                    # print(f"Updated {filepath}")
                    
                except Exception as e:
                    print(f"Error updating {filepath}: {e}")
                    errors += 1
                    
    print(f"Completed. Updated {count} files with {errors} errors.")

if __name__ == "__main__":
    force_refresh_files("production-backend/app")
