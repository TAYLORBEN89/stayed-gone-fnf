"""
Generate ALL Cash Empire pickup/currency props + open showcase.
Matches Config.Currencies ids.
"""

import bpy
import math
import os
import random
from mathutils import Vector

EXPORT_DIR = r"C:\Users\btayl\vox vr alistor\roblox\assets\export"
BLEND_OUT = r"C:\Users\btayl\vox vr alistor\roblox\assets\blender\CashEmpire_Pickups_Showcase.blend"
random.seed(7)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        if block.users == 0:
            bpy.data.materials.remove(block)
    for block in list(bpy.data.curves):
        if block.users == 0:
            bpy.data.curves.remove(block)


def mat(name, color, metallic=0.3, roughness=0.4, emission=0.0):
    m = bpy.data.materials.new(name=name[:60])
    m.use_nodes = True
    nt = m.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = roughness
    if emission > 0:
        if "Emission Strength" in bsdf.inputs:
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


def join_all(name):
    bpy.ops.object.select_all(action="SELECT")
    meshes = [o for o in bpy.context.selected_objects if o.type == "MESH"]
    if not meshes:
        return None
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    shade_smooth(obj)
    origin_bottom(obj)
    return obj


def coin(name, color, r=0.45, d=0.09, emboss=True):
    clear_scene()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=r, depth=d, location=(0, 0, d / 2))
    body = bpy.context.active_object
    apply_mat(body, mat(name + "_m", color, metallic=0.88, roughness=0.22))
    bpy.ops.mesh.primitive_torus_add(
        major_radius=r * 0.9, minor_radius=d * 0.32, major_segments=48, minor_segments=10, location=(0, 0, d / 2)
    )
    apply_mat(bpy.context.active_object, mat(name + "_rim", tuple(min(1, c + 0.1) for c in color), metallic=0.9, roughness=0.2))
    if emboss:
        bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r * 0.42, depth=d * 0.3, location=(0, 0, d * 0.72))
        apply_mat(bpy.context.active_object, mat(name + "_e", tuple(min(1, c + 0.12) for c in color), metallic=0.7, roughness=0.28))
    return join_all(name)


def bill_stack(name, color, n=8):
    clear_scene()
    for i in range(n):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.025 + i * 0.04))
        b = bpy.context.active_object
        b.scale = (0.72, 0.36, 0.018)
        b.rotation_euler[2] = math.radians((i - n / 2) * 2.2)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        apply_mat(b, mat(f"{name}_{i}", color, metallic=0.05, roughness=0.7))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.18))
    band = bpy.context.active_object
    band.scale = (0.78, 0.07, 0.1)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(band, mat(name + "_band", (0.12, 0.12, 0.14), metallic=0.15, roughness=0.55))
    return join_all(name)


def jar(name):
    clear_scene()
    glass = mat(name + "_g", (0.75, 0.85, 0.9), metallic=0.05, roughness=0.15)
    gold = mat(name + "_gold", (0.95, 0.75, 0.2), metallic=0.9, roughness=0.25)
    # jar body
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.28, depth=0.45, location=(0, 0, 0.28))
    apply_mat(bpy.context.active_object, glass)
    # neck
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.16, depth=0.12, location=(0, 0, 0.55))
    apply_mat(bpy.context.active_object, glass)
    # lid
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.18, depth=0.06, location=(0, 0, 0.64))
    apply_mat(bpy.context.active_object, gold)
    # coins inside (visual)
    for i in range(5):
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.08, depth=0.025, location=(random.uniform(-0.1, 0.1), random.uniform(-0.1, 0.1), 0.2 + i * 0.04)
        )
        apply_mat(bpy.context.active_object, gold)
    return join_all(name)


