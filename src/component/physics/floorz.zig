const std = @import("std");

const FloorZ = @This();

slip: f32 = 0.89, // inverse of friction. between 0 & 1
angular_velocity: f32 = 0.0,
angular_acceleration: f32 = 0.01,

pub fn calculateRotation(self: *FloorZ, dx: f32, dy: f32, object_rotation: *f32) void {
    if (dx != 0 or dy != 0) {
        const target_angle = (std.math.atan2(dy, -dx) * 180.0 / std.math.pi) + 90.0;

        // 1. Calculate the shortest diff
        var diff = target_angle - object_rotation.*;
        while (diff > 180) diff -= 360;
        while (diff < -180) diff += 360;

        // 2. Apply torque (angular acceleration) based on direction
        self.angular_velocity += (diff * self.angular_acceleration);

        // 3. Apply friction
        self.angular_velocity *= self.slip;

        // 4. Apply to rotation
        object_rotation.* += self.angular_velocity;
    }
}
