const std = @import("std");
const slick = @import("slick");
const rl = @import("raylib");
const rg = @import("raygui");

const SortCtx = struct {
    const Self = @This();
    camera: rl.Camera2D,
    fn lessThan(ctx: Self, a: *slick.StackEntity, b: *slick.StackEntity) bool {
        return a.sortY(ctx.camera) < b.sortY(ctx.camera);
    }
};

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    rl.initWindow(1280, 720, "slick");
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

    var textures2 = try loadTexturesFromFolder(allocator, init.io, "./assets/sprites/car");
    defer textures2.deinit(allocator);
    // const scanlines_shader = try rl.loadShader(null, "assets/shaders/scanlines.fs");
    // defer rl.unloadShader(scanlines_shader);

    // Get shader uniform location
    // const time_loc = rl.getShaderLocation(scanlines_shader, "time");

    const screen_center = rl.Vector2{ .x = 640, .y = 360 };
    var control_position = rl.Vector2{ .x = 32, .y = 32 };
    var camera = rl.Camera2D{
        .offset = screen_center,
        .target = control_position,
        .rotation = 0,
        .zoom = 1,
    };
    // const texture = textures.items[0];

    var entities: std.ArrayList(*slick.StackEntity) = .empty;
    // Calibrate/Verify gamepad
    var active_gamepad: i32 = -1;
    for (0..4) |i| {
        if (rl.isGamepadAvailable(@intCast(i))) {
            const name = rl.getGamepadName(@intCast(i));
            // Filter out the touchpad (SYNA) to find the actual wireless controller
            // This affected my machine (Linux), displaying my mouse as a controller
            if (std.mem.indexOf(u8, name, "SYNA") == null) {
                active_gamepad = @intCast(i);
                std.debug.print("Gamepad {d} detected: {s}\n", .{ i, name });
                break;
            }
        }
    }

    var object_rotation: f32 = 0.0;
    var angular_velocity: f32 = 0.0;
    var stack_entity = slick.StackEntity.init(0, 0, 0, textures.items);
    var stack_entity2 = slick.StackEntity.init(32, 0, 0, textures.items);
    var controlled_entity = slick.StackEntity.init(32, 32, object_rotation, textures2.items);
    controlled_entity.controlled = true;
    try entities.append(allocator, &stack_entity);
    try entities.append(allocator, &stack_entity2);
    try entities.append(allocator, &controlled_entity);

    while (!rl.windowShouldClose()) {
        const speed = 4.0;

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

        const gamepad_left_x = if (active_gamepad != -1) rl.getGamepadAxisMovement(active_gamepad, .left_x) else 0;
        const gamepad_left_y = if (active_gamepad != -1) rl.getGamepadAxisMovement(active_gamepad, .left_y) else 0;
        const gamepad_right_x = if (active_gamepad != -1) rl.getGamepadAxisMovement(active_gamepad, .right_x) else 0;

        const deadzone = 0.2;

        const dpad_up = if (active_gamepad != -1) rl.isGamepadButtonDown(active_gamepad, .left_face_up) else false;
        const dpad_down = if (active_gamepad != -1) rl.isGamepadButtonDown(active_gamepad, .left_face_down) else false;
        const dpad_left = if (active_gamepad != -1) rl.isGamepadButtonDown(active_gamepad, .left_face_left) else false;
        const dpad_right = if (active_gamepad != -1) rl.isGamepadButtonDown(active_gamepad, .left_face_right) else false;

        // Calculate movement vector
        var move_vec = rl.Vector2{ .x = 0, .y = 0 };

        if (rl.isKeyDown(.w) or gamepad_left_y < -deadzone or dpad_up) move_vec.y += 1;
        if (rl.isKeyDown(.s) or gamepad_left_y > deadzone or dpad_down) move_vec.y -= 1;
        if (rl.isKeyDown(.a) or gamepad_left_x < -deadzone or dpad_left) move_vec.x -= 1;
        if (rl.isKeyDown(.d) or gamepad_left_x > deadzone or dpad_right) move_vec.x += 1;

        // Normalize and apply speed
        const length = @sqrt(move_vec.x * move_vec.x + move_vec.y * move_vec.y);
        if (length > 0) {
            move_vec.x /= length;
            move_vec.y /= length;

            // Rotate move_vec by camera angle
            const final_move_x = (move_vec.x * right.x) + (move_vec.y * forward.x);
            const final_move_y = (move_vec.x * right.y) + (move_vec.y * forward.y);

            control_position.x += final_move_x * speed;
            control_position.y += final_move_y * speed;
        }

        // Pan Camera with Right Stick (or QE)
        if (rl.isKeyDown(.q) or gamepad_right_x < -deadzone) camera.rotation += speed;
        if (rl.isKeyDown(.e) or gamepad_right_x > deadzone) camera.rotation -= speed;

        {
            camera.target.x = control_position.x;
            camera.target.y = control_position.y;
            for (entities.items) |entity| {
                if (entity.controlled) {
                    const dx = control_position.x - entity.position.x;
                    const dy = control_position.y - entity.position.y;

                    if (dx != 0 or dy != 0) {
                        const target_angle = (std.math.atan2(dy, -dx) * 180.0 / std.math.pi) + 90.0;

                        // Physics Constants
                        const angular_acceleration = 0.01; // How hard it tries to turn
                        const friction = 0.85; // How much it resists continuing to spin

                        // 1. Calculate the shortest diff
                        var diff = target_angle - object_rotation;
                        while (diff > 180) diff -= 360;
                        while (diff < -180) diff += 360;

                        // 2. Apply torque (angular acceleration) based on direction
                        angular_velocity += (diff * angular_acceleration);

                        // 3. Apply friction
                        angular_velocity *= friction;

                        // 4. Apply to rotation
                        object_rotation += angular_velocity;
                    }

                    entity.position.x = control_position.x;
                    entity.position.y = control_position.y;
                }
            }
        }
        // kept so we know we can do this
        // if (rl.isKeyDown(.z)) object_rotation -= speed;
        // if (rl.isKeyDown(.x)) object_rotation += speed;

        // const time_value = rl.getTime();
        // rl.setShaderValue(scanlines_shader, time_loc, &time_value, .float);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.init(128, 128, 128, 255));
        // rl.beginShaderMode(scanlines_shader);
        // defer rl.endShaderMode();
        rl.beginMode2D(camera);
        // rl.drawTexturePro(
        //     texture,
        //     .{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) },
        //     .{ .x = control_position.x, .y = control_position.y, .width = @as(f32, @floatFromInt(texture.width)), .height = @as(f32, @floatFromInt(texture.height)) },
        //     .{ .x = @as(f32, @floatFromInt(texture.width)), .y = @as(f32, @floatFromInt(texture.height)) },
        //     -camera.rotation,
        //     rl.Color.white,
        // );
        rl.endMode2D();

        // TODO: sort billboard sprites as well
        std.mem.sort(*slick.StackEntity, entities.items, SortCtx{ .camera = camera }, SortCtx.lessThan);
        for (entities.items) |entity| {
            // there's has to be a better way than passing object_rotation to every render call
            if (entity.controlled) {
                entity.render(camera, object_rotation);
            } else {
                entity.render(camera, 0);
            }
        }
    }

    rl.closeWindow();
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
