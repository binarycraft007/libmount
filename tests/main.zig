const std = @import("std");
const c = @cImport(@cInclude("libmount.h"));
const testing = std.testing;

test "basic add functionality" {
    var tab = c.mnt_new_table_from_dir("mnt");
    _ = tab;
}
