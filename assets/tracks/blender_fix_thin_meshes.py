# Blender Script: Fix thin/single-sided meshes
# Run this in Blender's Scripting tab before exporting to Godot
#
# This script does TWO things:
# 1. Adds a Solidify modifier to give thin meshes thickness
# 2. OR duplicates faces and flips normals (for ground/road that should be visible from both sides)
#
# HOW TO USE:
# 1. Open your track in Blender
# 2. Go to the Scripting tab
# 3. Click "New" to create a new script
# 4. Paste this code
# 5. Modify the settings below if needed
# 6. Click "Run Script"
# 7. Re-export your GLB

import bpy
import bmesh

# =============================================================================
# SETTINGS - Adjust these as needed
# =============================================================================

# Option 1: Add thickness with Solidify modifier
USE_SOLIDIFY = False  # Set to True to add thickness
THICKNESS = 0.1       # How thick to make the mesh (in Blender units/meters)

# Option 2: Duplicate faces and flip normals (makes mesh visible from both sides)
USE_DOUBLE_SIDED = True  # Set to True to make meshes double-sided

# Only process meshes with these keywords in their name (case insensitive)
# Leave empty [] to process ALL meshes
KEYWORDS = ["road", "ground", "floor", "terrain", "track", "asphalt", "grass"]

# Skip meshes with these keywords
SKIP_KEYWORDS = ["tree", "building", "fence", "sign", "car", "wheel"]

# =============================================================================
# SCRIPT - Don't modify below unless you know what you're doing
# =============================================================================

def should_process(obj):
    """Check if object should be processed based on keywords"""
    name_lower = obj.name.lower()
    
    # Check skip keywords first
    for skip in SKIP_KEYWORDS:
        if skip.lower() in name_lower:
            return False
    
    # If no keywords specified, process all meshes
    if not KEYWORDS:
        return True
    
    # Check if any keyword matches
    for keyword in KEYWORDS:
        if keyword.lower() in name_lower:
            return True
    
    return False


def add_solidify(obj, thickness):
    """Add Solidify modifier to give mesh thickness"""
    # Check if already has solidify
    for mod in obj.modifiers:
        if mod.type == 'SOLIDIFY':
            print(f"  Skipping {obj.name} - already has Solidify")
            return False
    
    mod = obj.modifiers.new(name="Solidify", type='SOLIDIFY')
    mod.thickness = thickness
    mod.offset = 0  # Center the thickness
    print(f"  Added Solidify to {obj.name}")
    return True


def make_double_sided(obj):
    """Duplicate all faces and flip their normals to make mesh visible from both sides"""
    if obj.type != 'MESH':
        return False
    
    # Enter edit mode
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    
    # Create bmesh
    bm = bmesh.from_edit_mesh(obj.data)
    
    # Get original face count
    original_count = len(bm.faces)
    
    # Duplicate all faces
    geom = bm.faces[:] + bm.edges[:] + bm.verts[:]
    result = bmesh.ops.duplicate(bm, geom=geom)
    
    # Get the new faces
    new_faces = [f for f in result['geom'] if isinstance(f, bmesh.types.BMFace)]
    
    # Flip normals on the new faces
    for face in new_faces:
        face.normal_flip()
    
    # Update mesh
    bmesh.update_edit_mesh(obj.data)
    
    # Return to object mode
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Recalculate normals
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    
    print(f"  Made {obj.name} double-sided ({original_count} -> {len(obj.data.polygons)} faces)")
    return True


def main():
    processed = 0
    skipped = 0
    
    print("\n" + "="*50)
    print("Starting mesh fix script...")
    print("="*50 + "\n")
    
    # Make sure we're in object mode first
    if bpy.context.active_object and bpy.context.active_object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    
    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')
    
    # Process all mesh objects
    for obj in bpy.data.objects:
        if obj.type != 'MESH':
            continue
        
        if not should_process(obj):
            skipped += 1
            continue
        
        print(f"Processing: {obj.name}")
        
        # Select object
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
        if USE_SOLIDIFY:
            if add_solidify(obj, THICKNESS):
                processed += 1
        
        if USE_DOUBLE_SIDED:
            if make_double_sided(obj):
                processed += 1
        
        obj.select_set(False)
    
    print("\n" + "="*50)
    print(f"Done! Processed {processed} meshes, skipped {skipped}")
    print("="*50)
    print("\nNow re-export your GLB file!")


if __name__ == "__main__":
    main()
