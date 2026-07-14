const std = @import("std");
const rl = @import("raylib");
const SpriteStack = @import("../component/spritestack.zig");

const StackEntity = @This();

position: rl.Vector2,
rotation: f32,
stack: SpriteStack,
controlled: bool = false,

pub fn init(x: f32, y: f32, rotation: f32, textures: []rl.Texture) StackEntity {
    return StackEntity{
        .position = rl.Vector2{ .x = x, .y = y },
        .rotation = rotation,
        .stack = SpriteStack{ .rotation = rotation, .textures = textures },
    };
}

pub fn render(self: StackEntity, camera: rl.Camera2D, rotation: f32) void {
    const position = rl.getWorldToScreen2D(self.position, camera);

    _ = self.stack.render(position.x, position.y, -(rotation - camera.rotation));
}

pub fn sortY(self: StackEntity, camera: rl.Camera2D) f32 {
    return rl.getWorldToScreen2D(self.position, camera).y;
}
