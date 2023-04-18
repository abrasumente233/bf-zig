const std = @import("std");
const print = std.debug.print;

const memorySize = 1024 * 1024; // 1 MiB

fn interpret(memory: []u8, comptime prog: []const u8) !void {
    const stdin = std.io.getStdIn().reader();
    comptime var ii: u32 = 0; // instruction index for codegen
    var ip: u32 = 0; // instruction pointer at runtime
    var dp: u32 = 0; // data pointer at runtime

    inline while (ii != prog.len) : (ii += 1) {
        const c = prog[ii];
        switch (c) {
            '>' => dp += 1,
            '<' => dp -= 1,
            '+' => memory[dp] += 1,
            '-' => memory[dp] -= 1,
            '.' => print("{}", .{memory[dp]}),
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
    var memory = [_]u8{0} ** memorySize;
    memory[0] = 44;
    memory[1] = 42;
    print("adding {} and {}\n", .{ memory[0], memory[1] });

    // Adding memory[0] and memory[1] and store the result in memory[1]
    const prog = "[->+<]";
    try interpret(&memory, prog);

    // FIXME: we can't call `std.testing.expectEqual` at comptime since it in turn
    // calls `std.debug.print`, which acquires lock for `stderr`, which calls into
    // pthread, which is an external library, gg.
    try std.testing.expectEqual(memory[1], 86);
    print("result: {}\n", .{memory[1]});
}

fn Func(comptime factor: i32) type {
    return struct {
        inline fn process() void {
            print("once: {}\n", .{2 * factor});
        }
    };
}

fn Loop3Times(comptime func: fn () callconv(.Inline) void) type {
    return struct {
        inline fn execute_loop(counter: *u32) void {
            comptime var i = 0;
            inline while (i < 3) : (i += 1) {
                counter.* += 1;
                _ = func();
            }
        }
    };
}

fn StraightLineCodeEmitter(comptime prog: []const u8) type {
    return struct {
        inline fn emit(memory: []u8) void {
            comptime var ii: u32 = 0;
            inline while (ii < prog.len) : (ii += 1) {
                const inst = prog[ii];
                switch (inst) {
                    '+' => memory[0] += 1,
                    '.' => print("{}", .{memory[0]}),
                    else => @compileError("unknown instruction: `" ++ [1]u8{inst} ++ "`"),
                }
            }
        }
    };
}

pub fn main() !void {
    // try fuck();

    var memory = [_]u8{0} ** memorySize;
    const prog = "[->+<]";
    StraightLineCodeEmitter(prog).emit(&memory);
}
