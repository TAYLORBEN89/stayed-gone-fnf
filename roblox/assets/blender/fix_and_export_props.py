"""
Fixed prop generation: verify mesh has verts, export FBX + OBJ + PNG preview.
"""

import bpy
import math
import os
from mathutils import Vector

EXPORT = r"C:\Users\btayl\vox vr alistor\roblox\assets\export"
PREVIEWS = r"C:\Users\btayl\vox vr alistor\roblox\assets\export\previews"
BLEND = r"C:\Users\btayl\vox vr alistor\roblox\assets\blender\CashEmpire_Pickups_REAL.blend"


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for col in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.cameras, bpy.data.lights):
        for b in list(col):
            if getattr(b, "users", 1) == 0:
                col.remove(b)


def make_mat(name, color, metallic=0.5, roughness=0.35, emit=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    nodes = m.node_tree.nodes
    links = m.node_tree.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic
    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = roughness
    if emit > 0 and "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = emit
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (*color, 1)
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def set_mat(obj, m):
    if obj.data.materials:
        obj.data.materials[0] = m
    else:
        obj.data.materials.append(m)


def bottom_origin(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    # move geometry so min z = 0
    mw = obj.matrix_world
    coords = [mw @ Vector(c) for c in obj.bound_box]
    min_z = min(v.z for v in coords)
    obj.location.z -= min_z
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    coords = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    min_z = min(v.z for v in coords)
    obj.location.z -= min_z
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)


def join_meshes(name):
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        return None
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    try:
        bpy.ops.object.shade_smooth()
    except Exception:
        pass
    bottom_origin(obj)
    print(f"  MESH {name}: verts={len(obj.data.vertices)} faces={len(obj.data.polygons)}")
    return obj


def export_obj(obj, path):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    # Blender 4+/5 export_scene.obj
    if hasattr(bpy.ops.wm, "obj_export"):
        bpy.ops.wm.obj_export(filepath=path, export_selected_objects=True, forward_axis="NEGATIVE_Z", up_axis="Y")
    else:
        bpy.ops.export_scene.obj(filepath=path, use_selection=True, axis_forward="-Z", axis_up="Y")
    print("  OBJ", path, "bytes", os.path.getsize(path) if os.path.isfile(path) else 0)


def export_fbx(obj, path):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    assert len(obj.data.vertices) > 0, f"empty mesh {obj.name}"
    bpy.ops.export_scene.fbx(
        filepath=path,
        use_selection=True,
        object_types={"MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        bake_space_transform=True,
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        path_mode="AUTO",
        embed_textures=False,
        add_leaf_bones=False,
    )
    sz = os.path.getsize(path) if os.path.isfile(path) else 0
    print("  FBX", path, "bytes", sz)


def render_preview(obj, png_path):
    # simple eevee/workbench preview
    scene = bpy.context.scene
    # camera
    bpy.ops.object.camera_add(location=(1.8, -2.2, 1.4), rotation=(math.radians(65), 0, math.radians(40)))
    cam = bpy.context.active_object
    scene.camera = cam
    # light
    bpy.ops.object.light_add(type="SUN", location=(2, -2, 5))
    bpy.context.active_object.data.energy = 4
    bpy.ops.object.light_add(type="AREA", location=(0, 1, 3))
    bpy.context.active_object.data.energy = 150

    # aim camera at object
    mid = Vector((0, 0, 0.3))
    direction = mid - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.filepath = png_path
    scene.render.image_settings.file_format = "PNG"
    # use workbench for speed/reliability
    scene.render.engine = "BLENDER_WORKBENCH"
    try:
        bpy.ops.render.render(write_still=True)
        print("  PNG", png_path)
    except Exception as e:
        print("  PNG fail", e)

    # remove cam/lights so they don't join next
    for o in list(bpy.context.scene.objects):
        if o.type in ("CAMERA", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)


def coin(name, color, r=0.5, d=0.1):
    clear()
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=r, depth=d, location=(0, 0, d / 2))
    set_mat(bpy.context.active_object, make_mat(name + "m", color, 0.9, 0.25))
    bpy.ops.mesh.primitive_torus_add(
        major_radius=r * 0.88, minor_radius=d * 0.35, major_segments=40, minor_segments=12, location=(0, 0, d / 2)
    )
    set_mat(bpy.context.active_object, make_mat(name + "r", tuple(min(1, c + 0.1) for c in color), 0.92, 0.2))
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=r * 0.4, depth=d * 0.35, location=(0, 0, d * 0.75))
    set_mat(bpy.context.active_object, make_mat(name + "e", tuple(min(1, c + 0.15) for c in color), 0.7, 0.3))
    return join_meshes(name)


