const std = @import("std");

const memorySize = 1024 * 1024; // 1 MiB

fn interpret(memory: []u8, prog: []const u8) !void {
    const stdin = std.io.getStdIn().reader();
    var ip: u32 = 0; // instruction pointer
    var dp: u32 = 0; // data pointer

    while (ip != prog.len) {
        const c = prog[ip];
        switch (c) {
            '>' => dp += 1,
            '<' => dp -= 1,
            '+' => memory[dp] += 1,
            '-' => memory[dp] -= 1,
            '.' => std.debug.print("{}", .{memory[dp]}),
            ',' => memory[dp] = try stdin.readByte(),
            '[' => if (memory[dp] == 0) {
                var depth: u32 = 1;
                while (depth != 0) {
                    ip += 1;
                    const c0 = prog[ip];
                    if (c0 == '[') {
                        depth += 1;
                    } else if (c0 == ']') {
                        depth -= 1;
                    }
                }
            },
            ']' => if (memory[dp] != 0) {
                var depth: u32 = 1;
                while (depth != 0) {
                    ip -= 1;
                    const c0 = prog[ip];
                    if (c0 == ']') {
                        depth += 1;
                    } else if (c0 == '[') {
                        depth -= 1;
                    }
                }
            },
            else => unreachable,
        }
        ip += 1;
    }
}

fn fuck() !void {
    comptime var memory = [_]u8{0} ** memorySize;
    memory[0] = 44;
    memory[1] = 42;
    std.debug.print("adding {} and {}\n", .{ memory[0], memory[1] });

    // Adding memory[0] and memory[1] and store the result in memory[1]
    const prog = "[->+<]";
    try comptime interpret(&memory, prog);

    // FIXME: we can't call `std.testing.expectEqual` at comptime since it in turn
    // calls `std.debug.print`, which acquires lock for `stderr`, which calls into
    // pthread, which is an external library, gg.
    comptime try std.testing.expect(memory[1] == 86);
    std.debug.print("result: {}\n", .{memory[1]});
}

pub fn main() !void {
    try fuck();
}
