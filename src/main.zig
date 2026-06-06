const std = @import("std");
const slick = @import("slick");
const rl = @import("raylib");
const rg = @import("raygui");

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
        try textures.append(arena.allocator(), texture);
        rl.setTextureFilter(texture, .point);
    }
    var frame: f32 = 0;

    while (!rl.windowShouldClose()) {
        frame += 1;
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.ray_white);
        const texture_r = slick.SpriteStack{ .rotation = frame, .scale = 2, .textures = textures.items };
        texture_r.render(480, 280);
    }

    rl.closeWindow();
}
