import os
import shutil
import json

source_base = "/Users/m.li/Documents/_testp/NihonRyokou/image"
target_base = "/Users/m.li/Documents/_testp/NihonRyokou/NihonRyokou/Assets.xcassets/schedule"

def create_imageset(index):
    folder_name = f"schedule-{index}.imageset"
    target_dir = os.path.join(target_base, folder_name)
    
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)

    # Locate source files
    # The source folders are named "web", "web 2", ... "web 22"
    # User said "web~web22". Based on previous listing: "web", "web 2", "web 3", ...
    # But files are ALREADY RENAMED.
    # Where are the renamed files? They are still in "image/web X/".
    
    source_folder_name = "web" if index == 1 else f"web {index}"
    # Check if folder exists with or without space if fallback needed
    source_dir = os.path.join(source_base, source_folder_name)
    if not os.path.exists(source_dir):
        # try without space
        source_dir = os.path.join(source_base, f"web{index}")
    
    if not os.path.exists(source_dir):
        print(f"Source dir not found for index {index}")
        return

    # Files to move
    base_filename = f"schedule-{index}"
    files = [
        (f"{base_filename}.png", "1x"),
        (f"{base_filename}-2x.png", "2x"),
        (f"{base_filename}-3x.png", "3x")
    ]
    
    images_json = []
    
    for filename, scale in files:
        src = os.path.join(source_dir, filename)
        dst = os.path.join(target_dir, filename)
        
        if os.path.exists(src):
            print(f"Moving {src} -> {dst}")
            shutil.move(src, dst)
            images_json.append({
                "filename": filename,
                "idiom": "universal",
                "scale": scale
            })
        else:
            print(f"Warning: File {src} not found.")

    # Write Contents.json
    contents = {
        "images": images_json,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    with open(os.path.join(target_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

def main():
    # User asked for remaining ones (1-5 done). So 6 to 22.
    for i in range(6, 23):
        create_imageset(i)

if __name__ == "__main__":
    main()
