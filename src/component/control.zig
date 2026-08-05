const std = @import("std");

const rl = @import("raylib");

const Controls = @import("../controls.zig");

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

pub fn handle(self: *Control, input: Controls) void {
    if (!self.enabled) return;

    const camera_rad = self.camera.*.rotation * (std.math.pi / 180.0);
    const cos_a = @cos(camera_rad);
    const sin_a = @sin(camera_rad);
    const forward = rl.Vector2{ .x = -sin_a, .y = -cos_a };
    const right = rl.Vector2{ .x = cos_a, .y = -sin_a };

    var move_vec = rl.Vector2{ .x = 0, .y = 0 };
    const gamepad_axis_x: rl.GamepadAxis = if (input.controls.swap_sticks) .left_x else .right_x;
    const gamepad_axis_y: rl.GamepadAxis = if (input.controls.swap_sticks) .left_y else .right_y;
    if (self.active_gamepad != -1) {
        move_vec.x = rl.getGamepadAxisMovement(self.active_gamepad, gamepad_axis_x);
        move_vec.y -= rl.getGamepadAxisMovement(self.active_gamepad, gamepad_axis_y);
    }

    if (input.isNorth()) move_vec.y = 1.0;
    if (input.isSouth()) move_vec.y = -1.0;
    if (input.isWest()) move_vec.x = -1.0;
    if (input.isEast()) move_vec.x = 1.0;

    const length = @sqrt(move_vec.x * move_vec.x + move_vec.y * move_vec.y);
    if (length > 0.2) {
        const final_move_x = (move_vec.x * right.x) + (move_vec.y * forward.x);
        const final_move_y = (move_vec.x * right.y) + (move_vec.y * forward.y);

        self.position.x += final_move_x * self.speed;
        self.position.y += final_move_y * self.speed;
    }

    if (input.isRotatingCameraLeft()) self.camera.*.rotation += 1.5;
    if (input.isRotatingCameraRight()) self.camera.*.rotation -= 1.5;

    self.camera.*.target.x = self.position.x;
    self.camera.*.target.y = self.position.y;
}
