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
    var control_position = rl.Vector2{ .x = 0, .y = 0 };
    var camera = rl.Camera2D{
        .offset = screen_center,
        .target = control_position,
        .rotation = 0,
        .zoom = 1,
    };
    const texture = textures.items[0];

    var entities: std.ArrayList(slick.StackEntity) = .empty;

    var object_rotation: f32 = 0;
    const stack_entity = slick.StackEntity.init(0, 0, object_rotation, textures.items);
    const stack_entity2 = slick.StackEntity.init(32, 0, object_rotation, textures.items);
    try entities.append(allocator, stack_entity);
    try entities.append(allocator, stack_entity2);

    while (!rl.windowShouldClose()) {
        const speed = 2.0;

        const camera_rad = camera.rotation * (std.math.pi / 180.0);
        const cos_a = @cos(camera_rad);
        const sin_a = @sin(camera_rad);
        const forward = rl.Vector2{
            .x = -sin_a,
            .y = -cos_a,
        };

        const right = rl.Vector2{
            .x = cos_a,
            .y = -sin_a,
        };

        const frame_speed = speed;

        if (rl.isKeyDown(.w)) {
            control_position.x += forward.x * frame_speed;
            control_position.y += forward.y * frame_speed;
        }
        if (rl.isKeyDown(.s)) {
            control_position.x -= forward.x * frame_speed;
            control_position.y -= forward.y * frame_speed;
        }
        if (rl.isKeyDown(.a)) {
            control_position.x -= right.x * frame_speed;
            control_position.y -= right.y * frame_speed;
        }
        if (rl.isKeyDown(.d)) {
            control_position.x += right.x * frame_speed;
            control_position.y += right.y * frame_speed;
        }
        {
            camera.target.x = control_position.x;
            camera.target.y = control_position.y;
        }
        if (rl.isKeyDown(.q)) camera.rotation += speed;
        if (rl.isKeyDown(.e)) camera.rotation -= speed;
        if (rl.isKeyDown(.z)) object_rotation += speed;
        if (rl.isKeyDown(.x)) object_rotation -= speed;
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.init(128, 128, 128, 255));
        rl.beginMode2D(camera);

        rl.drawTexturePro(
            texture,
            .{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) },
            .{ .x = control_position.x, .y = control_position.y, .width = @as(f32, @floatFromInt(texture.width)), .height = @as(f32, @floatFromInt(texture.height)) },
            .{ .x = @as(f32, @floatFromInt(texture.width)), .y = @as(f32, @floatFromInt(texture.height)) },
            -camera.rotation,
            rl.Color.white,
        );
        rl.endMode2D();

        // TODO: sort billboard sprites as well
        std.mem.sort(slick.StackEntity, entities.items, SortCtx{ .camera = camera }, SortCtx.lessThan);
        for (entities.items) |entity| {
            entity.render(camera, object_rotation); // there's has to be a better way than passing object_rotation to every render call
        }
    }

    rl.closeWindow();
}
