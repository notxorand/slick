const std = @import("std");

const rg = @import("raygui");
const rl = @import("raylib");
const slick = @import("slick");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    rl.initWindow(1280, 720, "slick");
    defer rl.closeWindow();
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

    var textures2 = try loadTexturesFromFolder(allocator, init.io, "./assets/sprites/car2");
    defer textures2.deinit(allocator);

    var textures_hud = try loadTexturesFromFolder(allocator, init.io, "./assets/sprites/hud");
    defer textures_hud.deinit(allocator);

    // const scanlines_shader = try rl.loadShader(null, "assets/shaders/scanlines.fs");
    // defer rl.unloadShader(scanlines_shader);

    // Get shader uniform location
    // const time_loc = rl.getShaderLocation(scanlines_shader, "time");

    const internal_width = 1280;
    const internal_height = 720;
    var target = try rl.loadRenderTexture(internal_width, internal_height);
    defer target.unload();
    rl.setTextureFilter(target.texture, .point);
    const screen_center = rl.Vector2{ .x = internal_width / 2.0, .y = internal_height / 2.0 };
    var camera = slick.Camera.init(screen_center);
    // const texture = textures.items[0];

    var entities: std.ArrayList(*slick.StackEntity) = .empty;
    var players: std.ArrayList(*slick.Player) = .empty;

    const object_rotation: f32 = 0.0;
    var stack_entity = slick.StackEntity.init(0, 0, 0, textures.items, &camera);
    var stack_entity2 = slick.StackEntity.init(30, 0, 0, textures.items, &camera);
    var player1 = slick.Player.init(0, 32, 32, object_rotation, textures2.items, &camera);
    player1.setLocal(true);
    player1.setActiveGamepad();

    try players.append(allocator, &player1);
    try entities.append(allocator, &stack_entity);
    try entities.append(allocator, &stack_entity2);
    try entities.append(allocator, &player1.stack_entity);
    for (players.items) |player| if (player.stack_entity.is_local) camera.setTarget(&player.stack_entity.position);

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.f11)) rl.toggleFullscreen();

        for (entities.items) |entity| entity.handlePhysics();
        camera.update(rl.getFrameTime());

        // kept so we know we can do this
        // if (rl.isKeyDown(.z)) object_rotation -= speed;
        // if (rl.isKeyDown(.x)) object_rotation += speed;

        // const time_value = rl.getTime();
        // rl.setShaderValue(scanlines_shader, time_loc, &time_value, .float);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginTextureMode(target);
        rl.clearBackground(rl.Color.init(128, 128, 128, 255));

        // Sort using world Y coordinate
        std.mem.sort(*slick.StackEntity, entities.items, {}, struct {
            fn lessThan(_: void, a: *slick.StackEntity, b: *slick.StackEntity) bool {
                return a.sortY() < b.sortY();
            }
        }.lessThan);

        // there's has to be a better way than passing object_rotation to every render call
        for (entities.items) |entity| {
            const screen_pos = rl.getWorldToScreen2D(entity.position, entity.camera.camera);

            // culling: don't render if outside the screen bounds
            if (screen_pos.x > -100 and screen_pos.x < internal_width + @as(f32, @floatFromInt(entity.stack.textures[0].width)) and
                screen_pos.y > -100 and screen_pos.y < internal_height + @as(f32, @floatFromInt(entity.stack.textures[0].height)) + entity.stack.stack_height) entity.render();
        }
        renderHealth(textures_hud.items, 6, 4);
        rl.endTextureMode();

        rl.clearBackground(rl.Color.black);
        const screen_w = @as(f32, @floatFromInt(rl.getScreenWidth()));
        const screen_h = @as(f32, @floatFromInt(rl.getScreenHeight()));
        const scale = @min(screen_w / internal_width, screen_h / internal_height);
        const dest_rect = rl.Rectangle{
            .x = (screen_w - (internal_width * scale)) / 2,
            .y = (screen_h - (internal_height * scale)) / 2,
            .width = internal_width * scale,
            .height = internal_height * scale,
        };

        rl.drawTexturePro(
            target.texture,
            .{ .x = 0, .y = 0, .width = internal_width, .height = -internal_height },
            dest_rect,
            .{ .x = 0, .y = 0 },
            0,
            rl.Color.white,
        );
    }
}

fn loadTexturesFromFolder(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !std.ArrayList(rl.Texture2D) {
    var textures = std.ArrayList(rl.Texture2D).empty;
    var image_paths = std.ArrayList([]const u8).empty;
    defer image_paths.deinit(allocator);

    var dir = try std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true });
    defer dir.close(io);

    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".png")) {
            const full_path = try std.fs.path.join(allocator, &[_][]const u8{ path, entry.name });
            try image_paths.append(allocator, full_path);
        }
    }

    sortFileNameById(&image_paths);

    for (image_paths.items) |full_path| {
        const full_path_terminated = try allocator.allocSentinel(u8, full_path.len, 0);
        @memcpy(full_path_terminated, full_path);
        defer allocator.free(full_path_terminated);

        const image = try rl.Image.init(full_path_terminated);
        defer rl.unloadImage(image);

        const texture = try rl.Texture.fromImage(image);
        rl.setTextureFilter(texture, .point);

        try textures.append(allocator, texture);
    }
    return textures;
}

fn sortFileNameById(image_paths: *std.ArrayList([]const u8)) void {
    std.mem.sort([]const u8, image_paths.items, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            var id_a: usize = 0;
            var id_b: usize = 0;

            while (id_a < a.len and id_b < b.len) {
                if (std.ascii.isDigit(a[id_a]) and std.ascii.isDigit(b[id_b])) {
                    var num_a: usize = 0;
                    var num_b: usize = 0;

                    var temp_id_a = id_a;
                    while (temp_id_a < a.len and std.ascii.isDigit(a[temp_id_a])) {
                        num_a = num_a * 10 + (a[temp_id_a] - '0');
                        temp_id_a += 1;
                    }

                    var temp_id_b = id_b;
                    while (temp_id_b < b.len and std.ascii.isDigit(b[temp_id_b])) {
                        num_b = num_b * 10 + (b[temp_id_b] - '0');
                        temp_id_b += 1;
                    }

                    if (num_a != num_b) {
                        return num_a < num_b;
                    }

                    id_a = temp_id_a;
                    id_b = temp_id_b;
                } else if (std.ascii.isDigit(a[id_a])) {
                    // 'a' has a digit, 'b' has a non-digit: 'b' comes first (e.g., "car" < "car1")
                    return false;
                } else if (std.ascii.isDigit(b[id_b])) {
                    // 'b' has a digit, 'a' has a non-digit: 'a' comes first (e.g., "car1" > "car")
                    return true;
                } else {
                    // Both are non-digits, compare character by character
                    if (a[id_a] != b[id_b]) {
                        return a[id_a] < b[id_b];
                    }
                    id_a += 1;
                    id_b += 1;
                }
            }

            return id_a < id_b;
        }
    }.lessThan);
}

fn renderHealth(textures: []rl.Texture2D, total_health: u32, health: u32) void {
    for (0..total_health) |i| {
        textures[1].draw(1240 - @as(i32, @intCast(i)) * 14, 680, .white);
    }
    for (0..health) |i| {
        textures[0].draw(1240 - @as(i32, @intCast(i)) * 14, 680, .white);
    }
}