def stack(name, color, n=8):
    clear()
    for i in range(n):
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.03 + i * 0.045))
        o = bpy.context.active_object
        o.scale = (0.75, 0.38, 0.02)
        o.rotation_euler.z = math.radians((i - n / 2) * 2)
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        set_mat(o, make_mat(f"{name}{i}", color, 0.05, 0.65))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.2))
    b = bpy.context.active_object
    b.scale = (0.8, 0.08, 0.12)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(b, make_mat(name + "band", (0.15, 0.15, 0.15), 0.2, 0.5))
    return join_meshes(name)


def egg(name):
    clear()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=24, radius=0.45, location=(0, 0, 0.55))
    o = bpy.context.active_object
    o.scale = (0.85, 0.85, 1.2)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name + "s", (0.9, 0.15, 0.2), 0.35, 0.3, 0.25))
    for i, z in enumerate((0.35, 0.55, 0.75)):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.38 - i * 0.05, minor_radius=0.03, location=(0, 0, z))
        set_mat(bpy.context.active_object, make_mat(f"{name}r{i}", (1, 0.5, 0.15), 0.2, 0.35, 0.5))
    return join_meshes(name)


def tree_oak(name):
    clear()
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.2, depth=2.2, location=(0, 0, 1.1))
    set_mat(bpy.context.active_object, make_mat(name + "t", (0.35, 0.22, 0.1), 0, 0.9))
    for i, (z, r) in enumerate(((1.8, 1.1), (2.4, 0.9), (2.9, 0.65))):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=r, location=(0, 0, z))
        set_mat(bpy.context.active_object, make_mat(f"{name}l{i}", (0.2 + i * 0.05, 0.55, 0.18), 0, 0.7))
    return join_meshes(name)


def grass(name):
    clear()
    for i in range(16):
        ang = i / 16 * math.pi * 2
        h = 0.3 + (i % 4) * 0.08
        bpy.ops.mesh.primitive_cube_add(
            size=1, location=(math.cos(ang) * 0.15, math.sin(ang) * 0.15, h / 2)
        )
        o = bpy.context.active_object
        o.scale = (0.04, 0.03, h)
        o.rotation_euler.z = ang
        bpy.ops.object.transform_apply(rotation=True, scale=True)
        set_mat(o, make_mat(f"{name}{i}", (0.25, 0.6, 0.2), 0, 0.85))
    return join_meshes(name)


def jar(name):
    clear()
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.3, depth=0.5, location=(0, 0, 0.3))
    set_mat(bpy.context.active_object, make_mat(name + "g", (0.7, 0.85, 0.9), 0.05, 0.15))
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=0.18, depth=0.08, location=(0, 0, 0.58))
    set_mat(bpy.context.active_object, make_mat(name + "l", (0.95, 0.75, 0.2), 0.9, 0.25))
    for i in range(4):
        bpy.ops.mesh.primitive_cylinder_add(
            vertices=16, radius=0.08, depth=0.03, location=(0.05 * (i % 2), 0.05 * (i // 2), 0.22 + i * 0.05)
        )
        set_mat(bpy.context.active_object, make_mat(f"{name}c{i}", (0.95, 0.75, 0.2), 0.9, 0.25))
    return join_meshes(name)


def duck(name):
    clear()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.35, location=(0, 0, 0.32))
    o = bpy.context.active_object
    o.scale = (1.15, 0.9, 0.85)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name + "y", (1, 0.85, 0.2), 0.05, 0.45))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.2, location=(0.3, 0, 0.55))
    set_mat(bpy.context.active_object, make_mat(name + "h", (1, 0.85, 0.2), 0.05, 0.45))
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.08, depth=0.14, location=(0.5, 0, 0.52))
    b = bpy.context.active_object
    b.rotation_euler.y = math.radians(90)
    bpy.ops.object.transform_apply(rotation=True)
    set_mat(b, make_mat(name + "b", (1, 0.45, 0.1), 0.05, 0.45))
    return join_meshes(name)


def pearl(name):
    clear()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=20, radius=0.35, location=(0, 0, 0.35))
    set_mat(bpy.context.active_object, make_mat(name, (0.1, 0.1, 0.14), 0.9, 0.1, 0.05))
    return join_meshes(name)