def tooth(name):
    clear_scene()
    green = mat(name + "_g", (0.45, 0.85, 0.35), metallic=0.1, roughness=0.45)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.25))
    root = bpy.context.active_object
    root.scale = (0.18, 0.18, 0.35)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(root, green)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.16, location=(0, 0, 0.48))
    apply_mat(bpy.context.active_object, mat(name + "_t", (0.85, 0.9, 0.75), metallic=0.05, roughness=0.35))
    # green gunk
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=0.06, location=(0.08, 0.05, 0.55))
    apply_mat(bpy.context.active_object, green)
    return join_all(name)


def token_cheese(name):
    clear_scene()
    # arcade token disc
    c = coin(name + "_base", (1.0, 0.4, 0.2), r=0.42, d=0.1)
    clear_scene()
    bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=0.42, depth=0.1, location=(0, 0, 0.05))
    apply_mat(bpy.context.active_object, mat(name + "_d", (1.0, 0.38, 0.18), metallic=0.75, roughness=0.28))
    # cheese wedge on top
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.2, depth=0.12, location=(0.05, 0, 0.14))
    apply_mat(bpy.context.active_object, mat(name + "_ch", (1.0, 0.85, 0.25), metallic=0.05, roughness=0.5))
    return join_all(name)


def monopoly_piece(name):
    clear_scene()
    yellow = mat(name + "_y", (1.0, 0.85, 0.15), metallic=0.15, roughness=0.4)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.08))
    card = bpy.context.active_object
    card.scale = (0.55, 0.35, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(card, yellow)
    # red hotel
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.18))
    hotel = bpy.context.active_object
    hotel.scale = (0.18, 0.14, 0.14)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(hotel, mat(name + "_h", (0.9, 0.15, 0.12), metallic=0.1, roughness=0.45))
    # text plate
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.11))
    plate = bpy.context.active_object
    plate.scale = (0.4, 0.12, 0.01)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(plate, mat(name + "_p", (0.15, 0.15, 0.15), metallic=0, roughness=0.6))
    return join_all(name)


def ticket(name):
    clear_scene()
    pink = mat(name + "_p", (1.0, 0.3, 0.55), metallic=0.05, roughness=0.55)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.03))
    t = bpy.context.active_object
    t.scale = (0.65, 0.28, 0.025)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(t, pink)
    # perforated edge notches
    for x in (-0.28, 0.28):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.04, depth=0.04, location=(x, 0, 0.03))
        apply_mat(bpy.context.active_object, mat(name + f"_n{x}", (0.05, 0.05, 0.05), metallic=0, roughness=1))
    # stripe
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.045))
    s = bpy.context.active_object
    s.scale = (0.55, 0.06, 0.01)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(s, mat(name + "_s", (1.0, 0.9, 0.2), metallic=0.1, roughness=0.4))
    return join_all(name)


def pearl(name):
    clear_scene()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=20, radius=0.32, location=(0, 0, 0.32))
    apply_mat(bpy.context.active_object, mat(name + "_p", (0.12, 0.12, 0.16), metallic=0.85, roughness=0.12, emission=0.05))
    # highlight
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.08, location=(0.1, 0.1, 0.45))
    apply_mat(bpy.context.active_object, mat(name + "_h", (0.5, 0.5, 0.55), metallic=0.9, roughness=0.08, emission=0.2))
    return join_all(name)


def laurel(name):
    clear_scene()
    gold = mat(name + "_g", (0.95, 0.78, 0.2), metallic=0.9, roughness=0.25)
    # two arcs as torus sections approximated by many small leaves
    for side in (-1, 1):
        for i in range(10):
            t = i / 9
            ang = math.radians(-70 + t * 140)
            x = side * 0.28 * math.sin(ang)
            z = 0.15 + 0.35 * (1 - math.cos(ang))
            y = 0.22 * math.cos(ang)
            bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z))
            leaf = bpy.context.active_object
            leaf.scale = (0.06, 0.12, 0.02)
            leaf.rotation_euler = (0, 0, ang * side)
            bpy.ops.object.transform_apply(rotation=True, scale=True)
            apply_mat(leaf, gold)
    # base disc
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.2, depth=0.05, location=(0, 0, 0.03))
    apply_mat(bpy.context.active_object, gold)
    return join_all(name)


