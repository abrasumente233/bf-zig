const std = @import("std");

fn BrainfuckEmitter(comptime prog: []const u8) type {
    return struct {
        inline fn emit(memory: []u8, dp: *u32) void {
            @setEvalBranchQuota(1000000);
            const stdout = std.io.getStdOut().writer();
            const stdin = std.io.getStdIn().reader(); // FIXME: lock?
            comptime var ii: u32 = 0;
            inline while (ii < prog.len) : (ii += 1) {
                const inst = prog[ii];
                switch (inst) {
                    '>' => dp.* += 1,
                    '<' => dp.* -= 1,
                    '+' => memory[dp.*] +%= 1,
                    '-' => memory[dp.*] -%= 1,
                    '.' => stdout.print("{s}", .{[1]u8{memory[dp.*]}}) catch unreachable,
                    ',' => memory[dp.*] = stdin.readByte() catch @panic("stdin.readByte() failed"),
                    '[' => {
                        // find the matching ]
                        // TODO: make this faster
                        comptime var end_ii = ii;
                        comptime var depth: u32 = 1;
                        inline while (depth != 0) {
                            end_ii += 1;
                            const c0 = prog[end_ii];
                            if (c0 == '[') {
                                depth += 1;
                            } else if (c0 == ']') {
                                depth -= 1;
                            }
                        }

                        LoopEmitter(prog[ii + 1 .. end_ii]).emit(memory, dp);

                        // now that we've emitted the loop body,
                        // set `ii` to `]` and continue emitting
                        // the straight line code afterwards.
                        ii = end_ii;
                    },
                    ']' => unreachable,
                    // FIXME: allow other characters as comments.
                    else => @compileError("unknown instruction: `" ++ [1]u8{inst} ++ "`"),
                }
            }
        }
    };
}

fn LoopEmitter(comptime prog: []const u8) type {
    return struct {
        inline fn emit(memory: []u8, dp: *u32) void {
            while (memory[dp.*] != 0) {
                BrainfuckEmitter(prog).emit(memory, dp);
            }
        }
    };
}

