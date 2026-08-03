const std = @import("std");
const rl = @import("raylib");
const SpriteStack = @import("../component/spritestack.zig");
const FloorZ = @import("../component/physics/floorz.zig");
const Control = @import("../component/control.zig");
const Camera = @import("../camera.zig");

const StackEntity = @This();

position: rl.Vector2,
rotation: f32,
stack: SpriteStack,
floorz: FloorZ = .{},
control: Control,
is_local: bool = false,
camera: *Camera,

pub fn init(x: f32, y: f32, rotation: f32, textures: []rl.Texture, camera: *Camera) StackEntity {
    const position = rl.Vector2{ .x = x, .y = y };

    return StackEntity{
        .position = position,
        .rotation = rotation,
        .stack = SpriteStack{ .rotation = rotation, .textures = textures },
        .control = .init(false, position, &camera.camera),
        .camera = camera,
    };
}

pub fn render(self: StackEntity) void {
    const position = rl.getWorldToScreen2D(self.position, self.camera.camera);

    _ = self.stack.render(position.x, position.y, -(self.rotation - self.camera.camera.rotation), self.camera.camera.zoom);
}

pub fn handlePhysics(self: *StackEntity) void {
    if (self.is_local) self.control.handle();
    const dx = self.control.position.x - self.position.x;
    const dy = self.control.position.y - self.position.y;
    self.floorz.calculateRotation(dx, dy, &self.rotation);
    self.position.x = self.control.position.x;
    self.position.y = self.control.position.y;

    // TODO: physics bodies and collisions
}

pub fn sortY(self: StackEntity) f32 {
    return rl.getWorldToScreen2D(self.position, self.camera.camera).y;
}
