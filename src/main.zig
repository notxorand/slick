const std = @import("std");
const slick = @import("slick");
const rl = @import("raylib");
const rg = @import("raygui");

const SortCtx = struct {
    const Self = @This();
    camera: rl.Camera2D,
    fn lessThan(ctx: Self, a: slick.StackEntity, b: slick.StackEntity) bool {
        return a.sortY(ctx.camera) < b.sortY(ctx.camera);
    }
};

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    rl.initWindow(960, 560, "slick");
    rl.setTargetFPS(60);
    rl.hideCursor();

    const allocator = arena.allocator();
    var textures = try std.ArrayList(rl.Texture2D).initCapacity(allocator, 16);
    const image = try rl.Image.init("./assets/simple_s.png");
    for (0..16) |_| {
        const texture = try rl.Texture.fromImage(image);
        try textures.append(allocator, texture);
        rl.setTextureFilter(texture, .point);
    }

    const screen_center = rl.Vector2{ .x = 480, .y = 280 };
    var camera = rl.Camera2D{
        .offset = screen_center,
        .target = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .zoom = 1,
    };

    var entities: std.ArrayList(slick.StackEntity) = .empty;

    var object_rotation: f32 = 0;
    const stack_entity = slick.StackEntity.init(0, 0, object_rotation, textures.items);
    const stack_entity2 = slick.StackEntity.init(32, 0, object_rotation, textures.items);
    try entities.append(allocator, stack_entity);
    try entities.append(allocator, stack_entity2);

    while (!rl.windowShouldClose()) {
        const speed = 2.0;
        if (rl.isKeyDown(.w)) camera.target.y += speed;
        if (rl.isKeyDown(.s)) camera.target.y -= speed;
        if (rl.isKeyDown(.a)) camera.target.x += speed;
        if (rl.isKeyDown(.d)) camera.target.x -= speed;
        if (rl.isKeyDown(.q)) camera.rotation += speed;
        if (rl.isKeyDown(.e)) camera.rotation -= speed;
        if (rl.isKeyDown(.z)) object_rotation += speed;
        if (rl.isKeyDown(.x)) object_rotation -= speed;
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.init(128, 128, 128, 255));

        std.mem.sort(slick.StackEntity, entities.items, SortCtx{ .camera = camera }, SortCtx.lessThan);
        for (entities.items) |entity| {
            entity.render(camera, object_rotation); // there's has to be a better way than passing object_rotation to every render call
        }
    }

    rl.closeWindow();
}
