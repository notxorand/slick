const std = @import("std");

const rl = @import("raylib");

const Control = @This();

position: rl.Vector2,
speed: f32 = 4.0,
camera: *rl.Camera2D,
enabled: bool,
active_gamepad: i32 = -1,
focused: bool = true,

pub fn init(enabled: bool, position: rl.Vector2, camera: *rl.Camera2D) Control {
    return Control{
        .enabled = enabled,
        .position = position,
        .camera = camera,
    };
}

pub fn setActiveGamepad(self: *Control, active_gamepad: i32) void {
    if (self.enabled) self.active_gamepad = active_gamepad;
}

pub fn handle(self: *Control) void {
    if (!self.enabled) return;

    const camera_rad = self.camera.*.rotation * (std.math.pi / 180.0);
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

    const active_gamepad = self.active_gamepad;

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

    if (active_gamepad != -1) {
        move_vec.x = gamepad_left_x;
        move_vec.y = -gamepad_left_y;
    }

    if (rl.isKeyDown(.w) or dpad_up) move_vec.y = 1.0;
    if (rl.isKeyDown(.s) or dpad_down) move_vec.y = -1.0;
    if (rl.isKeyDown(.a) or dpad_left) move_vec.x = -1.0;
    if (rl.isKeyDown(.d) or dpad_right) move_vec.x = 1.0;

    // Apply deadzone and normalize
    const length = @sqrt(move_vec.x * move_vec.x + move_vec.y * move_vec.y);
    if (length < deadzone) {
        move_vec = rl.Vector2{ .x = 0, .y = 0 };
    } else {
        const speed_multiplier = @min(length, 1.0);
        move_vec.x = (move_vec.x / length) * speed_multiplier;
        move_vec.y = (move_vec.y / length) * speed_multiplier;
    }

    if (length > 0) {
        // Rotate move_vec by camera angle
        const final_move_x = (move_vec.x * right.x) + (move_vec.y * forward.x);
        const final_move_y = (move_vec.x * right.y) + (move_vec.y * forward.y);

        self.position.x += final_move_x * self.speed;
        self.position.y += final_move_y * self.speed;
    }

    // Pan Camera with Right Stick (or QE)
    if (rl.isKeyDown(.q) or gamepad_right_x < -deadzone) self.camera.*.rotation += 1.5;
    if (rl.isKeyDown(.e) or gamepad_right_x > deadzone) self.camera.*.rotation -= 1.5;
}