pub fn main() !void {
    // const prog = "[->+<]";
    //const prog = "+++.";
    //const prog = "[->+<]";
    //const prog = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.";
    //const prog = "+++++[-]";
    //const prog = ">+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.[-]>++++++++[<++++>-]<.>+++++++++++[<++++++++>-]<-.--------.+++.------.--------.[-]>++++++++[<++++>-]<+.[-]++++++++++.";
    //const prog = ">+++++++++[<++++++++>-]<.";
    //const prog = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]";
    //const prog = "[-]";
    // const prog = "[-]";
    //const prog = ">+++++[>+++++++<-]>.<<++[>+++++[>+++++++<-]<-]>>.+++++.<++[>-----<-]>-.<++[>++++<-]>+.<++[>++++<-]>+.[>+>+>+<<<-]>>>[<<<+>>>-]<<<<<++[>+++[>---<-]<-]>>+.+.<+++++++[>----------<-]>+.<++++[>+++++++<-]>.>.-------.-----.<<++[>+++++<<-]>>.+.----------------.<<++[>-------<-]>.>++++.<<++[>++++++++<-]>.<++++++++++[>>>-----------<<<-]>>>+++.<-----.+++++.-------.<<++[>>++++++++<<-]>>+.<<+++[>----------<-]>.<++[>>--------<<-]>>-.------.<<++[>++++++++<-]>+++.---....>++.<----.--.<++[>>+++++++++<<-]>>+.<<++[>+++++++++<-]>+.<++[>>-------<<-]>>-.<--.>>.<<<+++[>>++++<<-]>>.<<+++[>>----<<-]>>.++++++++.+++++.<<++[>---------<-]>-.+.>>.<<<++[>>+++++++<<-]>>-.>.>>>[-]>>[-]<+[<<[-],[>>>>>>>>>>>>>+>+<<<<<<<<<<<<<<-]>>>>>>>>>>>>>>[<<<<<<<<<<<<<<+>>>>>>>>-]<<+>[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[-[<->[-]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]<[<<<<<<<<<<<<[-]>>>>>>>>>>>>[-]]<<<<<<<<<<<<[<+++++[>---------<-]>++[>]>>[>+++++[>+++++++++<-]>--..-.<+++++++[>++++++++++<-]>.<+++++++++++[>-----<-]>++.<<<<<<.>>>>>>[-]<]<<<[-[>]>>[>++++++[>+++[>++++++<-]<-]>>++++++.-------------.----.+++.<++++++[>----------<-]>.++++++++.----.<++++[>+++++++++++++++++<-]>.<++++[>-----------------<-]>.+++++.--------.<++[>+++++++++<-]>.[-]<<<<<<<.>>>>>]<<<[-[>]>>[>+++++[>+++++++++<-]>..---.<+++++++[>++++++++++<-]>.<+++++++++++[>-----<-]>++.<<<<<<.>>>>>>[-]<]<<<[-[>]>>[>+++[>++++[>++++++++++<-]<-]>>-.-----.---------.<++[>++++++<-]>-.<+++[>-----<-]>.<++++++[----------<-]>-.<+++[>+++<-]>.-----.<++++[>+++++++++++++++++<-]>.<++++[>-----------------<-]>.+++++.--------.<++[>+++++++++<-]>.[-]<<<<<<<.>>>>>]<<<[<+++[>-----<-]>+[>]>>[>+++++[>+++++++++<-]>..<+++++++[>++++++++++<-]>---.<+++++[>----------<-]>---.<<<<<<.>>>>>>[-]<]<<<[--[>]>>[>+++++[>+++++++++<-]>--..<+++++++[>++++++++++<-]>-.<+++++[>----------<-]>---.[-]<<<<<<.>>>>]<<<[<+++[>----------<-]>+[>]>>[>+++[>++++[>++++++++++<-]<-]>>-.<+++[>-----<-]>.+.+++.-------.<++++++[>----------<-]>-.++.<+++++++[>++++++++++<-]>.<+++++++[>----------<-]>-.<++++++++[>++++++++++<-]>++.[-]<<<<<<<.>>>>>]<<<[--[>]>>[>+++++[>+++++[>+++++<-]<-]>>.[-]<<<<<<<.>>>>>]<<<[<++++++++++[>----------------<-]>--[>]>>[<<<<[-]]]]]]]]]]]>>]<++[>+++++[>++++++++++<-]<-]+.<+++[>++++++<-]>+.<+++[>-----<-]>.+++++++++++.<+++++++[>----------<-]>------.++++++++.-------.<+++[>++++++<-]>.<++++++[>+++++++++++<-]>.<++++++++++.";
    //const prog = ">++++[-<+++++++++++>]>,[>++++++[-<-------->]>+++++++++[-<<<[->+>+<<]>>[-<<+>>]>]<<[-<+>],]<<+++++.-----.+++++.----->-->+>+<<[-<.>>>[->+>+<<]<[->>>+<<<]>>[-<<+>>]>[->+<<<+>>]>[>>>>++++++++++<<<<[->+>>+>-[<-]<[->>+<<<<[->>>+<<<]>]<<]>+[-<+>]>>>[-]>[-<<<<+>>>>]<<<<]<[>++++++[<++++++++>-]<-.[-]<]<<<<]";
    //const prog = ",[.,]"; // cat
    //const prog = ">,[>++++++[-<-------->]>+++++++++[-<<<[->+>+<<]>>[-<<+>>]>]<<[-<+>],]>+<<[->>[>]<[[->+>+<<]<]>>[[-<+>]>]<<[<]<]>+++++++[-<+++++++>]<.----->>[>]<-<[[<]<.>>[>]<[->+<]>[>>>>++++++++++<<<<[->+>>+>-[<-]<[->>+<<<<[->>>+<<<]>]<<]>+[-<+>]>>>[-]>[-<<<<+>>>>]<<<<]<[>++++++[<++++++++>-]<-.[-]<]<]";
    //const prog = ">>>>++>+>++>+>>++<+[[>[>>[>>>>]<<<<[[>>>>+<<<<-]<<<<]>>>>>>]+<]>->>--[+[+++<<<<--]++>>>>--]+[>>>>]<<<<[<<+<+<]<<[>>>>>>[[<<<<+>>>>-]>>>>]<<<<<<<<[<<<<]>>-[<<+>>-]+<<[->>>>[-[+>>>>-]-<<-[>>>>-]++>>+[-<<<<+]+>>>>]<<<<[<<<<]]>[-[<+>-]]+<[->>>>[-[+>>>>-]-<<<-[>>>>-]++>>>+[-<<<<+]+>>>>]<<<<[<<<<]]<<]>>>+[>>>>]-[+<<<<--]++[<<<<]>>>+[>-[>>[--[++>>+>>--]-<[-[-[+++<<<<-]+>>>>-]]++>+[-<<<<+]++>>+>>]<<[>[<-<<<]+<]>->>>]+>[>>>>]-[+<<<<--]++<[[>>>>]<<<<[-[+>[<->-]++<[[>-<-]++[<<<<]+>>+>>-]++<<<<-]>-[+[<+[<<<<]>]<+>]+<[->->>>[-]]+<<<<]]>[<<<<]>[-[-[+++++[>++++++++<-]>-.>>>-[<<<----.<]<[<<]>>[-]>->>+[[>>>>]+[-[->>>>+>>>>>>>>-[-[+++<<<<[-]]+>>>>-]++[<<<<]]+<<<<]>>>]+<+<<]>[-[->[--[++>>>>--]->[-[-[+++<<<<-]+>>>>-]]++<+[-<<<<+]++>>>>]<<<<[>[<<<<]+<]>->>]<]>>>>[--[++>>>>--]-<--[+++>>>>--]+>+[-<<<<+]++>>>>]<<<<<[<<<<]<]>[>+<<++<]<]>[+>[--[++>>>>--]->--[+++>>>>--]+<+[-<<<<+]++>>>>]<<<[<<<<]]>>]>]";
    const prog = ">>>>++>+>++>+>>++<+[[>[>>[>>>>]<<<<[[>>>>+<<<<-]<<<<]>>>>>>]+<]>->>--[+[+++<<<<--]++>>>>--]+[>>>>]<<<<[<<+<+<]<<[>>>>>>[[<<<<+>>>>-]>>>>]<<<<<<<<[<<<<]>>-[<<+>>-]+<<[->>>>[-[+>>>>-]-<<-[>>>>-]++>>+[-<<<<+]+>>>>]<<<<[<<<<]]>[-[<+>-]]+<[->>>>[-[+>>>>-]-<<<-[>>>>-]++>>>+[-<<<<+]+>>>>]<<<<[<<<<]]<<]>>>+[>>>>]-[+<<<<--]++[<<<<]>>>+[>-[>>[--[++>>+>>--]-<[-[-[+++<<<<-]+>>>>-]]++>+[-<<<<+]++>>+>>]<<[>[<-<<<]+<]>->>>]+>[>>>>]-[+<<<<--]++<[[>>>>]<<<<[-[+>[<->-]++<[[>-<-]++[<<<<]+>>+>>-]++<<<<-]>-[+[<+[<<<<]>]<+>]+<[->->>>[-]]+<<<<]]>[<<<<]>[-[-[+++++[>++++++++<-]>-.>>>-[<<<----.<]<[<<]>>[-]>->>+[[>>>>]+[-[->>>>+>>>>>>>>-[-[+++<<<<[-]]+>>>>-]++[<<<<]]+<<<<]>>>]+<+<<]>[-[->[--[++>>>>--]->[-[-[+++<<<<-]+>>>>-]]++<+[-<<<<+]++>>>>]<<<<[>[<<<<]+<]>->>]<]>>>>[--[++>>>>--]-<--[+++>>>>--]+>+[-<<<<+]++>>>>]<<<<<[<<<<]<]>[>+<<++<]<]>[+>[--[++>>>>--]->--[+++>>>>--]+<+[-<<<<+]++>>>>]<<<[<<<<]]>>]>]";

    const memorySize = 1024 * 1024; // 1 MiB
    var memory = [_]u8{0} ** memorySize;
    var dp: u32 = 0; // data pointer

    BrainfuckEmitter(prog).emit(&memory, &dp);
}
