"""
Generate grass clumps + trees for Cash Empire (Blender background).
Exports FBX to ../export/
"""

import bpy
import math
import os
import random
from mathutils import Vector

EXPORT_DIR = r"C:\Users\btayl\vox vr alistor\roblox\assets\export"
random.seed(42)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)


def mat(name, color, metallic=0.0, roughness=0.75, emission=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    nodes = m.node_tree.nodes
    links = m.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0 and "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = emission
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def apply_mat(obj, material):
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def shade_smooth(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.shade_smooth()
    except Exception:
        pass
    obj.select_set(False)


def origin_bottom(obj):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    bbox = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    min_z = min(v.z for v in bbox)
    obj.location.z -= min_z
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)


def join_selected(name):
    objs = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    if not objs:
        return None
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    return obj


def make_blade(h, w, color_mat, x, y, rot_z, lean=0.15):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, h / 2))
    b = bpy.context.active_object
    b.scale = (w, w * 0.35, h)
    b.rotation_euler[0] = lean
    b.rotation_euler[2] = rot_z
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # taper top via scale at top isn't easy without edit mode — squash slightly
    apply_mat(b, color_mat)
    return b


def make_grass_clump(name, dense=12):
    clear_scene()
    greens = [
        mat(name + "_g1", (0.22, 0.55, 0.18), roughness=0.85),
        mat(name + "_g2", (0.30, 0.62, 0.22), roughness=0.8),
        mat(name + "_g3", (0.18, 0.48, 0.14), roughness=0.9),
        mat(name + "_g4", (0.40, 0.70, 0.28), roughness=0.75),
    ]
    for i in range(dense):
        ang = (i / dense) * math.pi * 2 + random.uniform(-0.2, 0.2)
        r = random.uniform(0.02, 0.22)
        x = math.cos(ang) * r
        y = math.sin(ang) * r
        h = random.uniform(0.25, 0.55)
        w = random.uniform(0.03, 0.07)
        make_blade(h, w, random.choice(greens), x, y, ang + random.uniform(-0.3, 0.3), lean=random.uniform(0.05, 0.35))

    # dirt base
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.2, depth=0.04, location=(0, 0, 0.02))
    dirt = bpy.context.active_object
    apply_mat(dirt, mat(name + "_dirt", (0.28, 0.2, 0.12), roughness=0.95))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_tree(name, trunk_h=2.2, trunk_r=0.18, canopy_r=1.1, canopy_levels=3):
    clear_scene()
    bark = mat(name + "_bark", (0.35, 0.22, 0.12), roughness=0.9)
    leaf_cols = [
        mat(name + "_l1", (0.2, 0.55, 0.18), roughness=0.7),
        mat(name + "_l2", (0.28, 0.62, 0.22), roughness=0.65),
        mat(name + "_l3", (0.15, 0.45, 0.12), roughness=0.75),
    ]

    # trunk
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=trunk_r, depth=trunk_h, location=(0, 0, trunk_h / 2))
    trunk = bpy.context.active_object
    apply_mat(trunk, bark)
    # slight taper: smaller top cylinder
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=10,
        radius=trunk_r * 0.7,
        depth=trunk_h * 0.35,
        location=(0, 0, trunk_h * 0.85),
    )
    top_trunk = bpy.context.active_object
    apply_mat(top_trunk, bark)

    # canopy spheres stacked
    for i in range(canopy_levels):
        z = trunk_h * 0.75 + i * (canopy_r * 0.45)
        r = canopy_r * (1.0 - i * 0.18)
        ox = random.uniform(-0.08, 0.08)
        oy = random.uniform(-0.08, 0.08)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=r, location=(ox, oy, z))
        leaf = bpy.context.active_object
        leaf.scale = (1.0, 1.0, 0.75 + random.uniform(0, 0.15))
        bpy.ops.object.transform_apply(scale=True)
        apply_mat(leaf, leaf_cols[i % len(leaf_cols)])

    # roots
    for i in range(4):
        ang = i * (math.pi / 2) + 0.3
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(math.cos(ang) * trunk_r * 1.2, math.sin(ang) * trunk_r * 1.2, 0.06),
        )
        root = bpy.context.active_object
        root.scale = (0.35, 0.12, 0.08)
        root.rotation_euler[2] = ang
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        apply_mat(root, bark)

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_bush(name):
    clear_scene()
    greens = [
        mat(name + "_a", (0.22, 0.5, 0.16), roughness=0.75),
        mat(name + "_b", (0.3, 0.58, 0.2), roughness=0.7),
    ]
    for i in range(5):
        ang = i * (math.pi * 2 / 5)
        r = 0.15
        bpy.ops.mesh.primitive_ico_sphere_add(
            subdivisions=2,
            radius=random.uniform(0.28, 0.4),
            location=(math.cos(ang) * r, math.sin(ang) * r, random.uniform(0.25, 0.4)),
        )
        s = bpy.context.active_object
        apply_mat(s, greens[i % 2])
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.35, location=(0, 0, 0.35))
    apply_mat(bpy.context.active_object, greens[0])

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_pine(name):
    clear_scene()
    bark = mat(name + "_bark", (0.32, 0.2, 0.1), roughness=0.92)
    needle = mat(name + "_n", (0.12, 0.38, 0.15), roughness=0.7)

    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.14, depth=2.4, location=(0, 0, 1.2))
    apply_mat(bpy.context.active_object, bark)

    for i, (z, r) in enumerate(((1.0, 1.0), (1.55, 0.75), (2.05, 0.5), (2.45, 0.28))):
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=r, radius2=0.02, depth=0.7, location=(0, 0, z))
        apply_mat(bpy.context.active_object, needle)

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def export_fbx(obj, path):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    origin_bottom(obj)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.fbx(
        filepath=path,
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
    print("Exported", path)


def main():
    os.makedirs(EXPORT_DIR, exist_ok=True)
    jobs = []

    def run(fn, filename):
        obj = fn()
        if obj:
            path = os.path.join(EXPORT_DIR, filename)
            export_fbx(obj, path)
            jobs.append(filename)

    run(lambda: make_grass_clump("GrassClump", dense=14), "GrassClump.fbx")
    run(lambda: make_grass_clump("GrassClumpDense", dense=22), "GrassClumpDense.fbx")
    run(lambda: make_tree("OakTree", trunk_h=2.4, trunk_r=0.2, canopy_r=1.25, canopy_levels=3), "OakTree.fbx")
    run(lambda: make_tree("OakTreeLarge", trunk_h=3.2, trunk_r=0.28, canopy_r=1.7, canopy_levels=4), "OakTreeLarge.fbx")
    run(lambda: make_pine("PineTree"), "PineTree.fbx")
    run(lambda: make_bush("Bush"), "Bush.fbx")

    manifest = os.path.join(EXPORT_DIR, "MANIFEST_NATURE.txt")
    with open(manifest, "w", encoding="utf-8") as f:
        f.write("Cash Empire nature props\n")
        for j in jobs:
            f.write(j + "\n")
        f.write("\nImport via Studio Asset Manager → Bulk Import\n")

    print("DONE nature", len(jobs))
    for j in jobs:
        print(" ", j)


if __name__ == "__main__":
    main()
