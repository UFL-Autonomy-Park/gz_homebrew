# PX4_DIR = /something


# create 2222_gz_homebrew
# add that file to CMAKELIST

# cp src/folders to PX4 dir in appropriate place
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# CONFIGURATION
# ==========================================
# Target Directory B (can be an absolute path or relative path)
px4_dir="/PX4-Autopilot" #in home directory

# Items in Directory A to be copied
homebrew_script="./src/22222_gz_homebrew"
x500tb_script="./src/22333_gz_x500_tbst"
gnvsdf_script="./src/gainesville.sdf"

custom_model_dir="./src"

# Target subdirectories inside Directory B
ROMFS="./ROMFS/px4fmu_common/init.d-posix/airframes"
gz_model_dir="./Tools/simulation/gz/models"
gz_world_dir="./Tools/simulation/gz/worlds"

# Name of the CMakeLists file
CMAKE_FILE="CMakeLists.txt"

# ==========================================
# EXECUTION
# ==========================================

# 1. Resolve absolute paths to prevent path mismatch errors
DIR_A="$(pwd)"
DIR_B_ABS="$HOME$px4_dir"

echo "Starting deployment from $DIR_A to $DIR_B_ABS..."

# Ensure target directories exist inside PX4-Autopilot
mkdir -p "$DIR_B_ABS/$ROMFS"
mkdir -p "$DIR_B_ABS/$gz_model_dir"
mkdir -p "$DIR_B_ABS/$gz_world_dir"

# 2. Copy Airframe scripts to ROMFS (with existence check) and register them
TARGET_CMAKE="$DIR_B_ABS/$ROMFS/$CMAKE_FILE"

for script in "$homebrew_script" "$x500tb_script"; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        TARGET_FILE="$DIR_B_ABS/$ROMFS/$script_name"

        # CHECK: Does the script already exist in the target directory?
        if [ -f "$TARGET_FILE" ]; then
            echo "Skipping copy: $script_name already exists in $ROMFS/"
        else
            cp "$script" "$DIR_B_ABS/$ROMFS/"
            echo "Successfully copied $script_name to $ROMFS/"
        fi

        # Check if it's already in CMakeLists.txt to prevent duplicate entries
        if ! grep -q "$script_name" "$TARGET_CMAKE" 2>/dev/null; then
            sed -i "/^[[:space:]]*)/i \	$script_name" "$TARGET_CMAKE"
            echo "Added $script_name to $CMAKE_FILE"
        else
            echo "$script_name already registered in $CMAKE_FILE."
        fi
    else
        echo "Error: Airframe script $script does not exist in Directory A." >&2
        exit 1
    fi
done

# 3. Copy the Gainesville world file (with existence check)
if [ -f "$gnvsdf_script" ]; then
    world_name=$(basename "$gnvsdf_script")
    TARGET_WORLD="$DIR_B_ABS/$gz_world_dir/$world_name"

    # CHECK: Does the world file already exist in the target directory?
    if [ -f "$TARGET_WORLD" ]; then
        echo "Skipping copy: $world_name already exists in $gz_world_dir/"
    else
        cp "$gnvsdf_script" "$DIR_B_ABS/$gz_world_dir/"
        echo "Successfully copied $world_name to $gz_world_dir/"
    fi
else
    echo "Error: World file $gnvsdf_script does not exist in Directory A." >&2
    exit 1
fi

# 4. Copy custom models to Gazebo models directory (with loop existence check)
if [ -d "$custom_model_dir" ]; then
    # Loop through each item inside the custom model directory
    for item in "$custom_model_dir"/*; do
        if [ -d "$item" ]; then
            model_name=$(basename "$item")
            TARGET_MODEL_DIR="$DIR_B_ABS/$gz_model_dir/$model_name"

            # CHECK: Does this specific model folder already exist in the target?
            if [ -d "$TARGET_MODEL_DIR" ]; then
                echo "Skipping folder: Model '$model_name' already exists in $gz_model_dir/"
            else
                cp -r "$item" "$DIR_B_ABS/$gz_model_dir/"
                echo "Successfully copied model folder '$model_name' to $gz_model_dir/"
            fi
        fi
    done
else
    echo "Error: Folder $custom_model_dir does not exist in Directory A." >&2
    exit 1
fi

echo "Deployment task finished!"