def keycard(name):
    clear_scene()
    teal = mat(name + "_t", (0.35, 0.95, 0.7), metallic=0.2, roughness=0.35, emission=0.3)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.03))
    card = bpy.context.active_object
    card.scale = (0.55, 0.35, 0.03)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(card, teal)
    # chip
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.15, 0.05, 0.05))
    chip = bpy.context.active_object
    chip.scale = (0.1, 0.08, 0.015)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(chip, mat(name + "_c", (0.9, 0.75, 0.2), metallic=0.8, roughness=0.25))
    # stripe
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.05, -0.08, 0.05))
    stripe = bpy.context.active_object
    stripe.scale = (0.35, 0.06, 0.01)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(stripe, mat(name + "_s", (0.1, 0.1, 0.12), metallic=0.3, roughness=0.4))
    return join_all(name)


def ethereum(name):
    clear_scene()
    blue = mat(name + "_b", (0.4, 0.5, 1.0), metallic=0.35, roughness=0.25, emission=0.4)
    # diamond crystal (octahedron-ish)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.35, location=(0, 0, 0.4))
    crystal = bpy.context.active_object
    crystal.scale = (0.55, 0.55, 1.1)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(crystal, blue)
    # ring base
    bpy.ops.mesh.primitive_torus_add(major_radius=0.28, minor_radius=0.04, location=(0, 0, 0.08))
    apply_mat(bpy.context.active_object, mat(name + "_r", (0.7, 0.75, 1.0), metallic=0.6, roughness=0.3))
    return join_all(name)


def duck(name):
    clear_scene()
    yellow = mat(name + "_y", (1.0, 0.85, 0.2), metallic=0.05, roughness=0.45)
    orange = mat(name + "_o", (1.0, 0.45, 0.1), metallic=0.05, roughness=0.45)
    # body
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.35, location=(0, 0, 0.32))
    body = bpy.context.active_object
    body.scale = (1.15, 0.9, 0.85)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(body, yellow)
    # head
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.2, location=(0.28, 0, 0.55))
    apply_mat(bpy.context.active_object, yellow)
    # beak
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.08, depth=0.14, location=(0.48, 0, 0.52))
    beak = bpy.context.active_object
    beak.rotation_euler[1] = math.radians(90)
    bpy.ops.object.transform_apply(rotation=True)
    apply_mat(beak, orange)
    # pixel frame (JPEG vibe)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.4))
    frame = bpy.context.active_object
    frame.scale = (0.7, 0.05, 0.55)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(frame, mat(name + "_f", (0.2, 0.2, 0.25), metallic=0.2, roughness=0.5))
    return join_all(name)


def nebula(name):
    clear_scene()
    purple = mat(name + "_p", (0.65, 0.3, 1.0), metallic=0.15, roughness=0.2, emission=0.8)
    pink = mat(name + "_k", (0.9, 0.3, 0.7), metallic=0.1, roughness=0.25, emission=0.6)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.28, location=(0, 0, 0.35))
    apply_mat(bpy.context.active_object, purple)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.18, location=(0.15, 0.1, 0.45))
    apply_mat(bpy.context.active_object, pink)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.12, location=(-0.12, -0.08, 0.5))
    apply_mat(bpy.context.active_object, mat(name + "_b", (0.3, 0.5, 1.0), metallic=0.1, roughness=0.2, emission=1.0))
    # orbit ring
    bpy.ops.mesh.primitive_torus_add(major_radius=0.35, minor_radius=0.025, location=(0, 0, 0.35))
    ring = bpy.context.active_object
    ring.rotation_euler[0] = math.radians(70)
    bpy.ops.object.transform_apply(rotation=True)
    apply_mat(ring, mat(name + "_r", (0.8, 0.6, 1.0), metallic=0.4, roughness=0.3, emission=0.5))
    return join_all(name)