def keycard(name):
    clear()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.03))
    o = bpy.context.active_object
    o.scale = (0.6, 0.38, 0.03)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name, (0.35, 0.95, 0.7), 0.2, 0.35, 0.3))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.15, 0.05, 0.05))
    c = bpy.context.active_object
    c.scale = (0.1, 0.08, 0.015)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(c, make_mat(name + "c", (0.9, 0.75, 0.2), 0.8, 0.25))
    return join_meshes(name)


def eth(name):
    clear()
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.4, location=(0, 0, 0.45))
    o = bpy.context.active_object
    o.scale = (0.55, 0.55, 1.15)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name, (0.4, 0.5, 1), 0.35, 0.25, 0.45))
    return join_meshes(name)


def nebula(name):
    clear()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.3, location=(0, 0, 0.35))
    set_mat(bpy.context.active_object, make_mat(name, (0.65, 0.3, 1), 0.15, 0.2, 0.8))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=10, radius=0.18, location=(0.15, 0.1, 0.45))
    set_mat(bpy.context.active_object, make_mat(name + "2", (0.9, 0.3, 0.7), 0.1, 0.25, 0.6))
    return join_meshes(name)


def infinity_cent(name):
    clear()
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.06, location=(-0.12, 0, 0.3))
    set_mat(bpy.context.active_object, make_mat(name, (1, 1, 1), 0.95, 0.08, 0.5))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.06, location=(0.12, 0, 0.3))
    set_mat(bpy.context.active_object, make_mat(name + "2", (1, 1, 1), 0.95, 0.08, 0.5))
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=0.35, depth=0.08, location=(0, 0, 0.04))
    set_mat(bpy.context.active_object, make_mat(name + "c", (0.95, 0.95, 1), 0.9, 0.15, 0.2))
    return join_meshes(name)


def tooth(name):
    clear()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.25))
    o = bpy.context.active_object
    o.scale = (0.18, 0.18, 0.35)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name, (0.45, 0.85, 0.35), 0.1, 0.45))
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.16, location=(0, 0, 0.48))
    set_mat(bpy.context.active_object, make_mat(name + "t", (0.85, 0.9, 0.75), 0.05, 0.35))
    return join_meshes(name)


def ticket(name):
    clear()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.03))
    o = bpy.context.active_object
    o.scale = (0.7, 0.3, 0.025)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name, (1, 0.3, 0.55), 0.05, 0.55))
    return join_meshes(name)


def monopoly(name):
    clear()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.08))
    o = bpy.context.active_object
    o.scale = (0.55, 0.35, 0.04)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name, (1, 0.85, 0.15), 0.15, 0.4))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.18))
    h = bpy.context.active_object
    h.scale = (0.18, 0.14, 0.14)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(h, make_mat(name + "h", (0.9, 0.15, 0.12), 0.1, 0.45))
    return join_meshes(name)


def laurel(name):
    clear()
    gold = make_mat(name, (0.95, 0.78, 0.2), 0.9, 0.25)
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
            leaf.rotation_euler.z = ang * side
            bpy.ops.object.transform_apply(rotation=True, scale=True)
            set_mat(leaf, gold)
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.2, depth=0.05, location=(0, 0, 0.03))
    set_mat(bpy.context.active_object, gold)
    return join_meshes(name)


def bitcoin(name):
    clear()
    gold = (0.95, 0.65, 0.12)
    bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.5, depth=0.1, location=(0, 0, 0.05))
    set_mat(bpy.context.active_object, make_mat(name, gold, 0.9, 0.22))
    bpy.ops.mesh.primitive_cube_add(size=1, location=(-0.05, 0, 0.12))
    b = bpy.context.active_object
    b.scale = (0.08, 0.08, 0.32)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(b, make_mat(name + "g", (1, 0.78, 0.2), 0.85, 0.2))
    return join_meshes(name)


def bar(name, color):
    clear()
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.12))
    o = bpy.context.active_object
    o.scale = (0.9, 0.35, 0.22)
    bpy.ops.object.transform_apply(scale=True)
    set_mat(o, make_mat(name, color, 0.95, 0.18))
    return join_meshes(name)


def process(name, builder):
    print("BUILD", name)
    obj = builder()
    if not obj or len(obj.data.vertices) < 3:
        print("  FAIL empty", name)
        return None
    os.makedirs(EXPORT, exist_ok=True)
    os.makedirs(PREVIEWS, exist_ok=True)
    fbx = os.path.join(EXPORT, name + ".fbx")
    objp = os.path.join(EXPORT, name + ".obj")
    png = os.path.join(PREVIEWS, name + ".png")
    export_fbx(obj, fbx)
    try:
        export_obj(obj, objp)
    except Exception as e:
        print("  OBJ skip", e)
    # keep mesh for showcase: store in collection
    return obj, fbx, png


