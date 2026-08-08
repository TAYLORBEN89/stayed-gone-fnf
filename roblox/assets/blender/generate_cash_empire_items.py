"""
Generate Cash Empire starter props in Blender (background-safe).
Exports FBX to ../export/
"""

import bpy
import math
import os
from mathutils import Vector, Matrix

EXPORT_DIR = r"C:\Users\btayl\vox vr alistor\roblox\assets\export"
BLEND_DIR = r"C:\Users\btayl\vox vr alistor\roblox\assets\blender"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # purge orphans lightly
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)


def mat(name, color, metallic=0.3, roughness=0.4, emission=0.0):
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
    # emission strength naming differs by blender version
    for key in ("Emission Strength", "Emission"):
        if key in bsdf.inputs and emission > 0:
            try:
                if key == "Emission":
                    bsdf.inputs[key].default_value = (*color, 1.0)
                else:
                    bsdf.inputs[key].default_value = emission
            except Exception:
                pass
    if "Emission Color" in bsdf.inputs and emission > 0:
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
    # move so bottom sits on Z=0
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


def make_coin(name, color, radius=0.45, depth=0.08, ridge=True, hole=False, bevel=True):
    clear_scene()
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=48,
        radius=radius,
        depth=depth,
        location=(0, 0, depth / 2),
    )
    coin = bpy.context.active_object
    coin.name = name + "_body"
    apply_mat(coin, mat(name + "_mat", color, metallic=0.85, roughness=0.25))

    # raised rim
    if ridge:
        bpy.ops.mesh.primitive_torus_add(
            major_radius=radius * 0.92,
            minor_radius=depth * 0.35,
            major_segments=48,
            minor_segments=12,
            location=(0, 0, depth / 2),
        )
        rim = bpy.context.active_object
        rim.name = name + "_rim"
        apply_mat(rim, mat(name + "_rim_mat", tuple(min(1, c + 0.08) for c in color), metallic=0.9, roughness=0.2))

    # center emboss disc
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=32,
        radius=radius * 0.45,
        depth=depth * 0.35,
        location=(0, 0, depth * 0.75),
    )
    emb = bpy.context.active_object
    emb.name = name + "_emboss"
    apply_mat(emb, mat(name + "_emb", tuple(min(1, c + 0.15) for c in color), metallic=0.7, roughness=0.3))

    if hole:
        # boolean-ish look: small inner cylinder different color (visual only)
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=24,
            radius=radius * 0.18,
            depth=depth * 1.4,
            location=(0, 0, depth / 2),
        )
        hole_obj = bpy.context.active_object
        apply_mat(hole_obj, mat(name + "_hole", (0.05, 0.05, 0.05), metallic=0, roughness=1))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_bill_stack(name, color):
    clear_scene()
    parts = []
    for i in range(8):
        bpy.ops.mesh.primitive_cube_add(
            size=1,
            location=(0, 0, 0.03 + i * 0.045),
        )
        b = bpy.context.active_object
        b.scale = (0.7, 0.35, 0.02)
        b.rotation_euler[2] = math.radians((i - 4) * 2.5)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        apply_mat(b, mat(f"{name}_p{i}", color, metallic=0.05, roughness=0.65))
        parts.append(b)
    # band
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.2))
    band = bpy.context.active_object
    band.scale = (0.75, 0.08, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(band, mat(name + "_band", (0.15, 0.15, 0.18), metallic=0.2, roughness=0.5))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_bar(name, color):
    clear_scene()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.12))
    bar = bpy.context.active_object
    bar.scale = (0.9, 0.35, 0.22)
    bpy.ops.object.transform_apply(scale=True)
    # bevel-ish: smaller top plate
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.28))
    top = bpy.context.active_object
    top.scale = (0.82, 0.28, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(bar, mat(name + "_m", color, metallic=0.95, roughness=0.18))
    apply_mat(top, mat(name + "_t", tuple(min(1, c + 0.1) for c in color), metallic=0.95, roughness=0.15))
    # stamp
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.12, depth=0.03, location=(0, 0, 0.32))
    stamp = bpy.context.active_object
    apply_mat(stamp, mat(name + "_s", (0.9, 0.9, 0.95), metallic=0.5, roughness=0.3))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_dragon_egg(name):
    clear_scene()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=24, radius=0.45, location=(0, 0, 0.55))
    egg = bpy.context.active_object
    egg.scale = (0.85, 0.85, 1.15)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(egg, mat(name + "_shell", (0.75, 0.12, 0.2), metallic=0.35, roughness=0.35, emission=0.15))

    # cracks / ridges as thin torus rings
    for i, z in enumerate((0.35, 0.55, 0.75)):
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.38 - i * 0.04,
            minor_radius=0.025,
            major_segments=32,
            location=(0, 0, z),
        )
        ring = bpy.context.active_object
        ring.scale[2] = 0.6
        bpy.ops.object.transform_apply(scale=True)
        apply_mat(ring, mat(f"{name}_r{i}", (1.0, 0.45, 0.15), metallic=0.2, roughness=0.4, emission=0.4))

    # glow core
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.12, location=(0, 0, 0.55))
    core = bpy.context.active_object
    apply_mat(core, mat(name + "_core", (1.0, 0.6, 0.1), metallic=0, roughness=0.2, emission=2.0))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_star_fragment(name):
    clear_scene()
    # low-poly crystal: elongated diamond from scaled cube + octahedron-ish
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.35, location=(0, 0, 0.45))
    crystal = bpy.context.active_object
    crystal.scale = (0.55, 0.55, 1.3)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(crystal, mat(name + "_c", (1.0, 0.95, 0.55), metallic=0.2, roughness=0.15, emission=0.6))

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.2, location=(0.15, 0.1, 0.7))
    shard = bpy.context.active_object
    shard.scale = (0.4, 0.4, 0.9)
    shard.rotation_euler = (0.4, 0.2, 0.5)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    apply_mat(shard, mat(name + "_s", (0.95, 0.85, 0.35), metallic=0.15, roughness=0.12, emission=0.8))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_piggy(name):
    clear_scene()
    # body
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=16, radius=0.45, location=(0, 0, 0.4))
    body = bpy.context.active_object
    body.scale = (1.1, 0.85, 0.8)
    bpy.ops.object.transform_apply(scale=True)
    pink = (1.0, 0.55, 0.65)
    apply_mat(body, mat(name + "_body", pink, metallic=0.05, roughness=0.55))

    # head
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.28, location=(0.42, 0, 0.48))
    head = bpy.context.active_object
    apply_mat(head, mat(name + "_head", pink, metallic=0.05, roughness=0.55))

    # snout
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.12, depth=0.12, location=(0.62, 0, 0.45))
    snout = bpy.context.active_object
    snout.rotation_euler[1] = math.radians(90)
    bpy.ops.object.transform_apply(rotation=True)
    apply_mat(snout, mat(name + "_snout", (1.0, 0.45, 0.55), metallic=0, roughness=0.5))

    # ears
    for y in (-0.12, 0.12):
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=0.1, depth=0.15, location=(0.4, y, 0.72))
        ear = bpy.context.active_object
        apply_mat(ear, mat(name + f"_ear{y}", pink, metallic=0, roughness=0.5))

    # legs
    for x, y in ((-0.2, -0.2), (-0.2, 0.2), (0.2, -0.2), (0.2, 0.2)):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.07, depth=0.22, location=(x, y, 0.11))
        leg = bpy.context.active_object
        apply_mat(leg, mat(name + f"_leg{x}{y}", (0.95, 0.5, 0.58), metallic=0, roughness=0.5))

    # coin slot
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.72))
    slot = bpy.context.active_object
    slot.scale = (0.22, 0.03, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(slot, mat(name + "_slot", (0.1, 0.1, 0.1), metallic=0, roughness=0.8))

    bpy.ops.object.select_all(action="SELECT")
    obj = join_selected(name)
    if obj:
        shade_smooth(obj)
        origin_bottom(obj)
    return obj


def make_bitcoin(name):
    clear_scene()
    make_coin(name + "_tmp", (0.95, 0.62, 0.12), radius=0.48, depth=0.1)
    # rebuild with B-like bars
    clear_scene()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.48, depth=0.1, location=(0, 0, 0.05))
    disc = bpy.context.active_object
    apply_mat(disc, mat(name + "_d", (0.95, 0.62, 0.12), metallic=0.9, roughness=0.22))

    # vertical bar of B
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.05, 0, 0.12))
    bar = bpy.context.active_object
    bar.scale = (0.08, 0.08, 0.32)
    bpy.ops.object.transform_apply(scale=True)
    gold = mat(name + "_g", (1.0, 0.75, 0.2), metallic=0.85, roughness=0.2)
    apply_mat(bar, gold)

    for z in (0.18, 0.05):
        bpy.ops.mesh.primitive_torus_add(
            major_radius=0.14,
            minor_radius=0.035,
            major_segments=24,
            minor_segments=10,
            location=(0.05, 0, z),
        )
        t = bpy.context.active_object
        t.rotation_euler[0] = math.radians(90)
        bpy.ops.object.transform_apply(rotation=True)
        apply_mat(t, gold)

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
    # scale for Roblox-ish stud size (~1 unit ≈ manageable prop)
    obj.scale = (1.2, 1.2, 1.2)
    bpy.ops.object.transform_apply(scale=True)
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
    os.makedirs(BLEND_DIR, exist_ok=True)

    jobs = []

    def run(fn, filename):
        obj = fn()
        if obj:
            path = os.path.join(EXPORT_DIR, filename)
            export_fbx(obj, path)
            jobs.append(path)

    run(lambda: make_coin("Penny", (0.72, 0.42, 0.22), radius=0.4, depth=0.07), "Penny.fbx")
    run(lambda: make_coin("Doubloon", (1.0, 0.78, 0.18), radius=0.48, depth=0.1), "GoldDoubloon.fbx")
    run(lambda: make_coin("PlatinumCoin", (0.78, 0.85, 0.92), radius=0.46, depth=0.09), "PlatinumCoin.fbx")
    run(lambda: make_bill_stack("DollarStack", (0.25, 0.65, 0.35)), "DollarStack.fbx")
    run(lambda: make_bar("PlatinumBar", (0.7, 0.78, 0.88)), "PlatinumBar.fbx")
    run(lambda: make_bitcoin("Bitcoin"), "Bitcoin.fbx")
    run(lambda: make_dragon_egg("DragonEgg"), "DragonEgg.fbx")
    run(lambda: make_star_fragment("StarFragment"), "StarFragment.fbx")
    run(lambda: make_piggy("PiggyBank"), "PiggyBank.fbx")

    # Save a showcase blend with last object only — rebuild showcase
    clear_scene()
    # re-import isn't needed; save empty scene note
    blend_path = os.path.join(BLEND_DIR, "CashEmpire_Items_README.txt")
    with open(blend_path, "w", encoding="utf-8") as f:
        f.write("Cash Empire generated FBX items\n")
        f.write("Import these in Roblox Studio: Asset Manager → Bulk Import\n\n")
        for p in jobs:
            f.write(os.path.basename(p) + "\n")

    # also write manifest
    manifest = os.path.join(EXPORT_DIR, "MANIFEST.txt")
    with open(manifest, "w", encoding="utf-8") as f:
        f.write("Cash Empire — Blender-generated props\n")
        f.write("=" * 40 + "\n")
        for p in jobs:
            f.write(f"{os.path.basename(p)}\n")
        f.write("\nStudio: View → Asset Manager → Bulk Import → select these FBX files\n")
        f.write("Or Blender Roblox plugin: open each / import FBX then Upload\n")

    print("DONE", len(jobs), "items")
    for p in jobs:
        print(" ", p)


if __name__ == "__main__":
    main()
