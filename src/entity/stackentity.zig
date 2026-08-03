const std = @import("std");
const rl = @import("raylib");
const SpriteStack = @import("../component/spritestack.zig");
const FloorZ = @import("../physics/floorz.zig");

const StackEntity = @This();

position: rl.Vector2,
rotation: f32,
stack: SpriteStack,
floorz: FloorZ = .{},
controlled: bool = false,

pub fn init(x: f32, y: f32, rotation: f32, textures: []rl.Texture) StackEntity {
    return StackEntity{
        .position = rl.Vector2{ .x = x, .y = y },
        .rotation = rotation,
        .stack = SpriteStack{ .rotation = rotation, .textures = textures },
    };
}

pub fn render(self: StackEntity, camera: rl.Camera2D) void {
    const position = rl.getWorldToScreen2D(self.position, camera);

    _ = self.stack.render(position.x, position.y, -(self.rotation - camera.rotation), camera.zoom);
}

pub fn handlePhysics(self: *StackEntity, control_position: rl.Vector2) void {
    const dx = control_position.x - self.position.x;
    const dy = control_position.y - self.position.y;
    self.floorz.calculateRotation(dx, dy, &self.rotation);
    self.position.x = control_position.x;
    self.position.y = control_position.y;

    // TODO: physics bodies and collisions
}

pub fn sortY(self: StackEntity, camera: rl.Camera2D) f32 {
    return rl.getWorldToScreen2D(self.position, camera).y;
}
