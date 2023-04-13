const std = @import("std");

const memorySize = 1024 * 1024; // 1 MiB

fn fuck() void {
    comptime var memory = [_]u8{0} ** memorySize;

    // Adding memory[0] and memory[1] and store the result in memory[1]
    const prog = "[->+<]";
    memory[0] = 44;
    memory[1] = 42;
    std.debug.print("adding {} and {}\n", .{ memory[0], memory[1] });

    // Interpret the program
    const stdin = std.io.getStdIn().reader();
    comptime var ip: u32 = 0; // instruction pointer
    comptime var dp: u32 = 0; // data pointer

    inline while (ip != prog.len) {
        @setEvalBranchQuota(1000000);
        const c = prog[ip];
        switch (c) {
            '>' => dp += 1,
            '<' => dp -= 1,
            '+' => memory[dp] += 1,
            '-' => memory[dp] -= 1,
            '.' => std.debug.print("{}", .{memory[dp]}),
            ',' => memory[dp] = try stdin.readByte(),
            '[' => if (memory[dp] == 0) {
                comptime var depth: u32 = 1;
                inline while (depth != 0) {
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
                comptime var depth: u32 = 1;
                inline while (depth != 0) {
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

    comptime try std.testing.expect(memory[1] == 86);

    std.debug.print("result: {}\n", .{memory[1]});
}

pub fn main() !void {
    fuck();
}
