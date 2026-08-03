const std = @import("std");

const rl = @import("raylib");

const SpriteStack = @This();

textures: []rl.Texture2D,
stack_height: f32 = 1,
rotation: f32 = 0,

pub fn render(self: SpriteStack, x: f32, y: f32, rotation: f32, scale: f32) rl.Vector2 {
    for (self.textures, 0..) |texture, i| {
        rl.drawTexturePro(
            texture,
            .{ .x = 0, .y = 0, .width = @floatFromInt(texture.width), .height = @floatFromInt(texture.height) },
            .{ .x = x, .y = y - @as(f32, @floatFromInt(i)) * self.stack_height, .width = @as(f32, @floatFromInt(texture.width)) * scale, .height = @as(f32, @floatFromInt(texture.height)) * scale },
            .{ .x = @as(f32, @floatFromInt(texture.width)) * scale / 2, .y = @as(f32, @floatFromInt(texture.height)) * scale / 2.5 },
            self.rotation + rotation,
            rl.Color.white,
        );
    }
    return .{ .x = x, .y = y };
}
