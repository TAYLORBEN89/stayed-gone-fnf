"""
Blender script: export selected meshes to Cash Empire assets/export as FBX.

Usage in Blender:
  Scripting workspace → Open this file → Run Script
  Or: blender --background your.blend --python export_roblox_fbx.py
"""

import bpy
import os

# Relative to this script when run from Blender Text Editor: set absolute path
EXPORT_DIR = r"C:\Users\btayl\vox vr alistor\roblox\assets\export"


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def prepare_selection():
    if not bpy.context.selected_objects:
        raise RuntimeError("Select at least one object to export.")
    # Apply transforms on selected meshes
    view_layer = bpy.context.view_layer
    for obj in list(bpy.context.selected_objects):
        if obj.type != "MESH":
            continue
        view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def export_selected():
    ensure_dir(EXPORT_DIR)
    selected = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    if not selected:
        # export whole selection as one file named after active
        name = bpy.context.active_object.name if bpy.context.active_object else "export"
        filepath = os.path.join(EXPORT_DIR, f"{name}.fbx")
        bpy.ops.export_scene.fbx(
            filepath=filepath,
            use_selection=True,
            apply_scale_options="FBX_SCALE_UNITS",
            axis_forward="-Z",
            axis_up="Y",
            path_mode="COPY",
            embed_textures=True,
            bake_space_transform=True,
            object_types={"MESH", "ARMATURE", "EMPTY"},
            use_mesh_modifiers=True,
            mesh_smooth_type="FACE",
            add_leaf_bones=False,
        )
        print(f"Exported: {filepath}")
        return

    # One FBX per mesh (Roblox-friendly)
    for obj in selected:
        # isolate selection
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        safe = "".join(c if c.isalnum() or c in "-_" else "_" for c in obj.name)
        filepath = os.path.join(EXPORT_DIR, f"{safe}.fbx")
        bpy.ops.export_scene.fbx(
            filepath=filepath,
            use_selection=True,
            apply_scale_options="FBX_SCALE_UNITS",
            axis_forward="-Z",
            axis_up="Y",
            path_mode="COPY",
            embed_textures=True,
            bake_space_transform=True,
            object_types={"MESH"},
            use_mesh_modifiers=True,
            mesh_smooth_type="FACE",
            add_leaf_bones=False,
        )
        print(f"Exported: {filepath}")

    # reselect all
    for obj in selected:
        obj.select_set(True)


if __name__ == "__main__":
    prepare_selection()
    export_selected()
    print("Done. Import FBX via Studio Asset Manager → Bulk Import.")