def main():
    os.makedirs(EXPORT, exist_ok=True)
    os.makedirs(PREVIEWS, exist_ok=True)

    jobs = [
        ("Penny", lambda: coin("Penny", (0.72, 0.42, 0.22), 0.45)),
        ("DollarBill", lambda: stack("DollarBill", (0.25, 0.65, 0.35))),
        ("FiveSpot", lambda: stack("FiveSpot", (0.3, 0.7, 0.4))),
        ("TwentyStack", lambda: stack("TwentyStack", (0.18, 0.55, 0.28), 10)),
        ("CoinJar", lambda: jar("CoinJar")),
        ("ZombieTooth", lambda: tooth("ZombieTooth")),
        ("ChuckEToken", lambda: coin("ChuckEToken", (1.0, 0.38, 0.18), 0.42)),
        ("MonopolyPiece", lambda: monopoly("MonopolyPiece")),
        ("PrizeTicket", lambda: ticket("PrizeTicket")),
        ("GoldDoubloon", lambda: coin("GoldDoubloon", (1.0, 0.78, 0.18), 0.5)),
        ("BlackPearl", lambda: pearl("BlackPearl")),
        ("RomanDenarius", lambda: coin("RomanDenarius", (0.82, 0.82, 0.86), 0.45)),
        ("GoldenLaurel", lambda: laurel("GoldenLaurel")),
        ("PlatinumCoin", lambda: coin("PlatinumCoin", (0.78, 0.85, 0.92), 0.48)),
        ("PlatinumBar", lambda: bar("PlatinumBar", (0.7, 0.78, 0.88))),
        ("VaultKeycard", lambda: keycard("VaultKeycard")),
        ("Bitcoin", lambda: bitcoin("Bitcoin")),
        ("Ethereum", lambda: eth("Ethereum")),
        ("JPEGDuck", lambda: duck("JPEGDuck")),
        ("StarFragment", lambda: eth("StarFragment")),  # crystal-like
        ("NebulaShard", lambda: nebula("NebulaShard")),
        ("DragonEgg", lambda: egg("DragonEgg")),
        ("InfinityCent", lambda: infinity_cent("InfinityCent")),
        ("OakTree", lambda: tree_oak("OakTree")),
        ("GrassClump", lambda: grass("GrassClump")),
    ]

    # Build each, export, render preview (each clear() isolates)
    results = []
    for name, fn in jobs:
        print("BUILD", name)
        obj = fn()
        if not obj:
            print("FAIL", name)
            continue
        v = len(obj.data.vertices)
        print(f"  verts={v}")
        if v < 3:
            print("FAIL empty mesh", name)
            continue
        fbx = os.path.join(EXPORT, name + ".fbx")
        png = os.path.join(PREVIEWS, name + ".png")
        export_fbx(obj, fbx)
        # verify reimport
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        # render before clear
        render_preview(obj, png)
        results.append((name, fbx, png, v))

    # Build showcase blend with all FBX reimported
    clear()
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    set_mat(bpy.context.active_object, make_mat("floor", (0.2, 0.2, 0.22), 0, 0.9))

    cols = 5
    spacing = 3.0
    for i, (name, fbx, png, v) in enumerate(results):
        row, col = divmod(i, cols)
        x = (col - 2) * spacing
        y = -row * spacing
        before = {o.name for o in bpy.data.objects}
        bpy.ops.import_scene.fbx(filepath=fbx)
        imported = [o for o in bpy.data.objects if o.name not in before]
        meshes = [o for o in imported if o.type == "MESH"]
        print(f"SHOWCASE import {name}: {len(meshes)} meshes verts={sum(len(m.data.vertices) for m in meshes)}")
        for o in meshes:
            o.location = (x, y, 0)
            o.name = name

    bpy.ops.object.camera_add(location=(0, -14, 9), rotation=(math.radians(58), 0, 0))
    bpy.context.scene.camera = bpy.context.active_object
    bpy.ops.object.light_add(type="SUN", location=(5, -3, 10))
    bpy.context.active_object.data.energy = 3

    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("SAVED", BLEND)
    print("TOTAL", len(results))
    for name, fbx, png, v in results:
        print(f"  {name}: verts={v} fbx={os.path.getsize(fbx)} png={os.path.isfile(png)}")


if __name__ == "__main__":
    main()
