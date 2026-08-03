const std = @import("std");

const rl = @import("raylib");

const StackEntity = @import("../entity/stackentity.zig");
const Camera = @import("../camera.zig");

stack_entity: StackEntity,
id: u32,

const Player = @This();

pub fn init(id: u32, x: f32, y: f32, rotation: f32, textures: []rl.Texture, camera: *Camera) Player {
    var stack_entity = StackEntity.init(x, y, rotation, textures, camera);
    stack_entity.control.enabled = true;
    return Player{
        .stack_entity = stack_entity,
        .id = id,
    };
}

pub fn setLocal(self: *Player, is_local: bool) void {
    self.stack_entity.is_local = is_local;
}

pub fn setActiveGamepad(self: *Player) void {
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
    self.stack_entity.control.setActiveGamepad(active_gamepad);
}