def infinity_cent(name):
    clear_scene()
    white = mat(name + "_w", (1.0, 1.0, 1.0), metallic=0.95, roughness=0.08, emission=0.5)
    # figure-8 as two tori
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.06, location=(-0.12, 0, 0.3))
    apply_mat(bpy.context.active_object, white)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.06, location=(0.12, 0, 0.3))
    apply_mat(bpy.context.active_object, white)
    # pedestal coin
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.35, depth=0.08, location=(0, 0, 0.04))
    apply_mat(bpy.context.active_object, mat(name + "_c", (0.95, 0.95, 1.0), metallic=0.9, roughness=0.15, emission=0.2))
    return join_all(name)


def bar(name, color):
    clear_scene()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.12))
    b = bpy.context.active_object
    b.scale = (0.9, 0.35, 0.22)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(b, mat(name + "_m", color, metallic=0.95, roughness=0.18))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.26))
    t = bpy.context.active_object
    t.scale = (0.8, 0.28, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(t, mat(name + "_t", tuple(min(1, c + 0.1) for c in color), metallic=0.95, roughness=0.15))
    return join_all(name)


def egg(name):
    clear_scene()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=24, radius=0.42, location=(0, 0, 0.5))
    egg = bpy.context.active_object
    egg.scale = (0.85, 0.85, 1.15)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(egg, mat(name + "_s", (0.85, 0.15, 0.22), metallic=0.35, roughness=0.32, emission=0.2))
    for i, z in enumerate((0.32, 0.52, 0.72)):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.36 - i * 0.04, minor_radius=0.022, location=(0, 0, z))
        apply_mat(bpy.context.active_object, mat(f"{name}_r{i}", (1.0, 0.45, 0.12), metallic=0.2, roughness=0.35, emission=0.5))
    return join_all(name)


def star(name):
    clear_scene()
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.32, location=(0, 0, 0.4))
    c = bpy.context.active_object
    c.scale = (0.55, 0.55, 1.25)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(c, mat(name + "_c", (1.0, 0.95, 0.5), metallic=0.2, roughness=0.15, emission=0.7))
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.18, location=(0.12, 0.08, 0.65))
    apply_mat(bpy.context.active_object, mat(name + "_s", (1.0, 0.9, 0.3), metallic=0.15, roughness=0.12, emission=0.9))
    return join_all(name)


def bitcoin(name):
    clear_scene()
    gold = (0.95, 0.65, 0.12)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.48, depth=0.1, location=(0, 0, 0.05))
    apply_mat(bpy.context.active_object, mat(name + "_d", gold, metallic=0.9, roughness=0.22))
    g = mat(name + "_g", (1.0, 0.78, 0.2), metallic=0.85, roughness=0.2)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.05, 0, 0.12))
    bar = bpy.context.active_object
    bar.scale = (0.08, 0.08, 0.32)
    bpy.ops.object.transform_apply(scale=True)
    apply_mat(bar, g)
    for z in (0.18, 0.05):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.14, minor_radius=0.035, location=(0.05, 0, z))
        t = bpy.context.active_object
        t.rotation_euler[0] = math.radians(90)
        bpy.ops.object.transform_apply(rotation=True)
        apply_mat(t, g)
    return join_all(name)


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


