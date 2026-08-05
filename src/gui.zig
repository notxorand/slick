const rl = @import("raylib");
const rg = @import("raygui");

const Gui = @This();

mode: GameMode = .MENU,

pub const GameMode = enum {
    MENU,
    PLAYING,
    PAUSED,
};

pub fn renderPaused(self: *Gui) void {
    if (self.mode != .PAUSED) return;
    rl.drawRectangle(0, 0, rl.getScreenWidth(), rl.getScreenHeight(), rl.Color.init(0, 0, 0, 90));
    rl.drawText("PAUSED", 32, 32, 16, rl.Color.white);
}

pub fn renderMenu(self: *Gui, active_gamepad: i32) void {
    if (rl.isKeyPressed(.enter) or (active_gamepad != -1 and rl.isGamepadButtonPressed(active_gamepad, .right_face_down))) self.mode = .PLAYING;
    rl.drawRectangle(0, 0, rl.getScreenWidth(), rl.getScreenHeight(), rl.Color.init(0, 0, 0, 90));
}
