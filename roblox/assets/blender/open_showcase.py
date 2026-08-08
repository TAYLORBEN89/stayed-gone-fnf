"""
Open a Blender showcase scene with all Cash Empire FBX props laid out in a grid.
Run: blender --python open_showcase.py
"""

import bpy
import os
import math

EXPORT_DIR = r"C:\Users\btayl\vox vr alistor\roblox\assets\export"
BLEND_OUT = r"C:\Users\btayl\vox vr alistor\roblox\assets\blender\CashEmpire_Showcase.blend"


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def main():
    clear()
    # floor
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.name = "Floor"

    files = sorted(
        f
        for f in os.listdir(EXPORT_DIR)
        if f.lower().endswith(".fbx")
    )
    cols = 4
    spacing = 4.0
    for i, name in enumerate(files):
        path = os.path.join(EXPORT_DIR, name)
        row = i // cols
        col = i % cols
        x = (col - (cols - 1) / 2) * spacing
        y = -row * spacing

        before = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=path)
        new = [o for o in bpy.data.objects if o not in before]
        if not new:
            continue
        # parent empties or move meshes
        for o in new:
            if o.type == "MESH":
                o.location = (x, y, 0.0)
                # label
                o.name = os.path.splitext(name)[0]
        # text label as empty name is enough

        # add simple text object above
        bpy.ops.object.text_add(location=(x, y - 1.2, 0.1))
        t = bpy.context.active_object
        t.data.body = os.path.splitext(name)[0]
        t.data.size = 0.35
        t.rotation_euler[2] = 0

    # camera
    bpy.ops.object.camera_add(location=(0, -14, 8), rotation=(math.radians(60), 0, 0))
    cam = bpy.context.active_object
    bpy.context.scene.camera = cam

    # light
    bpy.ops.object.light_add(type="SUN", location=(5, -5, 15))
    bpy.context.active_object.data.energy = 3

    os.makedirs(os.path.dirname(BLEND_OUT), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
    print("Showcase saved:", BLEND_OUT)
    print("Items:", len(files))


if __name__ == "__main__":
    main()
