const std = @import("std");
const rl = @import("raylib");

const Camera = @This();

pub const EasingType = enum { linear, ease_in, ease_out };

camera: rl.Camera2D,
track: *rl.Vector2,
lerp_factor: f32 = 0.25,
easing: EasingType = .linear,

pub fn init(screen_center: rl.Vector2) Camera {
    var target = rl.Vector2.zero();
    return Camera{
        .camera = rl.Camera2D{
            .offset = screen_center,
            .target = target,
            .rotation = 0,
            .zoom = 1,
        },
        .track = &target,
    };
}

fn linear(t: f32) f32 {
    return t;
}

fn easeIn(t: f32) f32 {
    return t * t;
}

fn easeOut(t: f32) f32 {
    return 1.0 - (1.0 - t) * (1.0 - t);
}

pub fn setTarget(self: *Camera, target: *rl.Vector2) void {
    self.track = target;
}

pub fn update(self: *Camera, dt: f32) void {
    const diff_x = self.track.*.x - self.camera.target.x;
    const diff_y = self.track.*.y - self.camera.target.y;
    const dist = @sqrt(diff_x * diff_x + diff_y * diff_y);

    if (dist < 0.1) return;

    const max_dist = 500.0;
    const progress = std.math.clamp(dist / max_dist, 0.0, 1.0);

    const eased_factor = switch (self.easing) {
        .linear => 1.0,
        .ease_in => progress * progress,
        .ease_out => 1.0 - (1.0 - progress) * (1.0 - progress),
    };

    const f = std.math.clamp(self.lerp_factor * eased_factor * dt * 60.0, 0.0, 1.0);

    self.camera.target.x += diff_x * f;
    self.camera.target.y += diff_y * f;
}
