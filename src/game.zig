const std = @import("std");

const rg = @import("raygui");
const rl = @import("raylib");
const slick = @import("slick");

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    const allocator = arena.allocator();

    var settings = slick.Settings{
        .allocator = allocator,
        .io = init.io,
    };
    try settings.load();

    rl.setConfigFlags(.{ .window_resizable = settings.settings.window_resizable, .fullscreen_mode = settings.settings.fullscreen });
    rl.initWindow(settings.settings.window_width, settings.settings.window_height, "slick");
    rl.setExitKey(.null);
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    rl.hideCursor();

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

    const scanlines_shader = try rl.loadShader(null, "assets/shaders/scanlines.fs");
    defer rl.unloadShader(scanlines_shader);

    // Get shader uniform location
    const time_loc = rl.getShaderLocation(scanlines_shader, "time");

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
    const active_gamepad = player1.setActiveGamepad();
    settings.controls.active_gamepad = active_gamepad;

    try players.append(allocator, &player1);
    try entities.append(allocator, &stack_entity);
    try entities.append(allocator, &stack_entity2);
    try entities.append(allocator, &player1.stack_entity);
    for (players.items) |player| if (player.stack_entity.is_local) camera.setTarget(&player.stack_entity.position);

    var volume_adjusted: f32 = 0;

    var gui = slick.Gui{};

    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.f11)) {
            rl.toggleFullscreen();
            settings.settings.fullscreen = !settings.settings.fullscreen;
            try settings.save();
        }
        if (rl.isKeyPressed(.f1)) {
            settings.settings.crt_enabled = !settings.settings.crt_enabled;
            try settings.save();
        }
        if (rl.isKeyPressed(.minus)) {
            if (settings.settings.volume > 0) settings.settings.volume -= 10;
            try settings.save();
            volume_adjusted = 60 * 1.5;
        }
        if (rl.isKeyPressed(.equal)) {
            if (settings.settings.volume < 100) settings.settings.volume += 10;
            try settings.save();
            volume_adjusted = 60 * 1.5;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.beginTextureMode(target);
        rl.clearBackground(rl.Color.init(128, 128, 128, 255));
        if (gui.mode == .MENU) {
            gui.renderMenu(active_gamepad);
        } else {
            if (rl.isKeyPressed(.escape) or (active_gamepad != -1 and rl.isGamepadButtonPressed(active_gamepad, .middle_right)))
                gui.mode = if (gui.mode == .PLAYING) .PAUSED else .PLAYING;

            for (entities.items) |entity| entity.handlePhysics(gui.mode, settings.controls);
            camera.update(rl.getFrameTime());

            // kept so we know we can do this
            // if (rl.isKeyDown(.z)) object_rotation -= speed;
            // if (rl.isKeyDown(.x)) object_rotation += speed;

            const time_value = rl.getTime();
            rl.setShaderValue(scanlines_shader, time_loc, &time_value, .float);

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

            renderHealth(textures_hud.items, player1.max_health, player1.health);

            if (volume_adjusted > 0) {
                volume_adjusted -= 1;
                renderVolume(textures_hud.items, settings.settings.volume);
            }
            gui.renderPaused();
        }
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

        if (settings.settings.crt_enabled) rl.beginShaderMode(scanlines_shader);
        rl.drawTexturePro(
            target.texture,
            .{ .x = 0, .y = 0, .width = internal_width, .height = -internal_height },
            dest_rect,
            .{ .x = 0, .y = 0 },
            0,
            rl.Color.white,
        );
        if (settings.settings.crt_enabled) rl.endShaderMode();
    }
    try settings.save();
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

fn renderVolume(textures: []rl.Texture2D, volume: u32) void {
    for (0..@intCast(volume / 10)) |i| {
        textures[2].draw(1240, 132 - @as(i32, @intCast(i)) * @as(i32, @intCast(textures[2].height - 2)), .white);
    }
}