def build_showcase(paths):
    clear_scene()
    bpy.ops.mesh.primitive_plane_add(size=50, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.name = "Floor"
    apply_mat(floor, mat("floor", (0.15, 0.15, 0.18), metallic=0, roughness=0.9))

    cols = 5
    spacing = 3.5
    for i, path in enumerate(paths):
        name = os.path.splitext(os.path.basename(path))[0]
        row, col = divmod(i, cols)
        x = (col - (cols - 1) / 2) * spacing
        y = -row * spacing
        before = set(bpy.data.objects)
        try:
            bpy.ops.import_scene.fbx(filepath=path)
        except Exception as e:
            print("Import fail", path, e)
            continue
        new = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
        for o in new:
            o.location = (x, y, 0)
            o.name = name
        bpy.ops.object.text_add(location=(x, y - 1.1, 0.05))
        t = bpy.context.active_object
        t.data.body = name
        t.data.size = 0.28
        apply_mat(t, mat(f"txt_{i}", (1, 1, 1), metallic=0, roughness=0.5))

    bpy.ops.object.camera_add(location=(0, -16, 10), rotation=(math.radians(55), 0, 0))
    bpy.context.scene.camera = bpy.context.active_object
    bpy.ops.object.light_add(type="SUN", location=(6, -4, 12))
    bpy.context.active_object.data.energy = 3.5
    bpy.ops.object.light_add(type="AREA", location=(0, 2, 6))
    bpy.context.active_object.data.energy = 200

    os.makedirs(os.path.dirname(BLEND_OUT), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
    print("Showcase:", BLEND_OUT)


def main():
    os.makedirs(EXPORT_DIR, exist_ok=True)
    # (filename without ext, builder fn)
    items = [
        ("Penny", lambda: coin("Penny", (0.72, 0.42, 0.22), r=0.4)),
        ("DollarBill", lambda: bill_stack("DollarBill", (0.25, 0.65, 0.35), 6)),
        ("FiveSpot", lambda: bill_stack("FiveSpot", (0.3, 0.7, 0.4), 7)),
        ("TwentyStack", lambda: bill_stack("TwentyStack", (0.18, 0.55, 0.28), 10)),
        ("CoinJar", lambda: jar("CoinJar")),
        ("ZombieTooth", lambda: tooth("ZombieTooth")),
        ("ChuckEToken", lambda: token_cheese("ChuckEToken")),
        ("MonopolyPiece", lambda: monopoly_piece("MonopolyPiece")),
        ("PrizeTicket", lambda: ticket("PrizeTicket")),
        ("GoldDoubloon", lambda: coin("GoldDoubloon", (1.0, 0.78, 0.18), r=0.48)),
        ("BlackPearl", lambda: pearl("BlackPearl")),
        ("RomanDenarius", lambda: coin("RomanDenarius", (0.82, 0.82, 0.86), r=0.44)),
        ("GoldenLaurel", lambda: laurel("GoldenLaurel")),
        ("PlatinumCoin", lambda: coin("PlatinumCoin", (0.78, 0.85, 0.92), r=0.46)),
        ("PlatinumBar", lambda: bar("PlatinumBar", (0.7, 0.78, 0.88))),
        ("VaultKeycard", lambda: keycard("VaultKeycard")),
        ("Bitcoin", lambda: bitcoin("Bitcoin")),
        ("Ethereum", lambda: ethereum("Ethereum")),
        ("JPEGDuck", lambda: duck("JPEGDuck")),
        ("StarFragment", lambda: star("StarFragment")),
        ("NebulaShard", lambda: nebula("NebulaShard")),
        ("DragonEgg", lambda: egg("DragonEgg")),
        ("InfinityCent", lambda: infinity_cent("InfinityCent")),
    ]

    paths = []
    for fname, fn in items:
        obj = fn()
        if not obj:
            print("FAIL", fname)
            continue
        path = os.path.join(EXPORT_DIR, fname + ".fbx")
        export_fbx(obj, path)
        paths.append(path)

    # keep existing nature files in showcase too
    for extra in ("PiggyBank.fbx", "OakTree.fbx", "GrassClump.fbx", "Bush.fbx", "PineTree.fbx"):
        p = os.path.join(EXPORT_DIR, extra)
        if os.path.isfile(p) and p not in paths:
            paths.append(p)

    build_showcase(paths)

    with open(os.path.join(EXPORT_DIR, "MANIFEST_PICKUPS.txt"), "w", encoding="utf-8") as f:
        f.write("Cash Empire pickup props\n")
        for p in paths:
            f.write(os.path.basename(p) + "\n")
        f.write(f"\nShowcase: {BLEND_OUT}\n")

    print("DONE", len(paths), "props")


if __name__ == "__main__":
    main()
