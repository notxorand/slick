const std = @import("std");
const rl = @import("raylib");
const SpriteStack = @import("../component/spritestack.zig");
const FloorZ = @import("../component/physics/floorz.zig");
const Control = @import("../component/control.zig");

const StackEntity = @This();

position: rl.Vector2,
rotation: f32,
stack: SpriteStack,
floorz: FloorZ = .{},
control: Control,

pub fn init(x: f32, y: f32, rotation: f32, textures: []rl.Texture, camera: *rl.Camera2D, controlled: bool) StackEntity {
    const position = rl.Vector2{ .x = x, .y = y };

    return StackEntity{
        .position = position,
        .rotation = rotation,
        .stack = SpriteStack{ .rotation = rotation, .textures = textures },
        .control = .init(controlled, position, camera),
    };
}

pub fn render(self: StackEntity, camera: rl.Camera2D) void {
    const position = rl.getWorldToScreen2D(self.position, camera);

    _ = self.stack.render(position.x, position.y, -(self.rotation - camera.rotation), camera.zoom);
}

pub fn handlePhysics(self: *StackEntity) void {
    self.control.handle();
    const dx = self.control.position.x - self.position.x;
    const dy = self.control.position.y - self.position.y;
    self.floorz.calculateRotation(dx, dy, &self.rotation);
    self.position.x = self.control.position.x;
    self.position.y = self.control.position.y;

    // TODO: physics bodies and collisions
}

pub fn sortY(self: StackEntity, camera: rl.Camera2D) f32 {
    return rl.getWorldToScreen2D(self.position, camera).y;
}
