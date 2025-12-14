import os
import re
import shutil

root_dir = "/Users/m.li/Documents/_testp/NihonRyokou/image"

def get_scale_suffix(filename):
    if "57" in filename:
        return ""
    elif "60" in filename:
        return "-2x"
    elif "76" in filename:
        return "-3x"
    return None

def main():
    dirs = [d for d in os.listdir(root_dir) if os.path.isdir(os.path.join(root_dir, d))]
    
    web_dirs = []
    for d in dirs:
        if d == "web":
            web_dirs.append((1, d))
        elif d.startswith("web "):
            try:
                num = int(d.split()[1])
                web_dirs.append((num, d))
            except ValueError:
                pass
        # Handle "web2", "web10" without space if they exist (though listing showed spaces)
        elif d.startswith("web") and d[3:].isdigit():
             num = int(d[3:])
             web_dirs.append((num, d))

    web_dirs.sort(key=lambda x: x[0])
    
    print(f"Found {len(web_dirs)} web directories.")
    
    for index, dirname in web_dirs:
        dir_path = os.path.join(root_dir, dirname)
        files = [f for f in os.listdir(dir_path) if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        
        # Sort files to ensure stable processing if needed, but we rely on content
        # Check if we have the expected 57/60/76
        categorized = {}
        uncategorized = []
        
        for f in files:
            suffix = get_scale_suffix(f)
            if suffix is not None:
                categorized[suffix] = f
            else:
                uncategorized.append(f)
        
        # If we didn't find specific numbers, fall back to size sorting
        if len(categorized) < 3 and len(uncategorized) + len(categorized) == 3:
             print(f"Directory {dirname} missing scale indicators. Sorting by size.")
             all_files_full = [(f, os.path.getsize(os.path.join(dir_path, f))) for f in files]
             all_files_full.sort(key=lambda x: x[1]) # Sort by size ascending
             
             # Smallest -> 1x, Mid -> 2x, Largest -> 3x
             if len(all_files_full) == 3:
                 categorized[""] = all_files_full[0][0]
                 categorized["-2x"] = all_files_full[1][0]
                 categorized["-3x"] = all_files_full[2][0]
        
        # Rename
        base_name = f"schedule-{index}"
        
        for suffix, old_name in categorized.items():
            new_name = f"{base_name}{suffix}.png" # Assuming png
            old_path = os.path.join(dir_path, old_name)
            new_path = os.path.join(dir_path, new_name)
            
            # Skip if already renamed
            if old_name == new_name:
                continue
                
            print(f"Renaming {dirname}/{old_name} -> {new_name}")
            os.rename(old_path, new_path)

if __name__ == "__main__":
    main()
