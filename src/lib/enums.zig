const c = @import("./c.zig");

/// Application initialisation enum
pub const GApplicationFlags = enum(c_uint) {
    default = c.G_APPLICATION_FLAGS_NONE,
    is_service = c.G_APPLICATION_IS_SERVICE,
    is_launcher = c.G_APPLICATION_IS_LAUNCHER,
    handles_command_line = c.G_APPLICATION_HANDLES_COMMAND_LINE,
    send_environment = c.G_APPLICATION_SEND_ENVIRONMENT,
    non_unique = c.G_APPLICATION_NON_UNIQUE,
    can_override_app_id = c.G_APPLICATION_CAN_OVERRIDE_APP_ID,
    allow_replacement = c.G_APPLICATION_ALLOW_REPLACEMENT,
    replace = c.G_APPLICATION_REPLACE,
};

/// PtyFlags enum
pub const PtyFlags = enum(c_uint) {
    no_lastlog = c.VTE_PTY_NO_LASTLOG,
    no_utmp = c.VTE_PTY_NO_UTMP,
    no_wtmp = c.VTE_PTY_NO_WTMP,
    no_helper = c.VTE_PTY_NO_HELPER,
    no_fallback = c.VTE_PTY_NO_FALLBACK,
    default = c.VTE_PTY_DEFAULT,
};

/// enum SpawnFlags
pub const SpawnFlags = enum(c_uint) {
    default = c.G_SPAWN_DEFAULT,
    leave_descriptors_open = c.G_SPAWN_LEAVE_DESCRIPTORS_OPEN,
    do_not_reap_child = c.G_SPAWN_DO_NOT_REAP_CHILD,
    search_path = c.G_SPAWN_SEARCH_PATH,
    stdout_to_dev_null = c.G_SPAWN_STDOUT_TO_DEV_NULL,
    stderr_to_dev_null = c.G_SPAWN_STDERR_TO_DEV_NULL,
    child_inherits_stdin = c.G_SPAWN_CHILD_INHERITS_STDIN,
    file_and_argv_zero = c.G_SPAWN_FILE_AND_ARGV_ZERO,
    search_path_from_envp = c.G_SPAWN_SEARCH_PATH_FROM_ENVP,
    cloexec_pipes = c.G_SPAWN_CLOEXEC_PIPES,
};

/// An enumeration type that can be used to specify the format the selection should be copied to the clipboard in.
/// see: https://valadoc.org/vte-2.91/Vte.Format.html
pub const Format = enum(c_uint) {
    text = c.VTE_FORMAT_TEXT,
    html = c.VTE_FORMAT_HTML,
};

/// Controls how a widget deals with extra space in a single (x or y) dimension.
///
/// Alignment only matters if the widget receives a “too large” allocation, for example if you packed the widget with the GtkWidget:expand flag inside a GtkBox, then the widget might get extra space. If you have for example a 16x16 icon inside a 32x32 space, the icon could be scaled and stretched, it could be centered, or it could be positioned to one side of the space.
///
/// Note that in horizontal context GTK_ALIGN_START and GTK_ALIGN_END are interpreted relative to text direction.
///
/// GTK_ALIGN_BASELINE support for it is optional for containers and widgets, and it is only supported for vertical alignment. When its not supported by a child or a container it is treated as GTK_ALIGN_FILL.
pub const GtkAlign = enum(c_uint) {
    fill = c.GTK_ALIGN_FILL,
    start = c.GTK_ALIGN_START,
    end = c.GTK_ALIGN_END,
    center = c.GTK_ALIGN_CENTER,
    baseline = c.GTK_ALIGN_BASELINE,
};

/// Represents the orientation of widgets and other
/// objects which can be switched between horizontal
/// and vertical orientation on the fly, like
/// GtkToolbar or GtkGesturePan.
pub const GtkOrientation = enum(c_uint) {
    horizontal = c.GTK_ORIENTATION_HORIZONTAL,
    vertical = c.GTK_ORIENTATION_VERTICAL,
};
