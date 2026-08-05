const std = @import("std");
const rl = @import("raylib");

const Controls = @This();

const FILE_NAME = "controls";

active_gamepad: i32 = -1,
controls: ControlsData = .{},

const ControlsData = struct {
    // Configurable keys
    key_north: i32 = @intFromEnum(rl.KeyboardKey.w),
    key_south: i32 = @intFromEnum(rl.KeyboardKey.s),
    key_west: i32 = @intFromEnum(rl.KeyboardKey.a),
    key_east: i32 = @intFromEnum(rl.KeyboardKey.d),
    key_drift: i32 = @intFromEnum(rl.KeyboardKey.space),
    key_fire: i32 = @intFromEnum(rl.KeyboardKey.i),
    key_speed_boost: i32 = @intFromEnum(rl.KeyboardKey.left_shift),
    key_artillery_boost: i32 = @intFromEnum(rl.KeyboardKey.j),
    key_cam_left: i32 = @intFromEnum(rl.KeyboardKey.q),
    key_cam_right: i32 = @intFromEnum(rl.KeyboardKey.e),
    key_pause: i32 = @intFromEnum(rl.KeyboardKey.escape),

    // Configurable gamepad buttons
    btn_north: i32 = @intFromEnum(rl.GamepadButton.left_face_up),
    btn_south: i32 = @intFromEnum(rl.GamepadButton.left_face_down),
    btn_west: i32 = @intFromEnum(rl.GamepadButton.left_face_left),
    btn_east: i32 = @intFromEnum(rl.GamepadButton.left_face_right),
    btn_drift: i32 = @intFromEnum(rl.GamepadButton.left_trigger_2),
    btn_fire: i32 = @intFromEnum(rl.GamepadButton.right_trigger_2),
    btn_speed_boost: i32 = @intFromEnum(rl.GamepadButton.right_face_down),
    btn_artillery_boost: i32 = @intFromEnum(rl.GamepadButton.right_face_right),
    btn_cam_left: i32 = @intFromEnum(rl.GamepadButton.left_trigger_1),
    btn_cam_right: i32 = @intFromEnum(rl.GamepadButton.right_trigger_1),
    btn_pause_start: i32 = @intFromEnum(rl.GamepadButton.middle_right),
    btn_pause_select: i32 = @intFromEnum(rl.GamepadButton.middle_left),

    swap_sticks: bool = false,
};

// Action Mappings
pub fn isNorth(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_north));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_north));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isSouth(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_south));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_south));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isWest(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_west));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_west));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isEast(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_east));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_east));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isDrifting(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_drift));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_drift));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isFiring(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_fire));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_fire));
    if (rl.isKeyDown(key) or rl.isMouseButtonDown(.left)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isSpeedBoosting(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_speed_boost));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_speed_boost));
    if (rl.isKeyPressed(key) or rl.isKeyPressed(.o)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonPressed(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isArtilleryBoosting(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_artillery_boost));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_artillery_boost));
    if (rl.isKeyPressed(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonPressed(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isRotatingCameraLeft(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_cam_left));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_cam_left));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isRotatingCameraRight(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_cam_right));
    const btn = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_cam_right));
    if (rl.isKeyDown(key)) return true;
    if (self.active_gamepad != -1 and rl.isGamepadButtonDown(self.active_gamepad, btn)) return true;
    return false;
}

pub fn isPausing(self: Controls) bool {
    const key = @as(rl.KeyboardKey, @enumFromInt(self.controls.key_pause));
    const btn_start = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_pause_start));
    const btn_select = @as(rl.GamepadButton, @enumFromInt(self.controls.btn_pause_select));
    if (rl.isKeyPressed(key)) return true;
    if (self.active_gamepad != -1 and (rl.isGamepadButtonPressed(self.active_gamepad, btn_start) or rl.isGamepadButtonPressed(self.active_gamepad, btn_select))) return true;
    return false;
}

pub fn load(self: *Controls, allocator: std.mem.Allocator, io: std.Io) !void {
    var buffer: [4096]u8 = undefined;
    const contents = std.Io.Dir.readFile(std.Io.Dir.cwd(), io, FILE_NAME, &buffer) catch |err| switch (err) {
        std.Io.File.OpenError.FileNotFound => {
            _ = std.Io.Dir.cwd().createFile(io, FILE_NAME, .{}) catch |create_err| return create_err;
            return;
        },
        else => return err,
    };
    if (contents.len == 0) return;
    const content = try allocator.allocSentinel(u8, contents.len, 0);

    @memcpy(content, contents);
    comptime {
        @setEvalBranchQuota(1600);
    }
    const parsed = try std.zon.parse.fromSliceAlloc(ControlsData, allocator, content, null, .{ .ignore_unknown_fields = true });

    self.controls.key_drift = parsed.key_drift;
    self.controls.key_fire = parsed.key_fire;
    self.controls.key_speed_boost = parsed.key_speed_boost;
    self.controls.key_artillery_boost = parsed.key_artillery_boost;
    self.controls.key_cam_left = parsed.key_cam_left;
    self.controls.key_cam_right = parsed.key_cam_right;
    self.controls.key_pause = parsed.key_pause;
    self.controls.btn_drift = parsed.btn_drift;
    self.controls.btn_fire = parsed.btn_fire;
    self.controls.btn_speed_boost = parsed.btn_speed_boost;
    self.controls.btn_artillery_boost = parsed.btn_artillery_boost;
    self.controls.btn_cam_left = parsed.btn_cam_left;
    self.controls.btn_cam_right = parsed.btn_cam_right;
    self.controls.btn_pause_start = parsed.btn_pause_start;
    self.controls.btn_pause_select = parsed.btn_pause_select;
    self.controls.key_north = parsed.key_north;
    self.controls.key_south = parsed.key_south;
    self.controls.key_west = parsed.key_west;
    self.controls.key_east = parsed.key_east;
    self.controls.btn_north = parsed.btn_north;
    self.controls.btn_south = parsed.btn_south;
    self.controls.btn_west = parsed.btn_west;
    self.controls.btn_east = parsed.btn_east;
    self.controls.swap_sticks = parsed.swap_sticks;
}

pub fn save(self: *Controls, io: std.Io) !void {
    // having a backup is always a good idea :)
    try std.Io.Dir.cwd().copyFile(FILE_NAME, .cwd(), "controls.bak", io, .{});
    // we create a new file here cause the file's buffer size might not align with the incoming data size from our serialisation which might leave artifacts
    const file = try std.Io.Dir.cwd().createFile(io, FILE_NAME, .{});
    defer file.close(io);

    var writer = file.writer(io, &.{});
    try std.zon.stringify.serialize(self.controls, .{}, &writer.interface);

    try writer.interface.flush();
}
