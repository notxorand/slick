const std = @import("std");

const Controls = @import("controls.zig");

const Settings = @This();

const FILE_NAME = "settings";

allocator: std.mem.Allocator,
io: std.Io,
settings: SettingsData = .{},
controls: Controls = .{},

const SettingsData = struct {
    crt_enabled: bool = true,
    window_width: i32 = 1280,
    window_height: i32 = 720,
    window_resizable: bool = false,
    fullscreen: bool = false,
    // TODO: randomise with mixture of a dictionary of words and numbers
    player_name: []const u8 = "noob",
    volume: u32 = 60,
};

pub fn load(self: *Settings) !void {
    var buffer: [4096]u8 = undefined;
    const contents = std.Io.Dir.readFile(std.Io.Dir.cwd(), self.io, FILE_NAME, &buffer) catch |err| switch (err) {
        std.Io.File.OpenError.FileNotFound => {
            _ = std.Io.Dir.cwd().createFile(self.io, FILE_NAME, .{}) catch |create_err| return create_err;
            return;
        },
        else => return err,
    };
    if (contents.len == 0) return;
    const content = try self.allocator.allocSentinel(u8, contents.len, 0);

    @memcpy(content, contents);
    const parsed = try std.zon.parse.fromSliceAlloc(SettingsData, self.allocator, content, null, .{ .ignore_unknown_fields = true });

    self.settings.crt_enabled = parsed.crt_enabled;
    self.settings.window_width = parsed.window_width;
    self.settings.window_height = parsed.window_height;
    self.settings.window_resizable = parsed.window_resizable;
    self.settings.fullscreen = parsed.fullscreen;
    self.settings.player_name = try self.allocator.dupe(u8, parsed.player_name);
    self.settings.volume = parsed.volume;
    try self.controls.load(self.allocator, self.io);
}

pub fn save(self: *Settings) !void {
    // having a backup is always a good idea :)
    try std.Io.Dir.cwd().copyFile(FILE_NAME, .cwd(), "settings.bak", self.io, .{});
    // we create a new file here cause the file's buffer size might not align with the incoming data size from our serialisation which might leave artifacts
    const file = try std.Io.Dir.cwd().createFile(self.io, FILE_NAME, .{});
    defer file.close(self.io);

    var writer = file.writer(self.io, &.{});
    try std.zon.stringify.serialize(self.settings, .{}, &writer.interface);

    try writer.interface.flush();
    try self.controls.save(self.io);
}
