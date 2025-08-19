pub const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("vte/vte.h");
});

pub usingnamespace c;
