const builtin = @import("builtin");
const std = @import("std");
const math = std.math;
const tvg = @import("../libs/tinyvg/src/lib/tinyvg.zig");
const fnv = std.hash.Fnv1a_32;
const freetype = @import("freetype");
pub const icons = @import("icons.zig");
pub const fonts = @import("fonts.zig");
pub const keys = @import("keys.zig");

//const stb = @cImport({
//    @cInclude("stb_rect_pack.h");
//    @cDefine("STB_TRUETYPE_IMPLEMENTATION", "1");
//    @cInclude("stb_truetype.h");
//});

const log = std.log.scoped(.gui);
const gui = @This();

var current_window: ?*Window = null;

pub var snap_to_pixels: bool = true;

pub var log_debug: bool = false;
pub fn debug(comptime str: []const u8, args: anytype) void {
    if (log_debug) {
        log.debug(str, args);
    }
}

pub const Theme = struct {
    name: []const u8,
    dark: bool,

    color_accent: Color,
    color_accent_bg: Color,
    color_success: Color,
    color_success_bg: Color,
    color_err: Color,
    color_err_bg: Color,
    color_window: Color,
    color_window_bg: Color,
    color_content: Color,
    color_content_bg: Color,
    color_control: Color,
    color_control_bg: Color,

    font_body: Font,
    font_heading: Font,
    font_caption: Font,
    font_caption_heading: Font,
    font_title: Font,
    font_title_1: Font,
    font_title_2: Font,
    font_title_3: Font,
    font_title_4: Font,
};

pub const theme_Adwaita = Theme{
    .name = "Adwaita",
    .dark = false,
    .font_body = Font{ .size = 11, .name = "Vera", .ttf_bytes = fonts.bitstream_vera.Vera },
    .font_heading = Font{ .size = 11, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_caption = Font{ .size = 9, .name = "Vera", .ttf_bytes = fonts.bitstream_vera.Vera },
    .font_caption_heading = Font{ .size = 9, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title = Font{ .size = 24, .name = "Vera", .ttf_bytes = fonts.bitstream_vera.Vera },
    .font_title_1 = Font{ .size = 20, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title_2 = Font{ .size = 17, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title_3 = Font{ .size = 15, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title_4 = Font{ .size = 13, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .color_accent = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_accent_bg = Color{ .r = 0x35, .g = 0x84, .b = 0xe4 },
    .color_success = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_success_bg = Color{ .r = 0x2e, .g = 0xc2, .b = 0x7e },
    .color_err = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_err_bg = Color{ .r = 0xe0, .g = 0x1b, .b = 0x24 },
    .color_window = Color{ .r = 0, .g = 0, .b = 0, .a = 0xcc },
    .color_window_bg = Color{ .r = 0xf0, .g = 0xf0, .b = 0xf0 },
    .color_content = Color{ .r = 0, .g = 0, .b = 0 },
    .color_content_bg = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_control = Color{ .r = 0x31, .g = 0x31, .b = 0x31 },
    .color_control_bg = Color{ .r = 0xe0, .g = 0xe0, .b = 0xe0 },
};

pub const theme_Adwaita_Dark = Theme{
    .name = "Adwaita Dark",
    .dark = true,
    .font_body = Font{ .size = 11, .name = "Vera", .ttf_bytes = fonts.bitstream_vera.Vera },
    .font_heading = Font{ .size = 11, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_caption = Font{ .size = 9, .name = "Vera", .ttf_bytes = fonts.bitstream_vera.Vera },
    .font_caption_heading = Font{ .size = 9, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title = Font{ .size = 24, .name = "Vera", .ttf_bytes = fonts.bitstream_vera.Vera },
    .font_title_1 = Font{ .size = 20, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title_2 = Font{ .size = 17, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title_3 = Font{ .size = 15, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .font_title_4 = Font{ .size = 13, .name = "VeraBd", .ttf_bytes = fonts.bitstream_vera.VeraBd },
    .color_accent = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_accent_bg = Color{ .r = 0x35, .g = 0x84, .b = 0xe4 },
    .color_success = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_success_bg = Color{ .r = 0x26, .g = 0xa2, .b = 0x69 },
    .color_err = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_err_bg = Color{ .r = 0xc0, .g = 0x1c, .b = 0x28 },
    .color_window = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_window_bg = Color{ .r = 0x24, .g = 0x24, .b = 0x24 },
    .color_content = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_content_bg = Color{ .r = 0x1e, .g = 0x1e, .b = 0x1e },
    .color_control = Color{ .r = 0xff, .g = 0xff, .b = 0xff },
    .color_control_bg = Color{ .r = 0x30, .g = 0x30, .b = 0x30 },
};

pub const Options = struct {
    pub const Expand = enum {
        none,
        horizontal,
        vertical,
        both,

        pub fn horizontal(self: *const Expand) bool {
            return (self.* == .horizontal or self.* == .both);
        }

        pub fn vertical(self: *const Expand) bool {
            return (self.* == .vertical or self.* == .both);
        }
    };

    pub const Gravity = enum {
        upleft,
        up,
        upright,
        left,
        center,
        right,
        downleft,
        down,
        downright,
    };

    pub const FontStyle = enum {
        custom,
        body,
        heading,
        caption,
        caption_heading,
        title,
        title_1,
        title_2,
        title_3,
        title_4,
    };

    pub const ColorStyle = enum {
        custom,
        accent,
        success,
        err,
        window,
        content,
        control,
    };

    // null is normal, meaning parent picks a rect for the child widget.  If
    // non-null, child widget is choosing its own place, meaning its not being
    // placed normally.  w and h will still be expanded if expand is set.
    // Example is ScrollArea, where user code chooses widget placement. If
    // non-null, should not call rectFor or minSizeForChild.
    rect: ?Rect = null,

    // default is .none
    expand: ?Expand = null,

    // default is .upleft
    gravity: ?Gravity = null,

    // widgets will be focusable only if this is set
    tab_index: ?u16 = null,

    // only used if .color_style == .custom
    color_custom: ?Color = null,
    color_custom_bg: ?Color = null,

    // only used if .font_style == .custom
    font_custom: ?Font = null,

    // For the rest of these fields, if null, each widget uses its defaults

    // x left, y top, w right, h bottom
    margin: ?Rect = null,
    border: ?Rect = null,
    padding: ?Rect = null,

    // x topleft, y topright, w botright, h botleft
    corner_radius: ?Rect = null,

    // includes padding/border/margin
    // see overrideMinSizeContent()
    min_size: ?Size = null,

    color_style: ?ColorStyle = null,
    background: ?bool = null,
    font_style: ?FontStyle = null,

    pub fn color(self: *const Options) Color {
        const style = self.color_style orelse .control;
        const col =
            switch (style) {
            .custom => self.color_custom,
            .accent => themeGet().color_accent,
            .success => themeGet().color_success,
            .err => themeGet().color_err,
            .content => themeGet().color_content,
            .window => themeGet().color_window,
            .control => themeGet().color_control,
        };

        if (col) |cc| {
            return cc;
        } else {
            log.debug("Options.color() couldn't find a color, substituting magenta", .{});
            return Color{ .r = 255, .g = 0, .b = 255, .a = 255 };
        }
    }

    pub fn color_bg(self: *const Options) Color {
        const style = self.color_style orelse .control;
        const col =
            switch (style) {
            .custom => self.color_custom_bg,
            .accent => themeGet().color_accent_bg,
            .success => themeGet().color_success_bg,
            .err => themeGet().color_err_bg,
            .content => themeGet().color_content_bg,
            .window => themeGet().color_window_bg,
            .control => themeGet().color_control_bg,
        };

        if (col) |cc| {
            return cc;
        } else {
            log.debug("Options.color_bg() couldn't find a color, substituting green", .{});
            return Color{ .r = 0, .g = 255, .b = 0, .a = 255 };
        }
    }

    pub fn font(self: *const Options) Font {
        return self.fontWithDefault(.body);
    }

    pub fn fontWithDefault(self: *const Options, style_default: FontStyle) Font {
        const style = self.font_style orelse style_default;
        const f =
            switch (style) {
            .custom => self.font_custom,
            .body => themeGet().font_body,
            .heading => themeGet().font_heading,
            .caption => themeGet().font_caption,
            .caption_heading => themeGet().font_caption_heading,
            .title => themeGet().font_title,
            .title_1 => themeGet().font_title_1,
            .title_2 => themeGet().font_title_2,
            .title_3 => themeGet().font_title_3,
            .title_4 => themeGet().font_title_4,
        };

        if (f) |ff| {
            return ff;
        } else {
            log.debug("Options.font() couldn't find a font, falling back", .{});
            return Font{ .name = "VeraMono", .ttf_bytes = gui.fonts.bitstream_vera.VeraMono, .size = 12 };
        }
    }

    pub fn expandGet(self: *const Options) Expand {
        return self.expand orelse .none;
    }

    pub fn gravityGet(self: *const Options) Gravity {
        return self.gravity orelse .upleft;
    }

    pub fn marginGet(self: *const Options) Rect {
        return self.margin orelse Rect{};
    }

    pub fn borderGet(self: *const Options) Rect {
        return self.border orelse Rect{};
    }

    pub fn backgroundGet(self: *const Options) bool {
        return self.background orelse false;
    }

    pub fn paddingGet(self: *const Options) Rect {
        return self.padding orelse Rect{};
    }

    pub fn corner_radiusGet(self: *const Options) Rect {
        return self.corner_radius orelse Rect{};
    }

    pub fn expandHorizontal(self: *const Options) bool {
        return (self.expand orelse Expand.none).horizontal();
    }

    pub fn expandVertical(self: *const Options) bool {
        return (self.expand orelse Expand.none).vertical();
    }

    pub fn expandAny(self: *const Options) bool {
        return (self.expand orelse Expand.none) != Expand.none;
    }

    // Used in compound widgets to strip out the styling that should only apply
    // to the outermost container widget.  For example, with a button
    // (container with label) the container uses:
    // - rect
    // - min_size
    // - margin
    // - border
    // - background
    // - padding
    // - corner_radius
    // while the label uses:
    // - fonts
    // - colors
    // and they both use:
    // - expand
    // - gravity
    pub fn strip(self: *const Options) Options {
        return Options{
            // explicity set these to "strip" out the defaults of internal widgets
            .margin = Rect{},
            .border = Rect{},
            .padding = Rect{},
            .corner_radius = Rect{},

            // keep the rest
            .expand = self.expand,
            .gravity = self.gravity,
            .color_custom = self.color_custom,
            .color_custom_bg = self.color_custom_bg,
            .font_custom = self.font_custom,
            .color_style = self.color_style,
            .font_style = self.font_style,
        };
    }

    // Use to keep only the font/color stuff and use defaults for the rest
    pub fn styling(self: *const Options) Options {
        return Options{
            .color_custom = self.color_custom,
            .color_custom_bg = self.color_custom_bg,
            .font_custom = self.font_custom,
            .color_style = self.color_style,
            .font_style = self.font_style,
        };
    }

    // converts a content min size to a min size including padding/border/margin
    // make sure you've previously overridden padding/border/margin
    pub fn overrideMinSizeContent(self: *const Options, min_size_content: Size) Options {
        return self.override(.{ .min_size = min_size_content.pad(self.paddingGet()).pad(self.borderGet()).pad(self.marginGet()) });
    }

    pub fn override(self: *const Options, over: Options) Options {
        var ret = self.*;

        inline for (@typeInfo(Options).Struct.fields) |f| {
            if (@field(over, f.name)) |fval| {
                @field(ret, f.name) = fval;
            }
        }

        return ret;
    }

    //pub fn format(self: *const Options, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    //    try std.fmt.format(writer, "Options{{ .background = {?}, .color_style = {?} }}", .{ self.background, self.color_style });
    //}
};

pub fn themeGet() *const Theme {
    var cw = current_window orelse unreachable;
    return cw.theme;
}

pub fn themeSet(theme: *const Theme) void {
    var cw = current_window orelse unreachable;
    cw.theme = theme;
}

pub fn placeOnScreen(spawner: Rect, start: Rect) Rect {
    var r = start;
    const wr = windowRect();
    if ((r.x + r.w) > wr.w) {
        if (spawner.w == 0) {
            r.x = wr.w - r.w;
        } else {
            r.x = spawner.x - spawner.w - r.w;
        }
    }

    if ((r.y + r.h) > wr.h) {
        if (spawner.h == 0) {
            r.y = wr.h - r.h;
        }
    }

    return r;
}

pub fn currentWindow() *Window {
    return current_window orelse unreachable;
}

pub fn frameTimeNS() i128 {
    var cw = current_window orelse unreachable;
    return cw.frame_time_ns;
}

// All widgets have to bubble keyboard events if they can have keyboard focus
// so that pressing the up key in any child of a scrollarea will scroll.  Call
// this helper at the end of processing normal events.
fn bubbleable(e: *Event) bool {
    return (!e.handled and (e.evt == .key or e.evt == .text));
}

pub const Font = struct {
    size: f32,
    line_skip_factor: f32 = 1.0,
    name: []const u8,
    ttf_bytes: []const u8,

    pub fn resize(self: *const Font, s: f32) Font {
        return Font{ .size = s, .name = self.name, .ttf_bytes = self.ttf_bytes };
    }

    pub fn textSize(self: *const Font, text: []const u8) Size {
        return self.textSizeEx(text, null, null);
    }

    pub fn textSizeEx(self: *const Font, text: []const u8, max_width: ?f32, end_idx: ?*usize) Size {
        // ask for a font that matches the natural display pixels so we get a more
        // accurate size

        const ss = parentGet().screenRectScale(Rect{}).s;

        const ask_size = @ceil(self.size * ss);
        const max_width_sized = (max_width orelse 1000000.0) * ss;
        const target_fraction = self.size / ask_size;
        const sized_font = self.resize(ask_size);
        const s = sized_font.textSizeRaw(text, max_width_sized, end_idx);
        //std.debug.print("textSize size {d} for \"{s}\" {d} {}\n", .{ self.size, text, target_fraction, s.scale(target_fraction) });
        return s.scale(target_fraction);
    }

    // doesn't scale the font or max_width
    pub fn textSizeRaw(self: *const Font, text: []const u8, max_width: ?f32, end_idx: ?*usize) Size {
        const fce = fontCacheGet(self.*);

        const mwidth = max_width orelse 1000000.0;

        var x: f32 = 0;
        var minx: f32 = 0;
        var maxx: f32 = 0;
        var miny: f32 = 0;
        var maxy: f32 = fce.height;
        var tw: f32 = 0;
        var th: f32 = 0;

        var ei: usize = 0;

        var utf8 = (std.unicode.Utf8View.init(text) catch unreachable).iterator();
        while (utf8.nextCodepoint()) |codepoint| {
            const gi = fce.glyphInfoGet(@intCast(u32, codepoint));

            minx = math.min(minx, x + gi.minx);
            maxx = math.max(maxx, x + gi.maxx);
            maxx = math.max(maxx, x + gi.advance);

            miny = math.min(miny, gi.miny);
            maxy = math.max(maxy, gi.maxy);

            // TODO: kerning

            // always include the first codepoint
            if (ei > 0 and (maxx - minx) > mwidth) {
                // went too far
                break;
            }

            tw = maxx - minx;
            th = maxy - miny;
            ei += std.unicode.utf8CodepointSequenceLength(codepoint) catch unreachable;
            x += gi.advance;
        }

        // TODO: xstart and ystart

        if (end_idx) |endout| {
            endout.* = ei;
        }

        //std.debug.print("textSizeRaw size {d} for \"{s}\" {d}x{d}\n", .{ self.size, text, tw, th });
        return Size{ .w = tw, .h = th };
    }

    pub fn lineSkip(self: *const Font) f32 {
        // do the same sized thing as textSizeEx so they will cache the same font
        const ss = parentGet().screenRectScale(Rect{}).s;

        const ask_size = @ceil(self.size * ss);
        const target_fraction = self.size / ask_size;
        const sized_font = self.resize(ask_size);

        const fce = fontCacheGet(sized_font);
        const skip = fce.height;
        //std.debug.print("lineSkip fontsize {d} is {d}\n", .{sized_font.size, skip});
        return skip * target_fraction * self.line_skip_factor;
    }
};

const GlyphInfo = struct {
    minx: f32,
    maxx: f32,
    advance: f32,
    miny: f32,
    maxy: f32,
    uv: @Vector(2, f32),
};

const FontCacheEntry = struct {
    used: bool = true,
    face: freetype.Face,
    height: f32,
    ascent: f32,
    glyph_info: std.AutoHashMap(u32, GlyphInfo),
    texture_atlas: *anyopaque,
    texture_atlas_size: Size,
    texture_atlas_regen: bool,

    pub fn hash(font: Font) u32 {
        var h = fnv.init();
        h.update(std.mem.asBytes(&font.ttf_bytes.ptr));
        h.update(std.mem.asBytes(&font.size));
        return h.final();
    }

    pub fn glyphInfoGet(self: *FontCacheEntry, codepoint: u32) GlyphInfo {
        if (self.glyph_info.get(codepoint)) |gi| {
            return gi;
        }

        self.face.loadChar(@intCast(u32, codepoint), .{ .render = false }) catch unreachable;
        const m = self.face.glyph().metrics();
        const minx = @intToFloat(f32, m.horiBearingX) / 64.0;
        const miny = self.ascent - @intToFloat(f32, m.horiBearingY) / 64.0;

        const gi = GlyphInfo{
            .minx = @floor(minx),
            .maxx = @ceil(minx + @intToFloat(f32, m.width) / 64.0),
            .advance = @ceil(@intToFloat(f32, m.horiAdvance) / 64.0),
            .miny = @floor(miny),
            .maxy = @ceil(miny + @intToFloat(f32, m.height) / 64.0),
            .uv = .{ 0, 0 },
        };

        // new glyph, need to regen texture atlas on next render
        //std.debug.print("new glyph {}\n", .{codepoint});
        self.texture_atlas_regen = true;

        self.glyph_info.put(codepoint, gi) catch unreachable;
        return gi;
    }
};

pub fn fontCacheGet(font: Font) *FontCacheEntry {
    var cw = current_window orelse unreachable;
    const fontHash = FontCacheEntry.hash(font);
    if (cw.font_cache.getPtr(fontHash)) |fce| {
        fce.used = true;
        return fce;
    }

    //std.debug.print("FontCacheGet creating font size {d} name \"{s}\"\n", .{font.size, font.name});

    var face = cw.ft2lib.createFaceMemory(font.ttf_bytes, 0) catch unreachable;
    face.setPixelSizes(0, @floatToInt(u32, font.size)) catch unreachable;

    const ascender = @intToFloat(f32, face.ascender()) / 64.0;
    const ss = @intToFloat(f32, face.size().metrics().y_scale) / 0x10000;
    const ascent = ascender * ss;
    //std.debug.print("fontcache size {d} ascender {d} scale {d} ascent {d}\n", .{font.size, ascender, scale, ascent});

    // make debug texture atlas so we can see if something later goes wrong
    const size = .{ .w = 10, .h = 10 };
    var pixels = cw.arena.alloc(u8, @floatToInt(usize, size.w * size.h) * 4) catch unreachable;
    std.mem.set(u8, pixels, 255);

    const entry = FontCacheEntry{
        .face = face,
        .height = @ceil(@intToFloat(f32, face.size().metrics().height) / 64.0),
        .ascent = @ceil(ascent),
        .glyph_info = std.AutoHashMap(u32, GlyphInfo).init(cw.gpa),
        .texture_atlas = cw.backend.textureCreate(pixels, @floatToInt(u32, size.w), @floatToInt(u32, size.h)),
        .texture_atlas_size = size,
        .texture_atlas_regen = true,
    };
    cw.font_cache.put(fontHash, entry) catch unreachable;

    return cw.font_cache.getPtr(fontHash).?;
}

const IconCacheEntry = struct {
    texture: *anyopaque,
    size: Size,
    used: bool = true,

    pub fn hash(tvg_bytes: []const u8, height: f32) u32 {
        var h = fnv.init();
        h.update(std.mem.asBytes(&tvg_bytes.ptr));
        h.update(std.mem.asBytes(&height));
        return h.final();
    }
};

pub fn iconWidth(name: []const u8, tvg_bytes: []const u8, height_natural: f32) f32 {
    const height = height_natural * windowNaturalScale();
    const ice = iconTexture(name, tvg_bytes, height);
    return ice.size.w / windowNaturalScale();
}

pub fn iconTexture(name: []const u8, tvg_bytes: []const u8, ask_height: f32) IconCacheEntry {
    var cw = current_window orelse unreachable;
    const icon_hash = IconCacheEntry.hash(tvg_bytes, ask_height);

    if (cw.icon_cache.getPtr(icon_hash)) |ice| {
        ice.used = true;
        return ice.*;
    }

    var image = tvg.rendering.renderBuffer(
        cw.arena,
        cw.arena,
        tvg.rendering.SizeHint{ .height = @floatToInt(u32, ask_height) },
        @intToEnum(tvg.rendering.AntiAliasing, 2),
        tvg_bytes,
    ) catch unreachable;
    defer image.deinit(cw.arena);

    var pixels: []u8 = undefined;
    pixels.ptr = @ptrCast([*]u8, image.pixels.ptr);
    pixels.len = image.pixels.len * 4;

    const texture = cw.backend.textureCreate(pixels, image.width, image.height);

    _ = name;
    //std.debug.print("created icon texture \"{s}\" ask height {d} size {d}x{d}\n", .{name, ask_height, image.width, image.height});

    const entry = IconCacheEntry{ .texture = texture, .size = .{ .w = @intToFloat(f32, image.width), .h = @intToFloat(f32, image.height) } };
    cw.icon_cache.put(icon_hash, entry) catch unreachable;

    return entry;
}

pub const RenderCmd = struct {
    clip: Rect,
    snap: bool,
    cmd: union(enum) {
        text: struct {
            font: Font,
            text: []const u8,
            rs: RectScale,
            color: Color,
        },
        debug_font_atlases: struct {
            rs: RectScale,
            color: Color,
        },
        icon: struct {
            name: []const u8,
            tvg_bytes: []const u8,
            rs: RectScale,
            colormod: Color,
        },
        pathFillConvex: struct {
            path: std.ArrayList(Point),
            color: Color,
        },
        pathStroke: struct {
            path: std.ArrayList(Point),
            closed: bool,
            thickness: f32,
            endcap_style: EndCapStyle,
            color: Color,
        },
    },
};

pub fn focusedWindow() bool {
    const cw = current_window orelse unreachable;
    if (cw.window_currentId == cw.focused_windowId) {
        return true;
    }

    return false;
}

pub fn focusedWindowId() u32 {
    const cw = current_window orelse unreachable;
    return cw.focused_windowId;
}

pub fn focusWindow(window_id: ?u32, iter: ?*EventIterator) void {
    const cw = current_window orelse unreachable;
    const winId = window_id orelse cw.window_currentId;
    if (cw.focused_windowId != winId) {
        cw.focused_windowId = winId;
        cueFrame();
        if (iter) |it| {
            if (cw.focused_windowId == cw.wd.id) {
                it.focusRemainingEvents(cw.focused_windowId, cw.focused_widgetId);
            } else {
                for (cw.floating_data.items) |*fd| {
                    if (cw.focused_windowId == fd.id) {
                        it.focusRemainingEvents(cw.focused_windowId, fd.focused_widgetId);
                        break;
                    }
                }
            }
        }
    }
}

pub fn raiseWindow(window_id: u32) void {
    const cw = current_window orelse unreachable;
    for (cw.floating_data.items) |fd, i| {
        if (fd.id == window_id) {
            _ = cw.floating_data.orderedRemove(i);
            cw.floating_data.append(fd) catch unreachable;
            break;
        }
    }
}

fn optionalEqual(comptime T: type, a: ?T, b: ?T) bool {
    if (a == null and b == null) {
        return true;
    } else if (a == null or b == null) {
        return false;
    } else {
        return (a.? == b.?);
    }
}

pub fn focusWidget(id: ?u32, iter: ?*EventIterator) void {
    const cw = current_window orelse unreachable;
    if (cw.focused_windowId == cw.wd.id) {
        if (!optionalEqual(u32, cw.focused_widgetId, id)) {
            cw.focused_widgetId = id;
            if (iter) |it| {
                it.focusRemainingEvents(cw.focused_windowId, cw.focused_widgetId);
            }
            cueFrame();
        }
    } else {
        for (cw.floating_data.items) |*fd| {
            if (cw.focused_windowId == fd.id) {
                if (!optionalEqual(u32, fd.focused_widgetId, id)) {
                    fd.focused_widgetId = id;
                    if (iter) |it| {
                        it.focusRemainingEvents(cw.focused_windowId, cw.focused_widgetId);
                    }
                    cueFrame();
                    break;
                }
            }
        }
    }
}

pub fn focusedWidgetId() ?u32 {
    const cw = current_window orelse unreachable;
    if (cw.focused_windowId == cw.wd.id) {
        return cw.focused_widgetId;
    } else {
        for (cw.floating_data.items) |*fd| {
            if (cw.focused_windowId == fd.id) {
                return fd.focused_widgetId;
            }
        }
    }

    return null;
}

pub fn focusedWidgetIdInCurrentWindow() ?u32 {
    const cw = current_window orelse unreachable;
    if (cw.window_currentId == cw.wd.id) {
        return cw.focused_widgetId;
    } else {
        for (cw.floating_data.items) |*fd| {
            if (cw.window_currentId == fd.id) {
                return fd.focused_widgetId;
            }
        }
    }

    return null;
}

pub const CursorKind = enum(u8) {
    arrow,
    ibeam,
    wait,
    crosshair,
    small_wait,
    arrow_nw_se,
    arrow_ne_sw,
    arrow_w_e,
    arrow_n_s,
    arrow_all,
    bad,
    hand,
};

pub fn cursorGetDragging() ?CursorKind {
    const cw = current_window orelse unreachable;
    return cw.cursor_dragging;
}

pub fn cursorSet(cursor: CursorKind) void {
    const cw = current_window orelse unreachable;
    cw.cursor_requested = cursor;
}

pub fn pathAddPoint(p: Point) void {
    const cw = current_window orelse unreachable;
    cw.path.append(p) catch unreachable;
}

pub fn pathAddRect(r: Rect, radius: Rect) void {
    var rad = radius;
    const maxrad = math.min(r.w, r.h) / 2;
    rad.x = math.min(rad.x, maxrad);
    rad.y = math.min(rad.y, maxrad);
    rad.w = math.min(rad.w, maxrad);
    rad.h = math.min(rad.h, maxrad);
    const tl = Point{ .x = r.x + rad.x, .y = r.y + rad.x };
    const bl = Point{ .x = r.x + rad.h, .y = r.y + r.h - rad.h };
    const br = Point{ .x = r.x + r.w - rad.w, .y = r.y + r.h - rad.w };
    const tr = Point{ .x = r.x + r.w - rad.y, .y = r.y + rad.y };
    pathAddArc(tl, rad.x, math.pi * 1.5, math.pi, @fabs(tl.y - bl.y) < 0.5);
    pathAddArc(bl, rad.h, math.pi, math.pi * 0.5, @fabs(bl.x - br.x) < 0.5);
    pathAddArc(br, rad.w, math.pi * 0.5, 0, @fabs(br.y - tr.y) < 0.5);
    pathAddArc(tr, rad.y, math.pi * 2.0, math.pi * 1.5, @fabs(tr.x - tl.x) < 0.5);
}

pub fn pathAddArc(center: Point, rad: f32, start: f32, end: f32, skip_end: bool) void {
    if (rad == 0) {
        pathAddPoint(center);
        return;
    }
    const err = 1.0;
    // angle that has err error between circle and segments
    const theta = math.acos(1.0 - math.min(rad, err) / rad);
    // make sure we never have less than 4 segments
    // so a full circle can't be less than a diamond
    const num_segments = math.max(@ceil((start - end) / theta), 4.0);
    const step = (start - end) / num_segments;

    const num = @floatToInt(u32, num_segments);
    var a: f32 = start;
    var i: u32 = 0;
    while (i < num) : (i += 1) {
        pathAddPoint(Point{ .x = center.x + rad * @cos(a), .y = center.y + rad * @sin(a) });
        a -= step;
    }

    if (!skip_end) {
        a = end;
        pathAddPoint(Point{ .x = center.x + rad * @cos(a), .y = center.y + rad * @sin(a) });
    }
}

pub fn pathFillConvex(col: Color) void {
    const cw = current_window orelse unreachable;
    if (cw.path.items.len < 3) {
        cw.path.clearAndFree();
        return;
    }

    if (cw.window_currentId != cw.wd.id) {
        var path_copy = std.ArrayList(Point).init(cw.arena);
        path_copy.appendSlice(cw.path.items) catch unreachable;
        var cmd = RenderCmd{ .snap = snap_to_pixels, .clip = clipGet(), .cmd = .{ .pathFillConvex = .{ .path = path_copy, .color = col } } };

        var i = cw.floating_data.items.len;
        while (i > 0) : (i -= 1) {
            const fw = &cw.floating_data.items[i - 1];
            if (fw.id == cw.window_currentId) {
                fw.render_cmds.append(cmd) catch unreachable;
                break;
            }
        }

        cw.path.clearAndFree();
        return;
    }

    var vtx = std.ArrayList(Vertex).initCapacity(cw.arena, cw.path.items.len * 2) catch unreachable;
    defer vtx.deinit();
    const idx_count = (cw.path.items.len - 2) * 3 + cw.path.items.len * 6;
    var idx = std.ArrayList(u32).initCapacity(cw.arena, idx_count) catch unreachable;
    defer idx.deinit();
    var col_trans = col;
    col_trans.a = 0;

    var i: usize = 0;
    while (i < cw.path.items.len) : (i += 1) {
        const ai = (i + cw.path.items.len - 1) % cw.path.items.len;
        const bi = i % cw.path.items.len;
        const ci = (i + 1) % cw.path.items.len;
        const aa = cw.path.items[ai];
        const bb = cw.path.items[bi];
        const cc = cw.path.items[ci];

        const diffab = Point.diff(aa, bb).normalize();
        const diffbc = Point.diff(bb, cc).normalize();
        // average of normals on each side
        const halfnorm = (Point{ .x = (diffab.y + diffbc.y) / 2, .y = (-diffab.x - diffbc.x) / 2 }).normalize().scale(0.5);

        var v: Vertex = undefined;
        // inner vertex
        v.pos.x = bb.x - halfnorm.x;
        v.pos.y = bb.y - halfnorm.y;
        v.col = col;
        vtx.append(v) catch unreachable;

        // outer vertex
        v.pos.x = bb.x + halfnorm.x;
        v.pos.y = bb.y + halfnorm.y;
        v.col = col_trans;
        vtx.append(v) catch unreachable;

        // indexes for fill
        if (i > 1) {
            idx.append(@intCast(u32, 0)) catch unreachable;
            idx.append(@intCast(u32, ai * 2)) catch unreachable;
            idx.append(@intCast(u32, bi * 2)) catch unreachable;
        }

        // indexes for aa fade from inner to outer
        idx.append(@intCast(u32, ai * 2)) catch unreachable;
        idx.append(@intCast(u32, ai * 2 + 1)) catch unreachable;
        idx.append(@intCast(u32, bi * 2)) catch unreachable;
        idx.append(@intCast(u32, ai * 2 + 1)) catch unreachable;
        idx.append(@intCast(u32, bi * 2 + 1)) catch unreachable;
        idx.append(@intCast(u32, bi * 2)) catch unreachable;
    }

    cw.backend.renderGeometry(null, vtx.items, idx.items);

    cw.path.clearAndFree();
}

pub const EndCapStyle = enum {
    none,
    square,
};

pub fn pathStroke(closed_in: bool, thickness: f32, endcap_style: EndCapStyle, col: Color) void {
    pathStrokeAfter(false, closed_in, thickness, endcap_style, col);
}

pub fn pathStrokeAfter(after: bool, closed_in: bool, thickness: f32, endcap_style: EndCapStyle, col: Color) void {
    const cw = current_window orelse unreachable;

    if (cw.path.items.len == 0) {
        return;
    }

    if (after or cw.window_currentId != cw.wd.id) {
        var path_copy = std.ArrayList(Point).init(cw.arena);
        path_copy.appendSlice(cw.path.items) catch unreachable;
        var cmd = RenderCmd{ .snap = snap_to_pixels, .clip = clipGet(), .cmd = .{ .pathStroke = .{ .path = path_copy, .closed = closed_in, .thickness = thickness, .endcap_style = endcap_style, .color = col } } };

        if (cw.window_currentId == cw.wd.id) {
            cw.render_cmds_after.append(cmd) catch unreachable;
        } else {
            var i = cw.floating_data.items.len;
            while (i > 0) : (i -= 1) {
                const fw = &cw.floating_data.items[i - 1];
                if (fw.id == cw.window_currentId) {
                    if (after) {
                        fw.render_cmds_after.append(cmd) catch unreachable;
                    } else {
                        fw.render_cmds.append(cmd) catch unreachable;
                    }
                    break;
                }
            }
        }

        cw.path.clearAndFree();
    } else {
        pathStrokeRaw(closed_in, thickness, endcap_style, col);
    }
}

pub fn pathStrokeRaw(closed_in: bool, thickness: f32, endcap_style: EndCapStyle, col: Color) void {
    const cw = current_window orelse unreachable;

    if (cw.path.items.len == 1) {
        // draw a circle with radius thickness at that point
        const center = cw.path.items[0];

        // remove old path so we don't have a center point
        cw.path.clearAndFree();

        pathAddArc(center, thickness, math.pi * 2.0, 0, true);
        pathFillConvex(col);
        cw.path.clearAndFree();
        return;
    }

    var closed: bool = closed_in;
    if (cw.path.items.len == 2) {
        // a single segment can't be closed
        closed = false;
    }

    var vtx_count = cw.path.items.len * 4;
    if (!closed) {
        vtx_count += 4;
    }
    var vtx = std.ArrayList(Vertex).initCapacity(cw.arena, vtx_count) catch unreachable;
    defer vtx.deinit();
    var idx_count = (cw.path.items.len - 1) * 18;
    if (closed) {
        idx_count += 18;
    } else {
        idx_count += 8 * 3;
    }
    var idx = std.ArrayList(u32).initCapacity(cw.arena, idx_count) catch unreachable;
    defer idx.deinit();
    var col_trans = col;
    col_trans.a = 0;

    var vtx_start: usize = 0;
    var i: usize = 0;
    while (i < cw.path.items.len) : (i += 1) {
        const ai = (i + cw.path.items.len - 1) % cw.path.items.len;
        const bi = i % cw.path.items.len;
        const ci = (i + 1) % cw.path.items.len;
        const aa = cw.path.items[ai];
        var bb = cw.path.items[bi];
        const cc = cw.path.items[ci];

        // the amount to move from bb to the edge of the line
        var halfnorm: Point = undefined;

        var v: Vertex = undefined;
        var diffab: Point = undefined;

        if (!closed and ((i == 0) or ((i + 1) == cw.path.items.len))) {
            if (i == 0) {
                const diffbc = Point.diff(bb, cc).normalize();
                // rotate by 90 to get normal
                halfnorm = Point{ .x = diffbc.y / 2, .y = (-diffbc.x) / 2 };

                if (endcap_style == .square) {
                    // square endcaps move bb out by thickness
                    bb.x += diffbc.x * thickness;
                    bb.y += diffbc.y * thickness;
                }

                // add 2 extra vertexes for endcap fringe
                vtx_start += 2;

                v.pos.x = bb.x - halfnorm.x * (thickness + 1.0) + diffbc.x;
                v.pos.y = bb.y - halfnorm.y * (thickness + 1.0) + diffbc.y;
                v.col = col_trans;
                vtx.append(v) catch unreachable;

                v.pos.x = bb.x + halfnorm.x * (thickness + 1.0) + diffbc.x;
                v.pos.y = bb.y + halfnorm.y * (thickness + 1.0) + diffbc.y;
                v.col = col_trans;
                vtx.append(v) catch unreachable;

                // add indexes for endcap fringe
                idx.append(@intCast(u32, 0)) catch unreachable;
                idx.append(@intCast(u32, vtx_start)) catch unreachable;
                idx.append(@intCast(u32, vtx_start + 1)) catch unreachable;

                idx.append(@intCast(u32, 0)) catch unreachable;
                idx.append(@intCast(u32, 1)) catch unreachable;
                idx.append(@intCast(u32, vtx_start)) catch unreachable;

                idx.append(@intCast(u32, 1)) catch unreachable;
                idx.append(@intCast(u32, vtx_start)) catch unreachable;
                idx.append(@intCast(u32, vtx_start + 2)) catch unreachable;

                idx.append(@intCast(u32, 1)) catch unreachable;
                idx.append(@intCast(u32, vtx_start + 2)) catch unreachable;
                idx.append(@intCast(u32, vtx_start + 2 + 1)) catch unreachable;
            } else if ((i + 1) == cw.path.items.len) {
                diffab = Point.diff(aa, bb).normalize();
                // rotate by 90 to get normal
                halfnorm = Point{ .x = diffab.y / 2, .y = (-diffab.x) / 2 };

                if (endcap_style == .square) {
                    // square endcaps move bb out by thickness
                    bb.x -= diffab.x * thickness;
                    bb.y -= diffab.y * thickness;
                }
            }
        } else {
            diffab = Point.diff(aa, bb).normalize();
            const diffbc = Point.diff(bb, cc).normalize();
            // average of normals on each side
            halfnorm = Point{ .x = (diffab.y + diffbc.y) / 2, .y = (-diffab.x - diffbc.x) / 2 };

            // scale averaged normal by angle between which happens to be the same as
            // dividing by the length^2
            const d2 = halfnorm.x * halfnorm.x + halfnorm.y * halfnorm.y;
            if (d2 > 0.000001) {
                halfnorm = halfnorm.scale(0.5 / d2);
            }

            // limit distance our vertexes can be from the point to 2 * thickness so
            // very small angles don't produce huge geometries
            const l = halfnorm.length();
            if (l > 2.0) {
                halfnorm = halfnorm.scale(2.0 / l);
            }
        }

        // side 1 inner vertex
        v.pos.x = bb.x - halfnorm.x * thickness;
        v.pos.y = bb.y - halfnorm.y * thickness;
        v.col = col;
        vtx.append(v) catch unreachable;

        // side 1 AA vertex
        v.pos.x = bb.x - halfnorm.x * (thickness + 1.0);
        v.pos.y = bb.y - halfnorm.y * (thickness + 1.0);
        v.col = col_trans;
        vtx.append(v) catch unreachable;

        // side 2 inner vertex
        v.pos.x = bb.x + halfnorm.x * thickness;
        v.pos.y = bb.y + halfnorm.y * thickness;
        v.col = col;
        vtx.append(v) catch unreachable;

        // side 2 AA vertex
        v.pos.x = bb.x + halfnorm.x * (thickness + 1.0);
        v.pos.y = bb.y + halfnorm.y * (thickness + 1.0);
        v.col = col_trans;
        vtx.append(v) catch unreachable;

        if (closed or ((i + 1) != cw.path.items.len)) {
            // indexes for fill
            idx.append(@intCast(u32, vtx_start + bi * 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4)) catch unreachable;

            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4)) catch unreachable;

            // indexes for aa fade from inner to outer side 1
            idx.append(@intCast(u32, vtx_start + bi * 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 1)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4 + 1)) catch unreachable;

            idx.append(@intCast(u32, vtx_start + bi * 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4 + 1)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4)) catch unreachable;

            // indexes for aa fade from inner to outer side 2
            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 3)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4 + 3)) catch unreachable;

            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + ci * 4 + 3)) catch unreachable;
        } else if (!closed and (i + 1) == cw.path.items.len) {
            // add 2 extra vertexes for endcap fringe
            v.pos.x = bb.x - halfnorm.x * (thickness + 1.0) - diffab.x;
            v.pos.y = bb.y - halfnorm.y * (thickness + 1.0) - diffab.y;
            v.col = col_trans;
            vtx.append(v) catch unreachable;

            v.pos.x = bb.x + halfnorm.x * (thickness + 1.0) - diffab.x;
            v.pos.y = bb.y + halfnorm.y * (thickness + 1.0) - diffab.y;
            v.col = col_trans;
            vtx.append(v) catch unreachable;

            // add indexes for endcap fringe
            idx.append(@intCast(u32, vtx_start + bi * 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 1)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 4)) catch unreachable;

            idx.append(@intCast(u32, vtx_start + bi * 4 + 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;

            idx.append(@intCast(u32, vtx_start + bi * 4 + 4)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 5)) catch unreachable;

            idx.append(@intCast(u32, vtx_start + bi * 4 + 2)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 3)) catch unreachable;
            idx.append(@intCast(u32, vtx_start + bi * 4 + 5)) catch unreachable;
        }
    }

    cw.backend.renderGeometry(null, vtx.items, idx.items);

    cw.path.clearAndFree();
}

pub fn windowFor(p: Point) u32 {
    const cw = current_window orelse unreachable;
    var i = cw.floating_data.items.len;
    while (i > 0) : (i -= 1) {
        const fw = &cw.floating_data.items[i - 1];
        if (fw.modal or fw.rect.contains(p)) {
            return fw.id;
        }
    }

    return cw.wd.id;
}

pub fn floatingWindowClosing(id: u32) void {
    const cw = current_window orelse unreachable;
    if (cw.floating_data.items.len > 0) {
        const fd = cw.floating_data.items[cw.floating_data.items.len - 1];
        if (fd.id == id) {
            _ = cw.floating_data.pop();
        } else {
            std.debug.print("floatingWindowClosing: last added floating window id {x} doesn't match {x}\n", .{ fd.id, id });
        }
    } else {
        std.debug.print("floatingWindowClosing: no floating windows\n", .{});
    }
}

pub fn floatingWindowAdd(id: u32, rect: Rect, modal: bool) void {
    const cw = current_window orelse unreachable;

    for (cw.floating_data.items) |*fd| {
        if (id == fd.id) {
            // this window was here previously, just update data
            fd.used = true;
            fd.rect = rect;
            fd.modal = modal;
            fd.render_cmds = std.ArrayList(RenderCmd).init(cw.arena);
            fd.render_cmds_after = std.ArrayList(RenderCmd).init(cw.arena);
            return;
        }
    }

    // haven't seen this window before, it goes on top
    const fd = Window.FloatingData{ .id = id, .rect = rect, .modal = modal, .render_cmds = std.ArrayList(RenderCmd).init(cw.arena), .render_cmds_after = std.ArrayList(RenderCmd).init(cw.arena) };
    cw.floating_data.append(fd) catch unreachable;
}

pub fn windowCurrentSet(id: u32) u32 {
    const cw = current_window orelse unreachable;
    const ret = cw.window_currentId;
    cw.window_currentId = id;
    return ret;
}

pub fn windowCurrentId() u32 {
    const cw = current_window orelse unreachable;
    return cw.window_currentId;
}

pub fn dragPreStart(p: Point, cursor: CursorKind, offset: Point) void {
    const cw = current_window orelse unreachable;
    cw.drag_state = .prestart;
    cw.drag_pt = p;
    cw.drag_offset = offset;
    cw.cursor_dragging = cursor;
}

pub fn dragStart(p: Point, cursor: CursorKind, offset: Point) void {
    const cw = current_window orelse unreachable;
    cw.drag_state = .dragging;
    cw.drag_pt = p;
    cw.drag_offset = offset;
    cw.cursor_dragging = cursor;
}

pub fn dragOffset() Point {
    const cw = current_window orelse unreachable;
    return cw.drag_offset;
}

pub fn dragging(p: Point) ?Point {
    const cw = current_window orelse unreachable;
    switch (cw.drag_state) {
        .none => return null,
        .dragging => {
            const dp = Point.diff(p, cw.drag_pt);
            cw.drag_pt = p;
            return dp;
        },
        .prestart => {
            const dp = Point.diff(p, cw.drag_pt);
            const dps = dp.scale(1 / windowNaturalScale());
            if (@fabs(dps.x) > 3 or @fabs(dps.y) > 3) {
                cw.drag_pt = p;
                cw.drag_state = .dragging;
                return dp;
            } else {
                return null;
            }
        },
    }
}

pub fn dragEnd() void {
    const cw = current_window orelse unreachable;
    cw.drag_state = .none;
}

pub fn mouseTotalMotion() Point {
    const cw = current_window orelse unreachable;
    return Point.diff(cw.mouse_pt, cw.mouse_pt_prev);
}

pub fn captureMouse(id: ?u32) void {
    const cw = current_window orelse unreachable;
    cw.captureID = id;
    if (id != null) {
        cw.captured_last_frame = true;
    }
}

pub fn captureMouseMaintain(id: u32) bool {
    const cw = current_window orelse unreachable;
    if (cw.captureID == id) {
        // to maintain capture, we must be on or above the
        // top modal window
        var i = cw.floating_data.items.len;
        while (i > 0) : (i -= 1) {
            const fw = &cw.floating_data.items[i - 1];
            if (fw.id == cw.window_currentId) {
                // maintaining capture
                break;
            } else if (fw.modal) {
                // found modal before we found current
                // cancel the capture, and cancel
                // any drag being done
                dragEnd();
                return false;
            }
        }

        // either our floating window as above the top modal
        // or there are no floating modal windows
        cw.captured_last_frame = true;
        return true;
    }

    return false;
}

pub fn captureMouseGet() ?u32 {
    const cw = current_window orelse unreachable;
    return cw.captureID;
}

pub fn clipGet() Rect {
    const cw = current_window orelse unreachable;
    return cw.clipRect;
}

pub fn clip(new: Rect) Rect {
    const cw = current_window orelse unreachable;
    var ret = cw.clipRect;
    clipSet(cw.clipRect.intersect(new));
    return ret;
}

pub fn clipSet(r: Rect) void {
    const cw = current_window orelse unreachable;
    cw.clipRect = r;
}

pub fn cueFrame() void {
    const cw = current_window orelse unreachable;
    cw.extra_frames_needed = 1;
}

pub fn animationRate() f32 {
    const cw = current_window orelse unreachable;
    return cw.rate;
}

pub fn FPS() f32 {
    const cw = current_window orelse unreachable;
    return cw.FPS();
}

pub fn parentGet() Widget {
    const cw = current_window orelse unreachable;
    return cw.wd.parent;
}

pub fn parentSet(w: Widget) Widget {
    var cw = current_window orelse unreachable;
    const ret = cw.wd.parent;
    cw.wd.parent = w;
    return ret;
}

pub fn popupSet(p: ?*PopupWidget) ?*PopupWidget {
    var cw = current_window orelse unreachable;
    const ret = cw.popup_current;
    cw.popup_current = p;
    return ret;
}

pub fn menuGet() ?*MenuWidget {
    const cw = current_window orelse unreachable;
    return cw.menu_current;
}

pub fn menuSet(m: ?*MenuWidget) ?*MenuWidget {
    var cw = current_window orelse unreachable;
    const ret = cw.menu_current;
    cw.menu_current = m;
    return ret;
}

pub fn windowRect() Rect {
    var cw = current_window orelse unreachable;
    return cw.wd.rect;
}

pub fn windowRectPixels() Rect {
    var cw = current_window orelse unreachable;
    return cw.rect_pixels;
}

pub fn windowNaturalScale() f32 {
    var cw = current_window orelse unreachable;
    return cw.natural_scale;
}

pub fn minSizeGetPrevious(id: u32) ?Size {
    var cw = current_window orelse unreachable;
    const ret = cw.widgets_min_size_prev.get(id);
    debug("{x} minSizeGetPrevious {?}", .{ id, ret });
    return ret;
}

pub fn minSizeSet(id: u32, s: Size) void {
    debug("{x} minSizeSet {}", .{ id, s });
    var cw = current_window orelse unreachable;
    return cw.widgets_min_size.put(id, s) catch unreachable;
}

pub fn hashIdKey(id: u32, key: []const u8) u32 {
    var h = fnv.init();
    h.value = id;
    h.update(key);
    return h.final();
}

const DataOffset = struct {
    begin: u32,
    end: u32,
};

pub fn dataSet(id: u32, key: []const u8, data: anytype) void {
    var cw = current_window orelse unreachable;
    const hash = hashIdKey(id, key);
    var bytes: []const u8 = undefined;
    const dt = @typeInfo(@TypeOf(data));
    if (dt == .Pointer and dt.Pointer.size == .Slice) {
        bytes = std.mem.sliceAsBytes(data);
    } else {
        bytes = std.mem.asBytes(&data);
    }
    {
        // save data for next frame
        const begin = @intCast(u32, cw.data.items.len);
        cw.data.appendSlice(bytes) catch unreachable;
        const end = @intCast(u32, cw.data.items.len);
        cw.data_offset.put(hash, DataOffset{ .begin = begin, .end = end }) catch unreachable;
    }

    if (!cw.data_offset_prev.contains(hash)) {
        // also save data for this frame, necessary for dialogs where we store
        // data and then access it at the end of the frame
        const begin = @intCast(u32, cw.data_prev.items.len);
        cw.data_prev.appendSlice(bytes) catch unreachable;
        const end = @intCast(u32, cw.data_prev.items.len);
        cw.data_offset_prev.put(hash, DataOffset{ .begin = begin, .end = end }) catch unreachable;
    }
}

pub fn dataGet(id: u32, key: []const u8, comptime T: type) ?T {
    var cw = current_window orelse unreachable;
    const offset = cw.data_offset_prev.get(hashIdKey(id, key));
    if (offset) |o| {
        const dt = @typeInfo(T);
        if (dt == .Pointer and dt.Pointer.size == .Slice) {
            return cw.data_prev.items[o.begin..o.end];
        } else {
            var bytes: [@sizeOf(T)]u8 = undefined;
            std.mem.copy(u8, &bytes, cw.data_prev.items[o.begin..o.end]);
            return std.mem.bytesAsValue(T, &bytes).*;
        }
    } else {
        return null;
    }
}

pub fn minSize(id: ?u32, min_size: Size) Size {
    var size = min_size;

    // Need to take the max of both given and previous.  ScrollArea could be
    // passed a min size Size{.w = 0, .h = 200} meaning to get the width from the
    // previous min size.
    if (id) |id2| {
        if (minSizeGetPrevious(id2)) |ms| {
            size = Size.max(size, ms);
        }
    }

    return size;
}

pub fn placeIn(id: ?u32, avail: Rect, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
    var size = minSize(id, min_size);

    if (e.horizontal()) {
        size.w = avail.w;
    }

    if (e.vertical()) {
        size.h = avail.h;
    }

    var r = avail.shrinkToSize(size);
    switch (g) {
        .upleft, .left, .downleft => r.x = avail.x,
        .up, .center, .down => r.x = avail.x + (avail.w - r.w) / 2.0,
        .upright, .right, .downright => r.x = avail.x + (avail.w - r.w),
    }

    switch (g) {
        .upleft, .up, .upright => r.y = avail.y,
        .left, .center, .right => r.y = avail.y + (avail.h - r.h) / 2.0,
        .downleft, .down, .downright => r.y = avail.y + (avail.h - r.h),
    }

    return r;
}

pub fn events() []Event {
    var cw = current_window orelse unreachable;
    return cw.events.items;
}

pub const EventIterator = struct {
    const Self = @This();
    id: u32,
    i: u32,
    r: Rect,

    pub fn init(id: u32, r: Rect) Self {
        return Self{ .id = id, .i = 0, .r = r };
    }

    pub fn focusRemainingEvents(self: *Self, focusWindowId: u32, focusWidgetId: ?u32) void {
        var k = self.i;
        var evts = events();
        while (k < evts.len) : (k += 1) {
            var e: *Event = &evts[k];
            e.focus_windowId = focusWindowId;
            e.focus_widgetId = focusWidgetId;
        }
    }

    pub fn next(self: *Self) ?*Event {
        return self.nextCleanup(false);
    }

    pub fn nextCleanup(self: *Self, cleanup: bool) ?*Event {
        var evts = events();
        while (self.i < evts.len) : (self.i += 1) {
            var e: *Event = &evts[self.i];
            if (e.handled) {
                continue;
            }

            switch (e.evt) {
                .key,
                .text,
                => {
                    if (cleanup) {
                        // window is catching all focus-routed events that didn't get
                        // processed (maybe the focus widget never showed up)
                        if (e.focus_windowId != self.id) {
                            continue;
                        }
                    } else {
                        if (e.focus_widgetId != self.id) {
                            continue;
                        }
                    }
                },

                .mouse => {
                    if (captureMouseGet()) |id| {
                        if (id != self.id) {
                            continue;
                        }
                    } else {
                        if (e.evt.mouse.floating_win != windowCurrentId()) {
                            continue;
                        }

                        if (!self.r.contains(e.evt.mouse.p)) {
                            continue;
                        }

                        if (!clipGet().contains(e.evt.mouse.p)) {
                            continue;
                        }
                    }
                },

                .close_popup => unreachable,
            }

            self.i += 1;
            return e;
        }

        return null;
    }
};

// Animations
// start_time and end_time are relative to the current frame time.  At the
// start of each frame both are reduced by the micros since the last frame.
//
// An animation will be active thru a frame where its end_time is <= 0, and be
// deleted at the beginning of the next frame.  See Spinner for an example of
// how to have a seemless continuous animation.

pub const Animation = struct {
    used: bool = true,
    start_val: f32,
    end_val: f32,
    start_time: i32 = 0,
    end_time: i32,

    pub fn lerp(a: *const Animation) f32 {
        var frac = @intToFloat(f32, -a.start_time) / @intToFloat(f32, a.end_time - a.start_time);
        frac = math.max(0, math.min(1, frac));
        return a.start_val + frac * (a.end_val - a.start_val);
    }
};

pub fn animate(id: u32, key: []const u8, a: Animation) void {
    var cw = current_window orelse unreachable;
    const h = hashIdKey(id, key);
    cw.animations.put(h, a) catch unreachable;
}

pub fn animationGet(id: u32, key: []const u8) ?Animation {
    var cw = current_window orelse unreachable;
    const h = hashIdKey(id, key);
    const val = cw.animations.getPtr(h);
    if (val) |v| {
        v.used = true;
        return v.*;
    }

    return null;
}

pub fn timerSet(id: u32, micros: i32) void {
    const a = Animation{ .start_val = 0, .end_val = 0, .start_time = micros, .end_time = micros };
    animate(id, "_timer", a);
}

pub fn timerGet(id: u32) ?i32 {
    if (animationGet(id, "_timer")) |a| {
        return a.start_time;
    } else {
        return null;
    }
}

pub fn timerExists(id: u32) bool {
    return timerGet(id) != null;
}

// returns true only on the frame where the timer expired
pub fn timerDone(id: u32) bool {
    if (timerGet(id)) |start| {
        if (start <= 0) {
            return true;
        }
    }

    return false;
}

const TabIndex = struct {
    windowId: u32,
    widgetId: u32,
    tabIndex: u16,
};

pub fn tabIndexSet(widget_id: u32, tab_index: ?u16) void {
    var cw = current_window orelse unreachable;
    const ti = TabIndex{ .windowId = cw.window_currentId, .widgetId = widget_id, .tabIndex = (tab_index orelse math.maxInt(u16)) };
    cw.tab_index.append(ti) catch unreachable;
}

pub fn tabIndexNext(iter: ?*EventIterator) void {
    const cw = current_window orelse unreachable;
    const widgetId = focusedWidgetId();
    var oldtab: ?u16 = null;
    if (widgetId != null) {
        for (cw.tab_index_prev.items) |ti| {
            if (ti.windowId == cw.focused_windowId and ti.widgetId == widgetId.?) {
                oldtab = ti.tabIndex;
                break;
            }
        }
    }

    // find the first widget with a tabindex greater than oldtab
    // or the first widget with lowest tabindex if oldtab is null
    var newtab: u16 = math.maxInt(u16);
    var newId: ?u32 = null;
    var foundFocus = false;

    for (cw.tab_index_prev.items) |ti| {
        if (ti.windowId == cw.focused_windowId) {
            if (ti.widgetId == widgetId) {
                foundFocus = true;
            } else if (foundFocus == true and oldtab != null and ti.tabIndex == oldtab.?) {
                // found the first widget after current that has the same tabindex
                newtab = ti.tabIndex;
                newId = ti.widgetId;
                break;
            } else if (oldtab == null or ti.tabIndex > oldtab.?) {
                if (newId == null or ti.tabIndex < newtab) {
                    newtab = ti.tabIndex;
                    newId = ti.widgetId;
                }
            }
        }
    }

    focusWidget(newId, iter);
}

pub fn tabIndexPrev(iter: ?*EventIterator) void {
    const cw = current_window orelse unreachable;
    const widgetId = focusedWidgetId();
    var oldtab: ?u16 = null;
    if (widgetId != null) {
        for (cw.tab_index_prev.items) |ti| {
            if (ti.windowId == cw.focused_windowId and ti.widgetId == widgetId.?) {
                oldtab = ti.tabIndex;
                break;
            }
        }
    }

    // find the last widget with a tabindex less than oldtab
    // or the last widget with highest tabindex if oldtab is null
    var newtab: u16 = 0;
    var newId: ?u32 = null;
    var foundFocus = false;

    for (cw.tab_index_prev.items) |ti| {
        if (ti.windowId == cw.focused_windowId) {
            if (ti.widgetId == widgetId) {
                foundFocus = true;

                if (oldtab != null and newtab == oldtab.?) {
                    // use last widget before that has the same tabindex
                    // might be none before so we'll go to null
                    break;
                }
            } else if (oldtab == null or ti.tabIndex < oldtab.? or (!foundFocus and ti.tabIndex == oldtab.?)) {
                if (ti.tabIndex >= newtab) {
                    newtab = ti.tabIndex;
                    newId = ti.widgetId;
                }
            }
        }
    }

    focusWidget(newId, iter);
}

pub const Vertex = struct {
    pos: Point,
    col: Color,
    uv: @Vector(2, f32),
};

// maps to OS window
pub const Window = struct {
    const Self = @This();

    pub const FloatingData = struct {
        used: bool = true,
        id: u32 = 0,
        rect: Rect = Rect{},
        modal: bool = false,
        focused_widgetId: ?u32 = null,
        render_cmds: std.ArrayList(RenderCmd),
        render_cmds_after: std.ArrayList(RenderCmd),
    };

    backend: Backend,

    window_currentId: u32 = 0,
    floating_data: std.ArrayList(FloatingData),

    // used to delay some rendering until after (like selection outlines)
    render_cmds_after: std.ArrayList(RenderCmd) = undefined,

    focused_windowId: u32 = 0,
    focused_widgetId: ?u32 = null, // this is specific to the base window
    focused_widgetId_last_frame: ?u32 = null, // only used to intially mark events

    events: std.ArrayList(Event) = undefined,
    // mouse_pt tracks the last position we got a mouse event for
    // 1) used to add position info to mouse wheel events
    // 2) used to highlight the widget under the mouse (MouseEvent.Kind.position event)
    // 3) used to change the cursor (MouseEvent.Kind.position event)
    // Start off screen so nothing is highlighted on the first frame
    mouse_pt: Point = Point{ .x = -1, .y = -1 },
    mouse_pt_prev: Point = Point{ .x = -1, .y = -1 },

    drag_state: enum {
        none,
        prestart,
        dragging,
    } = .none,
    drag_pt: Point = Point{},
    drag_offset: Point = Point{},

    frame_time_ns: i128 = 0,
    loop_wait_target: ?i128 = null,
    loop_wait_target_event: bool = false,
    loop_target_slop: i32 = 0,
    loop_target_slop_frames: i32 = 0,
    frame_times: [30]u32 = [_]u32{0} ** 30,

    rate: f32 = 0,
    extra_frames_needed: u8 = 0,
    clipRect: Rect = Rect{},

    menu_current: ?*MenuWidget = null,
    popup_current: ?*PopupWidget = null,
    theme: *const Theme = &theme_Adwaita,

    widgets_min_size_prev: std.AutoHashMap(u32, Size),
    widgets_min_size: std.AutoHashMap(u32, Size),
    data_prev: std.ArrayList(u8),
    data: std.ArrayList(u8),
    data_offset_prev: std.AutoHashMap(u32, DataOffset),
    data_offset: std.AutoHashMap(u32, DataOffset),
    animations: std.AutoHashMap(u32, Animation),
    tab_index_prev: std.ArrayList(TabIndex),
    tab_index: std.ArrayList(TabIndex),
    font_cache: std.AutoHashMap(u32, FontCacheEntry),
    icon_cache: std.AutoHashMap(u32, IconCacheEntry),
    dialogs: std.ArrayList(DialogEntry),

    ft2lib: freetype.Library = undefined,

    cursor_requested: CursorKind = .arrow,
    cursor_dragging: CursorKind = .arrow,

    wd: WidgetData = undefined,
    rect_pixels: Rect = Rect{}, // pixels
    natural_scale: f32 = 1.0,
    next_widget_ypos: f32 = 0,

    captureID: ?u32 = null,
    captured_last_frame: bool = false,

    gpa: std.mem.Allocator = undefined,
    arena: std.mem.Allocator = undefined,
    path: std.ArrayList(Point) = undefined,

    pub fn init(
        gpa: std.mem.Allocator,
        backend: Backend,
    ) Self {
        var fnv32 = fnv.init();
        var self = Self{
            .gpa = gpa,
            .floating_data = std.ArrayList(FloatingData).init(gpa),
            .widgets_min_size = std.AutoHashMap(u32, Size).init(gpa),
            .widgets_min_size_prev = std.AutoHashMap(u32, Size).init(gpa),
            .data_prev = std.ArrayList(u8).init(gpa),
            .data = std.ArrayList(u8).init(gpa),
            .data_offset_prev = std.AutoHashMap(u32, DataOffset).init(gpa),
            .data_offset = std.AutoHashMap(u32, DataOffset).init(gpa),
            .animations = std.AutoHashMap(u32, Animation).init(gpa),
            .tab_index_prev = std.ArrayList(TabIndex).init(gpa),
            .tab_index = std.ArrayList(TabIndex).init(gpa),
            .font_cache = std.AutoHashMap(u32, FontCacheEntry).init(gpa),
            .icon_cache = std.AutoHashMap(u32, IconCacheEntry).init(gpa),
            .dialogs = std.ArrayList(DialogEntry).init(gpa),
            .wd = WidgetData{ .id = fnv32.final() },
            .backend = backend,
        };

        self.focused_windowId = self.wd.id;
        self.frame_time_ns = std.time.nanoTimestamp();

        self.ft2lib = freetype.Library.init() catch unreachable;

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.floating_data.deinit();
        self.widgets_min_size.deinit();
        self.widgets_min_size_prev.deinit();
        self.data_prev.deinit();
        self.data.deinit();
        self.data_offset_prev.deinit();
        self.data_offset.deinit();
        self.animations.deinit();
        self.tab_index_prev.deinit();
        self.tab_index.deinit();
        self.font_cache.deinit();
        self.icon_cache.deinit();
        self.dialogs.deinit();
    }

    pub fn addEventKey(self: *Self, keysym: keys.Key, mod: keys.Mod, state: KeyEvent.Kind) bool {
        self.positionMouseEventRemove();
        defer self.positionMouseEventAdd();

        self.events.append(Event{ .focus_windowId = self.focused_windowId, .focus_widgetId = self.focused_widgetId_last_frame, .evt = AnyEvent{ .key = KeyEvent{
            .keysym = keysym,
            .mod = mod,
            .state = state,
        } } }) catch unreachable;

        return (self.wd.id != self.focused_windowId);
    }

    pub fn addEventText(self: *Self, text: []const u8) bool {
        self.positionMouseEventRemove();
        defer self.positionMouseEventAdd();

        self.events.append(Event{ .focus_windowId = self.focused_windowId, .focus_widgetId = self.focused_widgetId_last_frame, .evt = AnyEvent{ .text = TextEvent{
            .text = self.arena.dupe(u8, text) catch unreachable,
        } } }) catch unreachable;

        return (self.wd.id != self.focused_windowId);
    }

    pub fn addEventMouseMotion(self: *Self, x: f32, y: f32) bool {
        self.positionMouseEventRemove();
        defer self.positionMouseEventAdd();

        const newpt = (Point{ .x = x, .y = y }).scale(self.natural_scale);
        const dp = newpt.diff(self.mouse_pt);
        self.mouse_pt = newpt;
        const winId = windowFor(self.mouse_pt);

        // focus follows mouse:
        //focusWindow(winId, null);

        self.events.append(Event{ .focus_windowId = self.focused_windowId, .focus_widgetId = self.focused_widgetId_last_frame, .evt = AnyEvent{ .mouse = MouseEvent{
            .p = self.mouse_pt,
            .dp = dp,
            .wheel = 0,
            .floating_win = winId,
            .state = .motion,
        } } }) catch unreachable;

        return (self.wd.id != winId);
    }

    pub fn addEventMouseButton(self: *Self, state: MouseEvent.Kind) bool {
        self.positionMouseEventRemove();
        defer self.positionMouseEventAdd();

        const winId = windowFor(self.mouse_pt);

        self.events.append(Event{ .focus_windowId = self.focused_windowId, .focus_widgetId = self.focused_widgetId_last_frame, .evt = AnyEvent{ .mouse = MouseEvent{
            .p = self.mouse_pt,
            .dp = Point{},
            .wheel = 0,
            .floating_win = winId,
            .state = state,
        } } }) catch unreachable;

        if (state == .leftdown or state == .rightdown) {
            // add mouse focus event
            self.events.append(Event{ .focus_windowId = self.focused_windowId, .focus_widgetId = self.focused_widgetId_last_frame, .evt = AnyEvent{ .mouse = MouseEvent{
                .p = self.mouse_pt,
                .dp = Point{},
                .wheel = 0,
                .floating_win = winId,
                .state = .focus,
            } } }) catch unreachable;

            // have to check for the base window here because it doesn't have
            // an install() step
            if (winId == self.wd.id) {
                // focus but let the focus event propagate to widgets
                focusWindow(self.wd.id, null);
            }
        }

        return (self.wd.id != winId);
    }

    pub fn addEventMouseWheel(self: *Self, ticks: f32) bool {
        self.positionMouseEventRemove();
        defer self.positionMouseEventAdd();

        const winId = windowFor(self.mouse_pt);

        var ticks_adj = ticks;
        if (builtin.target.os.tag == .linux) {
            ticks_adj = ticks * 20;
        }
        //std.debug.print("mouse wheel {d}\n", .{ticks_adj});

        self.events.append(Event{ .focus_windowId = self.focused_windowId, .focus_widgetId = self.focused_widgetId_last_frame, .evt = AnyEvent{ .mouse = MouseEvent{
            .p = self.mouse_pt,
            .dp = Point{},
            .wheel = ticks_adj,
            .floating_win = winId,
            .state = .wheel_y,
        } } }) catch unreachable;

        return (self.wd.id != winId);
    }

    pub fn FPS(self: *const Self) f32 {
        const diff = self.frame_times[0];
        if (diff == 0) {
            return 0;
        }

        const avg = @intToFloat(f32, diff) / @intToFloat(f32, self.frame_times.len - 1);
        const fps = 1_000_000.0 / avg;
        return fps;
    }

    pub fn beginWait(self: *Self, has_event: bool) i128 {
        var new_time = math.max(self.frame_time_ns, std.time.nanoTimestamp());

        if (self.loop_wait_target) |target| {
            if (self.loop_wait_target_event and has_event) {
                // interrupted by event, so don't adjust slop for target
                //std.debug.print("beginWait interrupted by event\n", .{});
                return new_time;
            }

            //std.debug.print("beginWait adjusting slop\n", .{});
            // we were trying to sleep for a specific amount of time, adjust slop to
            // compensate if we didn't hit our target
            if (new_time > target) {
                // woke up later than expected
                self.loop_target_slop_frames = math.max(1, self.loop_target_slop_frames + 1);
                self.loop_target_slop += self.loop_target_slop_frames;
            } else if (new_time < target) {
                // woke up sooner than expected
                self.loop_target_slop_frames = math.min(-1, self.loop_target_slop_frames - 1);
                self.loop_target_slop += self.loop_target_slop_frames;

                // since we are early, spin a bit to guarantee that we never run before
                // the target
                //var i: usize = 0;
                //var first_time = new_time;
                while (new_time < target) {
                    //i += 1;
                    std.time.sleep(0);
                    new_time = math.max(self.frame_time_ns, std.time.nanoTimestamp());
                }

                //if (i > 0) {
                //  std.debug.print("    begin {d} spun {d} {d}us\n", .{self.loop_target_slop, i, @divFloor(new_time - first_time, 1000)});
                //}
            }
        }

        //std.debug.print("beginWait {d:6}\n", .{self.loop_target_slop});
        return new_time;
    }

    pub fn wait(self: *Self, end_micros: ?u32, maxFPS: ?f32) u32 {
        // end_micros is the naive value we want to be between last begin and next begin

        // minimum time to wait to hit max fps target
        var min_micros: u32 = 0;
        if (maxFPS) |mfps| {
            min_micros = @floatToInt(u32, 1_000_000.0 / mfps);
        }

        //std.debug.print("  end {d:6} min {d:6}", .{end_micros, min_micros});

        // wait_micros is amount on top of min_micros we will conditionally wait
        var wait_micros = (end_micros orelse 0) -| min_micros;

        // assume that we won't target a specific time to sleep but if we do
        // calculate the targets before removing so_far and slop
        self.loop_wait_target = null;
        self.loop_wait_target_event = false;
        const target_min = min_micros;
        const target = min_micros + wait_micros;

        // how long it's taken from begin to here
        const so_far_nanos = math.max(self.frame_time_ns, std.time.nanoTimestamp()) - self.frame_time_ns;
        var so_far_micros = @intCast(u32, @divFloor(so_far_nanos, 1000));
        //std.debug.print("  far {d:6}", .{so_far_micros});

        // take time from min_micros first
        const min_so_far = math.min(so_far_micros, min_micros);
        so_far_micros -= min_so_far;
        min_micros -= min_so_far;

        // then take time from wait_micros
        const min_so_far2 = math.min(so_far_micros, wait_micros);
        so_far_micros -= min_so_far2;
        wait_micros -= min_so_far2;

        var slop = self.loop_target_slop;

        // get slop we can take out of min_micros
        const min_us_slop = math.min(slop, min_micros);
        slop -= min_us_slop;
        if (min_us_slop >= 0) {
            min_micros -= @intCast(u32, min_us_slop);
        } else {
            min_micros += @intCast(u32, -min_us_slop);
        }

        // remaining slop we can take out of wait_micros
        const wait_us_slop = math.min(slop, wait_micros);
        slop -= wait_us_slop;
        if (wait_us_slop >= 0) {
            wait_micros -= @intCast(u32, wait_us_slop);
        } else {
            wait_micros += @intCast(u32, -wait_us_slop);
        }

        //std.debug.print("  min {d:6}", .{min_micros});
        if (min_micros > 0) {
            // wait unconditionally for fps target
            std.time.sleep(min_micros * 1000);
            self.loop_wait_target = self.frame_time_ns + (target_min * 1000);
        }

        if (end_micros == null) {
            // no target, wait indefinitely for next event
            self.loop_wait_target = null;
            //std.debug.print("  wait indef\n", .{});
            return std.math.maxInt(u32);
        } else if (wait_micros > 0) {
            // wait conditionally
            // since we have a timeout we will try to hit that target but set our
            // flag so that we don't adjust for the target if we wake up to an event
            self.loop_wait_target = self.frame_time_ns + (target * 1000);
            self.loop_wait_target_event = true;
            //std.debug.print("  wait {d:6}\n", .{wait_micros});
            return wait_micros;
        } else {
            // trying to hit the target but ran out of time
            //std.debug.print("  wait none\n", .{});
            return 0;
            // if we had a wait target from min_micros leave it
        }
    }

    pub fn begin(
        self: *Self,
        arena: std.mem.Allocator,
        time_ns: i128,
    ) void {
        var micros_since_last: u32 = 0;
        if (time_ns > self.frame_time_ns) {
            // enforce monotinicity
            const nanos_since_last = time_ns - self.frame_time_ns;
            micros_since_last = @intCast(u32, @divFloor(nanos_since_last, std.time.ns_per_us));
            self.frame_time_ns = time_ns;
        }

        //std.debug.print(" frame_time_ns {d}\n", .{self.frame_time_ns});

        current_window = self;

        self.cursor_requested = .arrow;

        self.arena = arena;
        self.render_cmds_after = std.ArrayList(RenderCmd).init(arena);
        self.path = std.ArrayList(Point).init(arena);

        {
            var i: usize = 0;
            while (i < self.floating_data.items.len) {
                var fd = &self.floating_data.items[i];
                if (fd.used) {
                    fd.used = false;
                    i += 1;
                } else {
                    _ = self.floating_data.orderedRemove(i);
                }
            }
        }

        self.events = std.ArrayList(Event).init(arena);

        for (self.frame_times) |_, i| {
            if (i == (self.frame_times.len - 1)) {
                self.frame_times[i] = 0;
            } else {
                self.frame_times[i] = self.frame_times[i + 1] + micros_since_last;
            }
        }

        self.focused_widgetId_last_frame = focusedWidgetId();

        self.widgets_min_size_prev.deinit();
        self.widgets_min_size_prev = self.widgets_min_size;
        self.widgets_min_size = @TypeOf(self.widgets_min_size).init(self.widgets_min_size.allocator);

        self.data_prev.deinit();
        self.data_prev = self.data;
        self.data = @TypeOf(self.data).init(self.data.allocator);

        self.data_offset_prev.deinit();
        self.data_offset_prev = self.data_offset;
        self.data_offset = @TypeOf(self.data_offset).init(self.data_offset.allocator);

        self.tab_index_prev.deinit();
        self.tab_index_prev = self.tab_index;
        self.tab_index = @TypeOf(self.tab_index).init(self.tab_index.allocator);

        self.rect_pixels = self.backend.pixelSize().rect();
        clipSet(self.rect_pixels);

        self.wd.rect = self.backend.windowSize().rect();
        self.natural_scale = self.rect_pixels.w / self.wd.rect.w;

        debug("window size {d} x {d} renderer size {d} x {d} scale {d}", .{ self.wd.rect.w, self.wd.rect.h, self.rect_pixels.w, self.rect_pixels.h, self.natural_scale });

        _ = windowCurrentSet(self.wd.id);

        self.extra_frames_needed -|= 1;
        if (micros_since_last == 0) {
            self.rate = 3600;
        } else {
            self.rate = @intToFloat(f32, micros_since_last) / 1_000_000;
        }

        {
            const micros: i32 = if (micros_since_last > math.maxInt(i32)) math.maxInt(i32) else @intCast(i32, micros_since_last);
            var deadAnimations = std.ArrayList(u32).init(arena);
            defer deadAnimations.deinit();
            var it = self.animations.iterator();
            while (it.next()) |kv| {
                if (!kv.value_ptr.used or kv.value_ptr.end_time <= 0) {
                    deadAnimations.append(kv.key_ptr.*) catch unreachable;
                } else {
                    kv.value_ptr.used = false;
                    kv.value_ptr.start_time -|= micros;
                    kv.value_ptr.end_time -|= micros;
                    if (kv.value_ptr.start_time <= 0 and kv.value_ptr.end_time > 0) {
                        cueFrame();
                    }
                }
            }

            for (deadAnimations.items) |id| {
                _ = self.animations.remove(id);
            }
        }

        {
            var deadFonts = std.ArrayList(u32).init(arena);
            defer deadFonts.deinit();
            var it = self.font_cache.iterator();
            while (it.next()) |kv| {
                if (kv.value_ptr.used) {
                    kv.value_ptr.used = false;
                } else {
                    deadFonts.append(kv.key_ptr.*) catch unreachable;
                }
            }

            for (deadFonts.items) |id| {
                var tce = self.font_cache.fetchRemove(id);
                tce.?.value.glyph_info.deinit();
                tce.?.value.face.deinit();
            }

            //std.debug.print("font_cache {d}\n", .{self.font_cache.count()});
        }

        {
            var deadIcons = std.ArrayList(u32).init(arena);
            defer deadIcons.deinit();
            var it = self.icon_cache.iterator();
            while (it.next()) |kv| {
                if (kv.value_ptr.used) {
                    kv.value_ptr.used = false;
                } else {
                    deadIcons.append(kv.key_ptr.*) catch unreachable;
                }
            }

            for (deadIcons.items) |id| {
                const ice = self.icon_cache.fetchRemove(id);
                self.backend.textureDestroy(ice.?.value.texture);
            }

            //std.debug.print("icon_cache {d}\n", .{self.icon_cache.count()});
        }

        if (!self.captured_last_frame) {
            self.captureID = null;
        }
        self.captured_last_frame = false;

        self.wd.parent = self.widget();
        self.menu_current = null;

        self.next_widget_ypos = self.wd.rect.y;

        // We want a position mouse event to do mouse cursors.  It needs to be
        // final so if there was a drag end the cursor will still be set
        // correctly.  We don't know when the client gives us the last event,
        // so make our position event now, and addEvent* functions will remove
        // and re-add to keep it as the final event.
        self.positionMouseEventAdd();

        self.backend.begin(arena);
    }

    fn positionMouseEventAdd(self: *Self) void {
        self.events.append(Event{ .evt = AnyEvent{ .mouse = MouseEvent{
            .p = self.mouse_pt,
            .dp = Point{},
            .wheel = 0,
            .floating_win = windowFor(self.mouse_pt),
            .state = .position,
        } } }) catch unreachable;
    }

    fn positionMouseEventRemove(self: *Self) void {
        const e = self.events.pop();
        if (e.evt != .mouse or e.evt.mouse.state != .position) {
            // std.debug.print("positionMouseEventRemove removed a non-mouse or non-position event\n", .{});
        }
    }

    // Return the cursor the gui wants.  Client code should cache this if
    // switching the platform's cursor is expensive.
    pub fn cursorRequested(self: *const Self) CursorKind {
        if (self.drag_state == .dragging) {
            return self.cursor_dragging;
        } else {
            return self.cursor_requested;
        }
    }

    // Return the cursor the gui wants or null if mouse is not in gui windows.
    // Client code should cache this if switching the platform's cursor is
    // expensive.
    pub fn cursorRequestedFloating(self: *const Self) ?CursorKind {
        if (self.captureID != null or windowFor(self.mouse_pt) != self.wd.id) {
            // gui owns the cursor if we have mouse capture or if the mouse is above
            // a floating window
            return self.cursorRequested();
        } else {
            // no capture, not above a floating window, so client owns the cursor
            return null;
        }
    }

    pub fn renderCommands(self: *Self, queue: *std.ArrayList(RenderCmd)) void {
        for (queue.items) |*drc| {
            snap_to_pixels = drc.snap;
            clipSet(drc.clip);
            switch (drc.cmd) {
                .text => |t| {
                    renderText(t.font, t.text, t.rs, t.color);
                },
                .debug_font_atlases => |t| {
                    debugRenderFontAtlases(t.rs, t.color);
                },
                .icon => |i| {
                    renderIcon(i.name, i.tvg_bytes, i.rs, i.colormod);
                },
                .pathFillConvex => |pf| {
                    self.path.appendSlice(pf.path.items) catch unreachable;
                    pathFillConvex(pf.color);
                    pf.path.deinit();
                },
                .pathStroke => |ps| {
                    self.path.appendSlice(ps.path.items) catch unreachable;
                    pathStrokeRaw(ps.closed, ps.thickness, ps.endcap_style, ps.color);
                    ps.path.deinit();
                },
            }
        }

        queue.clearAndFree();
    }

    fn dialogsShow(self: *Self) void {
        var i: usize = 0;
        while (i < self.dialogs.items.len) {
            const dialog = self.dialogs.items[i];
            if (dialog.display(dialog.id)) {
                _ = self.dialogs.orderedRemove(i);
            } else {
                i += 1;
            }
        }
    }

    pub fn end(self: *Self) ?u32 {
        self.dialogsShow();

        const oldclip = clipGet();
        self.renderCommands(&self.render_cmds_after);
        for (self.floating_data.items) |*fw| {
            self.renderCommands(&fw.render_cmds);
            self.renderCommands(&fw.render_cmds_after);
        }
        clipSet(oldclip);

        // events may have been tagged with a focus widget that never showed up, so
        // we wouldn't even get them bubbled
        var iter = EventIterator.init(self.wd.id, self.rect_pixels);
        while (iter.nextCleanup(true)) |e| {
            // doesn't matter if we mark events has handled or not because this is
            // the end of the line for all events
            if (e.evt == .mouse) {
                if (e.evt.mouse.state == .focus) {
                    // unhandled click, clear focus
                    focusWidget(null, null);
                }
            } else if (e.evt == .key) {
                if (e.evt.key.state == .down and e.evt.key.keysym == .tab) {
                    if (e.evt.key.mod.shift()) {
                        tabIndexPrev(&iter);
                    } else {
                        tabIndexNext(&iter);
                    }
                }
            }
        }

        self.mouse_pt_prev = self.mouse_pt;

        if (self.focusedWindowLost()) {
            // if the floating window that was focused went away, focus the highest
            // remaining one
            if (self.floating_data.items.len > 0) {
                const fdata = self.floating_data.items[self.floating_data.items.len - 1];
                focusWindow(fdata.id, null);
            } else {
                focusWindow(self.wd.id, null);
            }

            cueFrame();
        }

        // Check that the final event was our synthetic mouse position event.
        // If one of the addEvent* functions forgot to add the synthetic mouse
        // event to the end this will print a debug message.
        self.positionMouseEventRemove();

        self.backend.end();

        // This is what cueFrame affects
        if (self.extra_frames_needed > 0) {
            return 0;
        }

        // If there are current animations, return 0 so we go as fast as we can.
        // If all animations are scheduled in the future, pick the soonest start.
        var ret: ?u32 = null;
        var it = self.animations.iterator();
        while (it.next()) |kv| {
            if (kv.value_ptr.used) {
                if (kv.value_ptr.start_time > 0) {
                    const st = @intCast(u32, kv.value_ptr.start_time);
                    ret = math.min(ret orelse st, st);
                } else if (kv.value_ptr.end_time > 0) {
                    ret = 0;
                    break;
                }
            }
        }

        return ret;
    }

    pub fn focusedWindowLost(self: *Self) bool {
        if (self.wd.id == self.focused_windowId) {
            return false;
        } else {
            for (self.floating_data.items) |*fw| {
                if (fw.id == self.focused_windowId) {
                    return false;
                }
            }
        }

        return true;
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        var r = self.wd.rect;
        r.y = self.next_widget_ypos;
        const ret = placeIn(id, r, min_size, e, g);
        self.next_widget_ypos += ret.h;
        return ret;
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        // os window doesn't size itself based on children
        _ = self;
        _ = s;
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        const scaled = r.scale(self.natural_scale);
        return RectScale{ .r = scaled.offset(self.rect_pixels), .s = self.natural_scale };
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        // window does cleanup events, but not normal events
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        switch (e.evt) {
            .close_popup => |cp| {
                e.handled = true;
                if (cp.intentional) {
                    // when a popup is closed due to a menu item being chosen,
                    // the window that spawned it (which had focus previously)
                    // should become focused again
                    focusWindow(self.wd.id, null);
                }
            },
            else => {},
        }

        // can't bubble past the base window
    }
};

pub fn popup(src: std.builtin.SourceLocation, id_extra: usize, initialRect: Rect, opts: Options) *PopupWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(PopupWidget) catch unreachable;
    ret.* = PopupWidget.init(src, id_extra, initialRect, opts);
    ret.widget().processEvents(); // not strictly needed
    ret.install();
    return ret;
}

pub const PopupWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{ .corner_radius = Rect.all(5), .border = Rect.all(1), .padding = Rect.all(4), .background = true, .color_style = .window };

    wd: WidgetData = undefined,
    options: Options = undefined,
    prev_windowId: u32 = 0,
    parent_popup: ?*PopupWidget = null,
    have_popup_child: bool = false,
    layout: MenuWidget = undefined,
    initialRect: Rect = Rect{},
    prevClip: Rect = Rect{},

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, initialRect: Rect, opts: Options) Self {
        var self = Self{};

        // options is really for our embedded MenuWidget, so save them for the
        // end of install()
        self.options = defaults.override(opts);

        // the popup itself doesn't have any styling, it comes from the
        // embedded MenuWidget
        // passing options.rect will stop WidgetData.init from calling
        // rectFor which is important because we are outside normal layout
        self.wd = WidgetData.init(src, id_extra, .{ .rect = .{} });

        self.initialRect = initialRect;
        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} Popup {}", .{ self.wd.id, self.wd.rect });

        // Popup is outside normal widget flow, a menu can pop up outside the
        // current clip
        self.prevClip = clipGet();
        clipSet(windowRectPixels());

        _ = parentSet(self.widget());

        self.prev_windowId = windowCurrentSet(self.wd.id);
        self.parent_popup = popupSet(self);

        if (minSizeGetPrevious(self.wd.id)) |_| {
            self.wd.rect = Rect.fromPoint(self.initialRect.topleft());
            const ms = minSize(self.wd.id, self.options.min_size orelse Size{});
            self.wd.rect.w = ms.w;
            self.wd.rect.h = ms.h;
            self.wd.rect = placeOnScreen(self.initialRect, self.wd.rect);
        } else {
            self.wd.rect = placeOnScreen(self.initialRect, Rect.fromPoint(self.initialRect.topleft()));
            focusWindow(self.wd.id, null);

            // need a second frame to fit contents (FocusWindow calls cueFrame but
            // here for clarity)
            cueFrame();
        }

        // outside normal flow, so don't get rect from parent
        const rs = self.screenRectScale(self.wd.rect);
        floatingWindowAdd(self.wd.id, rs.r, false);

        // we are using MenuWidget to do border/background but floating windows
        // don't have margin, so turn that off
        self.layout = MenuWidget.init(@src(), 0, .vertical, self.options.override(.{ .margin = .{} }));
        self.layout.install();
    }

    pub fn close(self: *Self) void {
        floatingWindowClosing(self.wd.id);
        cueFrame();
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.rect, min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        _ = self;
        const s = windowNaturalScale();
        const scaled = r.scale(s);
        return RectScale{ .r = scaled.offset(windowRectPixels()), .s = s };
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        // popup does cleanup events, but not normal events
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        switch (e.evt) {
            .close_popup => |cp| {
                // close and continue bubbling
                if (cp.intentional) {
                    // if we call close() when not intentional (like from losing
                    // focus because a dialog), then calling floatingWindowClosing
                    // will show a warning because we wouldn't be the last floating
                    // window on the stack
                    self.close();
                }

                self.wd.parent.bubbleEvent(e);
            },
            else => {},
        }

        // otherwise popups don't bubble events
    }

    pub fn chainFocused(self: *Self, self_call: bool) bool {
        if (!self_call) {
            // if we got called by someone else, then we have a popup child
            self.have_popup_child = true;
        }

        var ret: bool = false;

        // we have to call chainFocused on our parent if we have one so we
        // can't return early

        if (self.wd.id == focusedWindowId()) {
            // we are focused
            ret = true;
        }

        if (self.parent_popup) |pp| {
            // we had a parent popup, is that focused
            if (pp.chainFocused(false)) {
                ret = true;
            }
        } else if (self.prev_windowId == focusedWindowId()) {
            // no parent popup, is our parent window focused
            ret = true;
        }

        return ret;
    }

    pub fn deinit(self: *Self) void {
        // outside normal flow, so don't get rect from parent
        var closing: bool = false;
        const rs = self.screenRectScale(self.wd.rect);
        var iter = EventIterator.init(self.wd.id, rs.r);
        while (iter.nextCleanup(true)) |e| {
            if (e.evt == .mouse) {
                // mark all events as handled so no mouse events are handled by
                // windows under us
                e.handled = true;
                if (e.evt.mouse.state == .focus) {
                    // unhandled click, clear focus
                    focusWidget(null, null);
                }
            } else if (e.evt == .key) {
                if (e.evt.key.state == .down and e.evt.key.keysym == .escape) {
                    e.handled = true;
                    var closeE = Event{ .evt = AnyEvent{ .close_popup = ClosePopupEvent{} } };
                    self.bubbleEvent(&closeE);
                } else if (e.evt.key.state == .down and e.evt.key.keysym == .tab) {
                    e.handled = true;
                    if (e.evt.key.mod.shift()) {
                        tabIndexPrev(null);
                    } else {
                        tabIndexNext(null);
                    }
                } else if (e.evt.key.state == .down and e.evt.key.keysym == .up) {
                    e.handled = true;
                    tabIndexPrev(&iter);
                } else if (e.evt.key.state == .down and e.evt.key.keysym == .down) {
                    e.handled = true;
                    tabIndexNext(&iter);
                } else if (e.evt.key.state == .down and e.evt.key.keysym == .left) {
                    e.handled = true;
                    self.close();
                    closing = true;
                    focusWindow(self.prev_windowId, &iter);
                    if (self.layout.parentMenu) |pm| {
                        pm.submenus_activated = false;
                    }
                }
            }
        }

        if (!closing and !self.have_popup_child and !self.chainFocused(true)) {
            // if a popup chain is open and the user focuses a different window
            // (not the parent of the popups), then we want to close the popups

            // only the last popup can do the check, you can't query the focus
            // status of children, only parents
            var closeE = Event{ .evt = AnyEvent{ .close_popup = ClosePopupEvent{ .intentional = false } } };
            self.bubbleEvent(&closeE);
        }

        self.layout.deinit();
        dataSet(self.wd.id, "_rect", self.wd.rect);
        self.wd.minSizeSetAndCue();
        // outside normal layout, don't call minSizeForChild or
        // wd.minSizeReportToParent
        _ = popupSet(self.parent_popup);
        _ = parentSet(self.wd.parent);
        _ = windowCurrentSet(self.prev_windowId);
        clipSet(self.prevClip);
    }
};

pub fn floatingWindow(src: std.builtin.SourceLocation, id_extra: usize, modal: bool, rect: ?*Rect, openflag: ?*bool, opts: Options) *FloatingWindowWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(FloatingWindowWidget) catch unreachable;
    ret.* = FloatingWindowWidget.init(src, id_extra, modal, rect, openflag, opts);
    ret.install(); // events processed here for floating window
    return ret;
}

pub const FloatingWindowWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .corner_radius = Rect.all(5),
        .border = Rect.all(1),
        .background = true,
        .color_style = .window,
    };

    wd: WidgetData = undefined,
    options: Options = undefined,
    modal: bool = false,
    captured: bool = false,
    prev_windowId: u32 = 0,
    io_rect: ?*Rect = null,
    layout: BoxWidget = undefined,
    openflag: ?*bool = null,
    first_frame: bool = false,
    prevClip: Rect = Rect{},
    autoPosSize: struct {
        autopos: bool,
        autosize: bool,
    } = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, modal: bool, io_rect: ?*Rect, openflag: ?*bool, opts: Options) Self {
        var self = Self{};

        // options is really for our embedded BoxWidget, so save them for the
        // end of install()
        self.options = defaults.override(opts);

        // the floating window itself doesn't have any styling, it comes from
        // the embedded BoxWidget
        // passing options.rect will stop WidgetData.init from calling rectFor
        // which is important because we are outside normal layout
        self.wd = WidgetData.init(src, id_extra, .{ .rect = .{} });

        self.modal = modal;
        self.io_rect = io_rect;
        self.openflag = openflag;

        if (self.io_rect) |ior| {
            // user is storing the rect for us across open/close
            self.wd.rect = ior.*;
        } else {
            // we store the rect (only while the window is open)
            self.wd.rect = dataGet(self.wd.id, "_rect", Rect) orelse Rect{};
        }

        if (dataGet(self.wd.id, "_autoPosSize", @TypeOf(self.autoPosSize))) |aps| {
            self.autoPosSize = aps;
        } else {
            self.autoPosSize = .{
                .autopos = (self.wd.rect.x == 0 and self.wd.rect.y == 0),
                .autosize = (self.wd.rect.w == 0 and self.wd.rect.h == 0),
            };
        }

        var ms = self.options.min_size orelse Size{};
        if (minSizeGetPrevious(self.wd.id)) |min_size| {
            ms = Size.max(ms, min_size);

            if (self.autoPosSize.autosize) {
                self.wd.rect.w = ms.w;
                self.wd.rect.h = ms.h;
                //std.debug.print("autosize to {}\n", .{self.wd.rect});
            }

            if (self.autoPosSize.autopos) {
                // only position ourselves once
                self.autoPosSize.autopos = false;

                // make sure that we stay on the screen
                self.wd.rect.x = math.max(0, windowRect().w / 2 - self.wd.rect.w / 2);
                self.wd.rect.y = math.max(0, windowRect().h / 2 - self.wd.rect.h / 2);
                //std.debug.print("autopos to {}\n", .{self.wd.rect});
            }
        } else {
            // first frame we are being shown
            self.first_frame = true; // for user code
            focusWindow(self.wd.id, null);

            if (self.autoPosSize.autopos or self.autoPosSize.autosize) {
                // need a second frame to position or fit contents (FocusWindow calls
                // cueFrame but here for clarity)
                cueFrame();

                // hide our first frame so the user doesn't see a jump when we
                // autopos/autosize
                self.wd.rect = .{};
            }
        }

        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} FloatingWindow {}", .{ self.wd.id, self.wd.rect });

        _ = parentSet(self.widget());
        self.prev_windowId = windowCurrentSet(self.wd.id);

        // FloatingWindow is outside normal widget flow, a dialog needs to paint on
        // top of the whole screen
        self.prevClip = clipGet();
        clipSet(windowRectPixels());

        self.captured = captureMouseMaintain(self.wd.id);

        // processEventsBefore can change self.wd.rect
        self.processEventsBefore();

        // outside normal flow, so don't get rect from parent
        const rs = self.screenRectScale(self.wd.rect);
        floatingWindowAdd(self.wd.id, rs.r, self.modal);

        if (self.modal) {
            // paint over everything below
            pathAddRect(windowRectPixels(), Rect.all(0));
            var col = self.options.color();
            col.a = 100;
            pathFillConvex(col);
        }

        // we are using BoxWidget to do border/background but floating windows
        // don't have margin, so turn that off
        self.layout = BoxWidget.init(@src(), 0, .vertical, self.options.override(.{ .margin = .{}, .expand = .both }));
        self.layout.install();
    }

    pub fn processEventsBefore(self: *Self) void {
        // outside normal flow, so don't get rect from parent
        const rs = self.screenRectScale(self.wd.rect);
        var iter = EventIterator.init(self.wd.id, rs.r);
        while (iter.next()) |e| {
            if (e.evt == .mouse) {
                var corner: bool = false;
                if (e.evt.mouse.p.x > rs.r.x + rs.r.w - 15 * rs.s and
                    e.evt.mouse.p.y > rs.r.y + rs.r.h - 15 * rs.s)
                {
                    // we are over the bottom-left resize corner
                    corner = true;
                }

                if (e.evt.mouse.state == .focus) {
                    // focus but let the focus event propagate to widgets
                    focusWindow(self.wd.id, &iter);
                }

                if (self.captured or corner) {
                    if (e.evt.mouse.state == .leftdown) {
                        // capture and start drag
                        captureMouse(self.wd.id);
                        dragStart(e.evt.mouse.p, .arrow_nw_se, Point.diff(rs.r.bottomRight(), e.evt.mouse.p));
                        e.handled = true;
                    } else if (e.evt.mouse.state == .leftup) {
                        // stop drag and capture
                        captureMouse(null);
                        dragEnd();
                        e.handled = true;
                    } else if (e.evt.mouse.state == .motion) {
                        // move if dragging
                        if (dragging(e.evt.mouse.p)) |dps| {
                            if (cursorGetDragging() == CursorKind.crosshair) {
                                const dp = dps.scale(1 / rs.s);
                                self.wd.rect.x += dp.x;
                                self.wd.rect.y += dp.y;
                            } else if (cursorGetDragging() == CursorKind.arrow_nw_se) {
                                const p = e.evt.mouse.p.plus(dragOffset()).scale(1 / rs.s);
                                self.wd.rect.w = math.max(40, p.x - self.wd.rect.x);
                                self.wd.rect.h = math.max(10, p.y - self.wd.rect.y);
                                self.autoPosSize.autosize = false;
                            }
                            // don't need cueFrame() because we're before drawing
                            e.handled = true;
                        }
                    } else if (e.evt.mouse.state == .position) {
                        if (corner) {
                            cursorSet(.arrow_nw_se);
                            e.handled = true;
                        }
                    }
                }
            }
        }
    }

    pub fn processEventsAfter(self: *Self) void {
        // outside normal flow, so don't get rect from parent
        const rs = self.screenRectScale(self.wd.rect);
        var iter = EventIterator.init(self.wd.id, rs.r);
        // duplicate processEventsBefore (minus corner stuff) because you could
        // have a click down, motion, and up in same frame and you wouldn't know
        // you needed to do anything until you got capture here
        while (iter.nextCleanup(true)) |e| {
            // mark all events as handled so no mouse events are handled by windows
            // under us
            e.handled = true;
            if (e.evt == .mouse) {
                if (e.evt.mouse.state == .focus) {
                    focusWidget(null, null);
                } else if (e.evt.mouse.state == .leftdown) {
                    // capture and start drag
                    captureMouse(self.wd.id);
                    dragPreStart(e.evt.mouse.p, .crosshair, Point{});
                } else if (e.evt.mouse.state == .leftup) {
                    // stop drag and capture
                    captureMouse(null);
                    dragEnd();
                } else if (e.evt.mouse.state == .motion) {
                    // move if dragging
                    if (dragging(e.evt.mouse.p)) |dps| {
                        if (cursorGetDragging() == CursorKind.crosshair) {
                            const dp = dps.scale(1 / rs.s);
                            self.wd.rect.x += dp.x;
                            self.wd.rect.y += dp.y;
                        } else if (cursorGetDragging() == CursorKind.arrow_nw_se) {
                            const p = e.evt.mouse.p.plus(dragOffset()).scale(1 / rs.s);
                            self.wd.rect.w = math.max(40, p.x - self.wd.rect.x);
                            self.wd.rect.h = math.max(10, p.y - self.wd.rect.y);
                            self.autoPosSize.autosize = false;
                        }
                        cueFrame();
                    }
                }
            } else if (e.evt == .key) {
                // catch any tabs that weren't handled by widgets
                if (e.evt.key.state == .down and e.evt.key.keysym == .tab) {
                    if (e.evt.key.mod.shift()) {
                        tabIndexPrev(&iter);
                    } else {
                        tabIndexNext(&iter);
                    }
                }
            }
        }
    }

    pub fn close(self: *Self) void {
        floatingWindowClosing(self.wd.id);
        if (self.openflag) |of| {
            of.* = false;
        }
        cueFrame();
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.rect, min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        _ = self;
        const s = windowNaturalScale();
        const scaled = r.scale(s);
        return RectScale{ .r = scaled.offset(windowRectPixels()), .s = s };
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        // floating window doesn't process events normally
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        switch (e.evt) {
            .close_popup => |cp| {
                e.handled = true;
                if (cp.intentional) {
                    // when a popup is closed because the user chose to, the
                    // window that spawned it (which had focus previously)
                    // should become focused again
                    focusWindow(self.wd.id, null);
                }
            },
            else => {},
        }

        // floating windows don't bubble any events
    }

    pub fn deinit(self: *Self) void {
        self.processEventsAfter();
        self.layout.deinit();
        if (self.io_rect) |ior| {
            // user is storing the rect for us across open/close
            if (!self.autoPosSize.autopos) {
                // if we are autopositioning, then this is the first frame and we set
                // our rect to 0 so the user wouldn't see the jump, so don't store it
                // back out this frame
                ior.* = self.wd.rect;
            }
        } else {
            // we store the rect
            dataSet(self.wd.id, "_rect", self.wd.rect);
        }
        dataSet(self.wd.id, "_autoPosSize", self.autoPosSize);
        self.wd.minSizeSetAndCue();
        // outside normal layout, don't call minSizeForChild or
        // wd.minSizeReportToParent
        _ = parentSet(self.wd.parent);
        _ = windowCurrentSet(self.prev_windowId);
        clipSet(self.prevClip);
    }
};

pub fn windowHeader(str: []const u8, right_str: []const u8, openflag: ?*bool) void {
    var over = gui.overlay(@src(), 0, .{ .expand = .horizontal });

    if (gui.buttonIcon(@src(), 0, 14, "close", gui.icons.papirus.actions.window_close_symbolic, .{ .gravity = .left, .corner_radius = Rect.all(14), .padding = Rect.all(2), .margin = Rect.all(2) })) {
        if (openflag) |of| {
            of.* = false;
        }
    }

    gui.labelNoFormat(@src(), 0, str, .{ .gravity = .center, .expand = .horizontal, .font_style = .heading });
    gui.labelNoFormat(@src(), 0, right_str, .{ .gravity = .right });

    var iter = EventIterator.init(over.wd.id, over.wd.contentRectScale().r);
    while (iter.next()) |e| {
        if (e.evt == .mouse and e.evt.mouse.state == .leftdown) {
            raiseWindow(windowCurrentId());
        }
    }

    over.deinit();

    gui.separator(@src(), 0, .{ .gravity = .down, .expand = .horizontal });
}

pub const DialogDisplay = *const fn (u32) bool;
pub const DialogCallAfter = *const fn (u32, DialogResponse) void;
pub const DialogEntry = struct {
    id: u32,
    display: DialogDisplay,
};
pub const DialogResponse = enum(u8) {
    CLOSED = 0,
    OK = 1,
};

pub fn dialogCustom(src: std.builtin.SourceLocation, id_extra: usize, display: DialogDisplay) u32 {
    const cw = current_window orelse unreachable;
    const parent = parentGet();
    const id = parent.extendID(src, id_extra);
    for (cw.dialogs.items) |*d| {
        if (d.id == id) {
            d.display = display;
            break;
        }
    } else {
        cw.dialogs.append(DialogEntry{ .id = id, .display = display }) catch unreachable;
    }

    return id;
}

pub fn dialogOk(src: std.builtin.SourceLocation, id_extra: usize, modal: bool, title: []const u8, msg: []const u8, callafter: ?DialogCallAfter) void {
    const id = gui.dialogCustom(src, id_extra, dialogOkDisplay);
    gui.dataSet(id, "_modal", modal);
    gui.dataSet(id, "_title", title);
    gui.dataSet(id, "_msg", msg);
    if (callafter) |ca| {
        gui.dataSet(id, "_callafter", ca);
    }
}

pub fn dialogOkDisplay(id: u32) bool {
    const modal = gui.dataGet(id, "_modal", bool) orelse {
        std.debug.print("Error: lost data for dialog {x}\n", .{id});
        return true;
    };
    gui.dataSet(id, "_modal", modal);

    const title = gui.dataGet(id, "_title", []const u8) orelse {
        std.debug.print("Error: lost data for dialog {x}\n", .{id});
        return true;
    };
    gui.dataSet(id, "_title", title);

    const message = gui.dataGet(id, "_msg", []const u8) orelse {
        std.debug.print("Error: lost data for dialog {x}\n", .{id});
        return true;
    };
    gui.dataSet(id, "_msg", message);

    const callafter = gui.dataGet(id, "_callafter", DialogCallAfter);
    if (callafter) |ca| {
        gui.dataSet(id, "_callafter", ca);
    }

    var win = gui.floatingWindow(@src(), id, modal, null, null, .{});
    defer win.deinit();

    var header_openflag = true;
    gui.windowHeader(title, "", &header_openflag);
    if (!header_openflag) {
        win.close();
        if (callafter) |ca| {
            ca(id, gui.DialogResponse.CLOSED);
        }
        return true;
    }

    var tl = gui.textLayout(@src(), 0, .{ .expand = .horizontal, .min_size = .{ .w = 250 } });
    tl.addText(message, .{});
    tl.deinit();

    if (gui.button(@src(), 0, "Ok", .{ .gravity = .center, .tab_index = 1 })) {
        win.close();
        if (callafter) |ca| {
            ca(id, gui.DialogResponse.OK);
        }
        return true;
    }

    return false;
}

pub var expander_defaults: Options = .{
    .padding = Rect.all(2),
    .font_style = .heading,
};

pub fn expander(src: std.builtin.SourceLocation, id_extra: usize, label_str: []const u8, opts: Options) bool {
    const options = expander_defaults.override(opts);

    var bc = ButtonContainerWidget.init(src, id_extra, true, options);
    bc.widget().processEvents();
    bc.install();
    defer bc.deinit();

    var expanded: bool = false;
    if (gui.dataGet(bc.wd.id, "_expand", bool)) |e| {
        expanded = e;
    }

    if (bc.clicked) {
        expanded = !expanded;
    }

    var bcbox = BoxWidget.init(@src(), 0, .horizontal, options.strip());
    defer bcbox.deinit();
    bcbox.install();
    const size = options.font().lineSkip();
    if (expanded) {
        icon(@src(), 0, size, "down_arrow", gui.icons.papirus.actions.pan_down_symbolic, .{ .gravity = .left });
    } else {
        icon(@src(), 0, size, "right_arrow", gui.icons.papirus.actions.pan_end_symbolic, .{ .gravity = .left });
    }
    labelNoFormat(@src(), 0, label_str, options.strip());

    gui.dataSet(bc.wd.id, "_expand", expanded);

    return expanded;
}

pub fn paned(src: std.builtin.SourceLocation, id_extra: usize, dir: gui.Direction, collapse_size: f32, opts: Options) *PanedWidget {
    var ret = gui.currentWindow().arena.create(PanedWidget) catch unreachable;
    ret.* = PanedWidget.init(src, id_extra, dir, collapse_size, opts);
    ret.widget().processEvents();
    ret.install();
    return ret;
}

pub const PanedWidget = struct {
    const Self = @This();

    const Data = struct {
        split_ratio: f32,
        rect: Rect,
    };

    const handle_size = 4;

    wd: WidgetData = undefined,

    split_ratio: f32 = undefined,
    dir: gui.Direction = undefined,
    collapse_size: f32 = 0,
    captured: bool = false,
    hovered: bool = false,
    data: Data = undefined,
    first_side_id: ?u32 = null,
    prevClip: Rect = Rect{},

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, dir: gui.Direction, collapse_size: f32, opts: Options) Self {
        var self = Self{};
        self.wd = WidgetData.init(src, id_extra, opts);
        self.dir = dir;
        self.collapse_size = collapse_size;
        self.captured = captureMouseMaintain(self.wd.id);

        const rect = self.wd.contentRect();

        if (gui.dataGet(self.wd.id, "_data", Data)) |d| {
            self.split_ratio = d.split_ratio;
            switch (self.dir) {
                .horizontal => {
                    if (d.rect.w >= self.collapse_size and rect.w < self.collapse_size) {
                        // collapsing
                        self.animate(1.0);
                    } else if (d.rect.w < self.collapse_size and rect.w >= self.collapse_size) {
                        // expanding
                        self.animate(0.5);
                    }
                },
                .vertical => {
                    if (d.rect.w >= self.collapse_size and rect.w < self.collapse_size) {
                        // collapsing
                        self.animate(1.0);
                    } else if (d.rect.w < self.collapse_size and rect.w >= self.collapse_size) {
                        // expanding
                        self.animate(0.5);
                    }
                },
            }
        } else {
            // first frame
            switch (self.dir) {
                .horizontal => {
                    if (rect.w < self.collapse_size) {
                        self.split_ratio = 1.0;
                    } else {
                        self.split_ratio = 0.5;
                    }
                },
                .vertical => {
                    if (rect.w < self.collapse_size) {
                        self.split_ratio = 1.0;
                    } else if (rect.w >= self.collapse_size) {
                        self.split_ratio = 0.5;
                    }
                },
            }
        }

        if (gui.animationGet(self.wd.id, "_split_ratio")) |a| {
            self.split_ratio = a.lerp();
        }

        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} Paned {}", .{ self.wd.id, self.wd.rect });
        self.wd.borderAndBackground();
        self.prevClip = clip(self.wd.contentRectScale().r);

        if (!self.collapsed()) {
            if (self.hovered) {
                const rs = self.wd.contentRectScale();
                var r = rs.r;
                const thick = handle_size * rs.s;
                switch (self.dir) {
                    .horizontal => {
                        r.x += r.w * self.split_ratio - thick / 2;
                        r.w = thick;
                        const height = r.h / 5;
                        r.y += r.h / 2 - height / 2;
                        r.h = height;
                    },
                    .vertical => {
                        r.y += r.h * self.split_ratio - thick / 2;
                        r.h = thick;
                        const width = r.w / 5;
                        r.x += r.w / 2 - width / 2;
                        r.w = width;
                    },
                }
                pathAddRect(r, Rect.all(thick));
                pathFillConvex(self.wd.options.color().transparent(0.5));
            }
        }

        _ = parentSet(self.widget());
    }

    pub fn collapsed(self: *Self) bool {
        const rect = self.wd.contentRect();
        switch (self.dir) {
            .horizontal => return (rect.w < self.collapse_size),
            .vertical => return (rect.h < self.collapse_size),
        }
    }

    pub fn showOther(self: *Self) void {
        if (self.split_ratio == 0.0) {
            self.animate(1.0);
        } else if (self.split_ratio == 1.0) {
            self.animate(0.0);
        }
    }

    fn animate(self: *Self, end_val: f32) void {
        gui.animate(self.wd.id, "_split_ratio", gui.Animation{ .start_val = self.split_ratio, .end_val = end_val, .end_time = 250_000 });
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) gui.Rect {
        if (self.first_side_id == null or self.first_side_id.? == id) {
            self.first_side_id = id;
            var r = self.wd.contentRect();
            if (self.collapsed()) {
                if (self.split_ratio == 0.0) {
                    r.w = 0;
                    r.h = 0;
                } else {
                    switch (self.dir) {
                        .horizontal => r.x -= (r.w - (r.w * self.split_ratio)),
                        .vertical => r.y -= (r.h - (r.h * self.split_ratio)),
                    }
                }
            } else {
                switch (self.dir) {
                    .horizontal => r.w = r.w * self.split_ratio - handle_size / 2,
                    .vertical => r.h = r.h * self.split_ratio - handle_size / 2,
                }
            }
            return gui.placeIn(id, r, min_size, e, g);
        } else {
            var r = self.wd.contentRect();
            if (self.collapsed()) {
                if (self.split_ratio == 1.0) {
                    r.w = 0;
                    r.h = 0;
                } else {
                    switch (self.dir) {
                        .horizontal => {
                            r.x = r.w * self.split_ratio;
                        },
                        .vertical => {
                            r.y = r.h * self.split_ratio;
                        },
                    }
                }
            } else {
                switch (self.dir) {
                    .horizontal => {
                        const first = r.w * self.split_ratio - handle_size / 2;
                        r.w -= first;
                        r.x += first + handle_size / 2;
                    },
                    .vertical => {
                        const first = r.h * self.split_ratio - handle_size / 2;
                        r.h -= first;
                        r.y += first + handle_size / 2;
                    },
                }
            }
            return gui.placeIn(id, r, min_size, e, g);
        }
    }

    pub fn minSizeForChild(self: *Self, s: gui.Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, r: gui.Rect) gui.RectScale {
        return self.wd.parent.screenRectScale(r);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        if (e.evt == .mouse) {
            var target: f32 = undefined;
            var mouse: f32 = undefined;
            var cursor: CursorKind = undefined;
            switch (self.dir) {
                .horizontal => {
                    target = iter.r.x + iter.r.w * self.split_ratio;
                    mouse = e.evt.mouse.p.x;
                    cursor = .arrow_w_e;
                },
                .vertical => {
                    target = iter.r.y + iter.r.h * self.split_ratio;
                    mouse = e.evt.mouse.p.y;
                    cursor = .arrow_n_s;
                },
            }

            if (self.captured or @fabs(mouse - target) < (5 * windowNaturalScale())) {
                self.hovered = true;
                e.handled = true;
                if (e.evt.mouse.state == .leftdown) {
                    // capture and start drag
                    captureMouse(self.wd.id);
                    dragPreStart(e.evt.mouse.p, cursor, Point{});
                } else if (e.evt.mouse.state == .leftup) {
                    // stop possible drag and capture
                    captureMouse(null);
                    dragEnd();
                } else if (e.evt.mouse.state == .motion) {
                    // move if dragging
                    if (dragging(e.evt.mouse.p)) |dps| {
                        _ = dps;
                        switch (self.dir) {
                            .horizontal => {
                                self.split_ratio = (e.evt.mouse.p.x - iter.r.x) / iter.r.w;
                            },
                            .vertical => {
                                self.split_ratio = (e.evt.mouse.p.y - iter.r.y) / iter.r.h;
                            },
                        }

                        self.split_ratio = math.max(0.0, math.min(1.0, self.split_ratio));
                    }
                } else if (e.evt.mouse.state == .position) {
                    cursorSet(cursor);
                }
            }
        }
    }

    pub fn bubbleEvent(self: *Self, e: *gui.Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        clipSet(self.prevClip);
        gui.dataSet(self.wd.id, "_data", Data{ .split_ratio = self.split_ratio, .rect = self.wd.contentRect() });
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = gui.parentSet(self.wd.parent);
    }
};

// TextLayout doesn't have a natural width.  If it's min_size.w was 0, then it
// would calculate a huge min_size.h assuming only 1 character per line can
// fit.  To prevent starting in weird situations, TextLayout defaults to having
// a min_size.w so at least you can see what is going on.
pub fn textLayout(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) *TextLayoutWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(TextLayoutWidget) catch unreachable;
    ret.* = TextLayoutWidget.init(src, id_extra, opts);
    ret.install();
    return ret;
}

pub const TextLayoutWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .margin = Rect.all(4),
        .padding = Rect.all(4),
        .background = true,
        .color_style = .content,
        .min_size = .{ .w = 25 },
    };

    wd: WidgetData = undefined,
    corners: [4]?Rect = [_]?Rect{null} ** 4,
    insert_pt: Point = Point{},
    prevClip: Rect = Rect{},

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) Self {
        const options = defaults.override(opts);
        return Self{ .wd = WidgetData.init(src, id_extra, options) };
    }

    pub fn install(self: *Self) void {
        _ = parentSet(self.widget());
        debug("{x} TextLayout {}", .{ self.wd.id, self.wd.rect });

        const rs = self.wd.contentRectScale();

        if (!rs.r.empty()) {
            self.wd.borderAndBackground();
        }

        self.prevClip = clip(rs.r);
        self.insert_pt = self.wd.contentRect().topleft();
    }

    pub fn format(self: *Self, comptime fmt: []const u8, args: anytype, opts: Options) void {
        var cw = current_window orelse unreachable;
        const l = std.fmt.allocPrint(cw.arena, fmt, args) catch unreachable;
        self.addText(l, opts);
    }

    pub fn addText(self: *Self, text: []const u8, opts: Options) void {
        const options = self.wd.options.override(opts);
        var iter = std.mem.split(u8, text, "\n");
        var first: bool = true;
        const startx = self.wd.contentRect().x;
        const lineskip = options.font().lineSkip();
        while (iter.next()) |line| {
            if (first) {
                first = false;
            } else {
                self.insert_pt.y += lineskip;
                self.insert_pt.x = startx;
            }
            self.addTextNoNewlines(line, options);
        }
    }

    pub fn addTextNoNewlines(self: *Self, text: []const u8, opts: Options) void {
        const options = self.wd.options.override(opts);
        const msize = options.font().textSize("m");
        const lineskip = options.font().lineSkip();
        var txt = text;

        const rect = self.wd.contentRect();
        const container_width = if (self.screenRectScale(rect).r.empty()) self.wd.min_size.w else rect.w;

        while (txt.len > 0) {
            var linestart = rect.x;
            var linewidth = container_width;
            var width = linewidth - self.insert_pt.x;
            for (self.corners) |corner| {
                if (corner) |cor| {
                    if (math.max(cor.y, self.insert_pt.y) < math.min(cor.y + cor.h, self.insert_pt.y + lineskip)) {
                        linewidth -= cor.w;
                        if (linestart == cor.x) {
                            linestart = (cor.x + cor.w);
                        }

                        if (self.insert_pt.x <= (cor.x + cor.w)) {
                            width -= cor.w;
                            if (self.insert_pt.x >= cor.x) {
                                self.insert_pt.x = (cor.x + cor.w);
                            }
                        }
                    }
                }
            }

            var end: usize = undefined;
            var s = options.font().textSizeEx(txt, width, &end);

            //std.debug.print("1 txt to {d} \"{s}\"\n", .{end, txt[0..end]});

            // if we are boxed in too much by corner widgets drop to next line
            if (s.w > width and linewidth < rect.w) {
                self.insert_pt.y += lineskip;
                self.insert_pt.x = rect.x;
                continue;
            }

            if (end < txt.len and linewidth > (10 * msize.w)) {
                const space: []const u8 = &[_]u8{' '};
                // now we are under the length limit but might be in the middle of a word
                // look one char further because we might be right at the end of a word
                const spaceIdx = std.mem.lastIndexOfLinear(u8, txt[0 .. end + 1], space);
                if (spaceIdx) |si| {
                    end = si + 1;
                    s = options.font().textSize(txt[0..end]);
                } else if (self.insert_pt.x > linestart) {
                    // can't fit breaking on space, but we aren't starting at the left edge
                    // so drop to next line
                    self.insert_pt.y += lineskip;
                    self.insert_pt.x = rect.x;
                    continue;
                }
            }

            // We want to render text, but no sense in doing it if we are off the end
            if (self.insert_pt.y < rect.y + rect.h) {
                const rs = self.screenRectScale(Rect{ .x = self.insert_pt.x, .y = self.insert_pt.y, .w = width, .h = math.max(0, rect.y + rect.h - self.insert_pt.y) });
                //log.debug("renderText: {} {s} {}", .{rs.r, txt[0..end], options.color()});
                renderText(options.font(), txt[0..end], rs, options.color());
            }

            // even if we don't actually render, need to update insert_pt and minSize
            // like we did because our parent might size based on that (might be in a
            // scroll area)
            self.insert_pt.x += s.w;
            const size = Size{ .w = 0, .h = self.insert_pt.y - rect.y + s.h };
            self.wd.min_size.h = math.max(self.wd.min_size.h, self.wd.padSize(size).h);
            txt = txt[end..];

            // move insert_pt to next line if we have more text
            if (txt.len > 0) {
                self.insert_pt.y += lineskip;
                self.insert_pt.x = rect.x;
            }
        }
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        const ret = placeIn(id, self.wd.contentRect(), min_size, e, g);
        const i: usize = switch (g) {
            .upleft => 0,
            .upright => 1,
            .downleft => 2,
            .downright => 3,
            else => blk: {
                std.debug.print("adding child to TextLayout with unsupported gravity (must be .upleft, .upright, .downleft, or .downright)\n", .{});
                break :blk 0;
            },
        };
        self.corners[i] = ret;
        return ret;
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        const padded = self.wd.padSize(s);
        self.wd.min_size.w = math.max(self.wd.min_size.w, padded.w);
        self.wd.min_size.h += padded.h;
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        return self.wd.parent.screenRectScale(r);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        _ = iter;

        if (bubbleable(e)) {
            self.bubbleEvent(e);
        }
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        clipSet(self.prevClip);
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub fn context(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) *ContextWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(ContextWidget) catch unreachable;
    ret.* = ContextWidget.init(src, id_extra, opts);
    ret.install();
    return ret;
}

pub const ContextWidget = struct {
    const Self = @This();
    wd: WidgetData = undefined,

    winId: u32 = undefined,
    focused: bool = false,
    activePt: Point = Point{},

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) Self {
        var self = Self{};
        self.wd = WidgetData.init(src, id_extra, opts);
        self.winId = windowCurrentId();
        if (focusedWidgetIdInCurrentWindow()) |fid| {
            if (fid == self.wd.id) {
                self.focused = true;
            }
        }

        if (dataGet(self.wd.id, "_activePt", Point)) |a| {
            self.activePt = a;
        }

        return self;
    }

    pub fn install(self: *Self) void {
        _ = parentSet(self.widget());
        debug("{x} Context {}", .{ self.wd.id, self.wd.rect });
        self.wd.borderAndBackground();
    }

    pub fn activePoint(self: *Self) ?Point {
        if (self.focused) {
            return self.activePt;
        }

        return null;
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect(), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, rect: Rect) RectScale {
        return self.wd.parent.screenRectScale(rect);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        switch (e.evt) {
            .close_popup => {
                if (self.focused) {
                    const focused_winId = focusedWindowId();
                    focusWindow(self.winId, null);
                    focusWidget(null, null);
                    focusWindow(focused_winId, null);
                }
            },
            else => {},
        }

        if (!e.handled) {
            self.wd.parent.bubbleEvent(e);
        }
    }

    pub fn processMouseEventsAfter(self: *Self) void {
        var focused_this_frame: bool = false;
        const rs = self.wd.borderRectScale();
        var iter = EventIterator.init(self.wd.id, rs.r);
        while (iter.next()) |e| {
            switch (e.evt) {
                .mouse => {
                    if (e.evt.mouse.state == .rightdown) {
                        e.handled = true;
                        focusWidget(self.wd.id, &iter);
                        self.focused = true;
                        focused_this_frame = true;

                        // scale the point back to natural so we can use it in Popup
                        self.activePt = e.evt.mouse.p.scale(1 / windowNaturalScale());

                        // offset just enough so when Popup first appears nothing is highlighted
                        self.activePt.x += 1;
                    } else if (e.evt.mouse.state == .focus) {
                        if (focused_this_frame) {
                            e.handled = true;
                        }
                    }
                },
                else => {},
            }
        }
    }

    pub fn deinit(self: *Self) void {
        self.processMouseEventsAfter();
        if (self.focused) {
            dataSet(self.wd.id, "_activePt", self.activePt);
        }
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub fn overlay(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) *OverlayWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(OverlayWidget) catch unreachable;
    ret.* = OverlayWidget.init(src, id_extra, opts);
    ret.install();
    return ret;
}

pub const OverlayWidget = struct {
    const Self = @This();
    wd: WidgetData = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) Self {
        return Self{ .wd = WidgetData.init(src, id_extra, opts) };
    }

    pub fn install(self: *Self) void {
        _ = parentSet(self.widget());
        debug("{x} Overlay {}", .{ self.wd.id, self.wd.rect });
        self.wd.borderAndBackground();
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect(), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, rect: Rect) RectScale {
        return self.wd.parent.screenRectScale(rect);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub const Direction = enum {
    horizontal,
    vertical,
};

pub fn box(src: std.builtin.SourceLocation, id_extra: usize, dir: Direction, opts: Options) *BoxWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(BoxWidget) catch unreachable;
    ret.* = BoxWidget.init(src, id_extra, dir, opts);
    ret.install();
    return ret;
}

pub const BoxWidget = struct {
    const Self = @This();

    const Data = struct {
        total_weight_prev: ?f32 = null,
        space_taken_prev: ?f32 = null,
    };

    wd: WidgetData = undefined,
    dir: Direction = undefined,
    max_thick: f32 = 0,
    data_prev: Data = Data{},
    space_taken: f32 = 0,
    total_weight: f32 = 0,
    childRect: Rect = Rect{},
    extra_pixels: f32 = 0,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, dir: Direction, opts: Options) BoxWidget {
        var self = Self{};
        self.wd = WidgetData.init(src, id_extra, opts);
        self.dir = dir;
        if (dataGet(self.wd.id, "_data", Data)) |d| {
            self.data_prev = d;
        }
        return self;
    }

    pub fn install(self: *Self) void {
        _ = parentSet(self.widget());
        debug("{x} Box {}", .{ self.wd.id, self.wd.rect });
        self.wd.borderAndBackground();

        // our rect for children has to start at 0,0
        self.childRect = self.wd.contentRect();
        self.childRect.x = 0;
        self.childRect.y = 0;

        if (self.data_prev.space_taken_prev) |taken_prev| {
            if (self.dir == .horizontal) {
                self.extra_pixels = math.max(0, self.childRect.w - taken_prev);
            } else {
                self.extra_pixels = math.max(0, self.childRect.h - taken_prev);
            }
        }
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        var current_weight: f32 = 0.0;
        if ((self.dir == .horizontal and e.horizontal()) or (self.dir == .vertical and e.vertical())) {
            current_weight = 1.0;
        }
        self.total_weight += current_weight;

        var pixels_per_w: f32 = 0;
        if (self.data_prev.total_weight_prev) |w| {
            if (w > 0) {
                pixels_per_w = self.extra_pixels / w;
            }
        }

        var child_size = minSize(id, min_size);

        var rect = self.childRect;
        rect.w = math.min(rect.w, child_size.w);
        rect.h = math.min(rect.h, child_size.h);

        if (self.dir == .horizontal) {
            rect.h = self.childRect.h;
            rect.w += pixels_per_w * current_weight;

            self.childRect.w = math.max(0, self.childRect.w - rect.w);
            self.childRect.x += rect.w;
        } else if (self.dir == .vertical) {
            rect.w = self.childRect.w;
            rect.h += pixels_per_w * current_weight;

            self.childRect.h = math.max(0, self.childRect.h - rect.h);
            self.childRect.y += rect.h;
        }

        return placeIn(null, rect, child_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        if (self.dir == .horizontal) {
            self.space_taken += s.w;
            self.max_thick = math.max(self.max_thick, s.h);
        } else {
            self.space_taken += s.h;
            self.max_thick = math.max(self.max_thick, s.w);
        }
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        const screenRS = self.wd.contentRectScale();
        const scaled = r.scale(screenRS.s);
        return RectScale{ .r = scaled.offset(screenRS.r), .s = screenRS.s };
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        var ms: Size = undefined;
        if (self.dir == .horizontal) {
            ms.w = self.space_taken;
            ms.h = self.max_thick;
        } else {
            ms.h = self.space_taken;
            ms.w = self.max_thick;
        }

        self.wd.minSizeMax(self.wd.padSize(ms));
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();

        dataSet(self.wd.id, "_data", Data{ .total_weight_prev = self.total_weight, .space_taken_prev = self.space_taken });

        _ = parentSet(self.wd.parent);
    }
};

pub const ScrollBar = struct {
    const Self = @This();
    const thick = 10;
    id: u32,
    parent: Widget,
    rect: Rect = Rect{},
    grabRect: Rect = Rect{},
    area: *ScrollAreaWidget,
    highlight: bool = false,

    pub fn run(src: std.builtin.SourceLocation, id_extra: usize, area: *ScrollAreaWidget, rect_in: Rect, opts: Options) void {
        const parent = parentGet();
        var self = Self{ .id = parent.extendID(src, id_extra), .parent = parent, .area = area };

        const captured = captureMouseMaintain(self.id);

        self.rect = rect_in;
        debug("{x} ScrollBar {}", .{ self.id, self.rect });
        {
            const si = area.scrollInfo();
            self.grabRect = self.rect;
            self.grabRect.h = math.max(20, self.rect.h * si.fraction_visible);
            const insideH = self.rect.h - self.grabRect.h;
            self.grabRect.y += insideH * si.scroll_fraction;

            const grabrs = self.parent.screenRectScale(self.grabRect);
            self.processEvents(grabrs.r);
        }

        // processEvents could have changed scroll so recalc before render
        {
            const si = area.scrollInfo();
            self.grabRect = self.rect;
            self.grabRect.h = math.max(20, self.rect.h * si.fraction_visible);
            const insideH = self.rect.h - self.grabRect.h;
            self.grabRect.y += insideH * si.scroll_fraction;
        }

        //const rs = self.parent.screenRectScale(self.rect);
        //PathAddRect(rs.r, Rect.all(0));
        //var fill_color = Color{.r = 0, .g = 0, .b = 0, .a = 50};
        //PathFillConvex(fill_color);

        //fill_color = Color{.r = 100, .g = 100, .b = 100, .a = 255};
        var fill = opts.color().transparent(0.5);
        if (captured or self.highlight) {
            fill = opts.color().transparent(0.3);
        }
        self.grabRect = self.grabRect.insetAll(2);
        const grabrs = self.parent.screenRectScale(self.grabRect);
        pathAddRect(grabrs.r, Rect.all(grabrs.r.w));
        pathFillConvex(fill);
    }

    pub fn processEvents(self: *Self, grabrs: Rect) void {
        const rs = self.parent.screenRectScale(self.rect);
        var iter = EventIterator.init(self.id, rs.r);
        while (iter.next()) |e| {
            if (e.evt == .mouse) {
                if (e.evt.mouse.state == .leftdown) {
                    e.handled = true;
                    if (grabrs.contains(e.evt.mouse.p)) {
                        // capture and start drag
                        captureMouse(self.id);
                        dragPreStart(e.evt.mouse.p, .arrow, .{ .x = 0, .y = e.evt.mouse.p.y - (grabrs.y + grabrs.h / 2) });
                    } else {
                        const si = self.area.scrollInfo();
                        var fi = si.fraction_visible;
                        // the last page is scroll fraction 1.0, so there is
                        // one less scroll position between 0 and 1.0
                        fi = 1.0 / ((1.0 / fi) - 1);
                        var f: f32 = undefined;
                        if (e.evt.mouse.p.y < grabrs.y) {
                            // clicked above grab
                            f = si.scroll_fraction - fi;
                        } else {
                            // clicked below grab
                            f = si.scroll_fraction + fi;
                        }
                        self.area.scrollToFraction(f);
                    }
                } else if (e.evt.mouse.state == .leftup) {
                    e.handled = true;
                    // stop possible drag and capture
                    captureMouse(null);
                    dragEnd();
                } else if (e.evt.mouse.state == .motion) {
                    e.handled = true;
                    // move if dragging
                    if (dragging(e.evt.mouse.p)) |dps| {
                        _ = dps;
                        const min = rs.r.y + grabrs.h / 2;
                        const max = rs.r.y + rs.r.h - grabrs.h / 2;
                        var grabmid = e.evt.mouse.p.y - dragOffset().y;
                        var f: f32 = 0;
                        if (max > min) {
                            f = (grabmid - min) / (max - min);
                        }
                        self.area.scrollToFraction(f);
                    }
                } else if (e.evt.mouse.state == .position) {
                    e.handled = true;
                    self.highlight = true;
                }
            }
        }
    }
};

pub fn scrollArea(src: std.builtin.SourceLocation, id_extra: usize, virtual_size: ?Size, opts: Options) *ScrollAreaWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(ScrollAreaWidget) catch unreachable;
    ret.* = ScrollAreaWidget.init(src, id_extra, virtual_size, opts);
    ret.widget().processEvents();
    ret.install();
    return ret;
}

pub const ScrollAreaWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .background = true,
        // generally the top of a scroll area is against something flat (like
        // window header), and the bottom is against something curved (bottom
        // of a window)
        .corner_radius = Rect{ .x = 0, .y = 0, .w = 5, .h = 5 },
        .color_style = .content,
        .min_size = .{ .w = 0, .h = 100 },
    };

    const grab_thick = 10;
    const ScrollInfo = struct {
        fraction_visible: f32,
        scroll_fraction: f32,
    };

    const Data = struct {
        scroll: f32,
        virtualSize: Size,
    };

    wd: WidgetData = undefined,

    prevClip: Rect = Rect{},
    virtualSize: Size = Size{},
    nextVirtualSize: Size = Size{},
    next_widget_ypos: f32 = 0, // goes from 0 to viritualSize.h
    scroll: f32 = 0, // how far down we are scrolled (natural scale pixels)
    scrollAfter: f32 = 0, // how far we need to scroll after this frame

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, virtual_size: ?Size, opts: Options) Self {
        var self = Self{};
        const options = defaults.override(opts);
        self.wd = WidgetData.init(src, id_extra, options);
        if (virtual_size) |vs| {
            self.virtualSize = vs;
        }

        if (dataGet(self.wd.id, "_data", Data)) |d| {
            if (virtual_size == null) {
                self.virtualSize = d.virtualSize;
            }
            self.scroll = d.scroll;
        }

        const max_scroll = math.max(0, self.virtualSize.h - self.wd.contentRect().h);
        if (self.scroll < 0) {
            self.scroll = math.min(0, math.max(-20 * self.wd.scale(), self.scroll + 250 * animationRate()));
            if (self.scroll < 0) {
                cueFrame();
            }
        } else if (self.scroll > max_scroll) {
            self.scroll = math.max(max_scroll, math.min(max_scroll + 20 * self.wd.scale(), self.scroll - 250 * animationRate()));
            if (self.scroll > max_scroll) {
                cueFrame();
            }
        }

        self.next_widget_ypos = 0;
        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} ScrollArea {}", .{ self.wd.id, self.wd.rect });
        self.wd.borderAndBackground();

        self.prevClip = clip(self.wd.contentRectScale().r);

        var rect = self.wd.contentRect();
        if (rect.w >= grab_thick) {
            rect.x += rect.w - grab_thick;
            rect.w = grab_thick;
        }
        ScrollBar.run(@src(), 0, self, rect, self.wd.options);

        _ = parentSet(self.widget());
    }

    pub fn scrollInfo(self: *Self) ScrollInfo {
        const rect = self.wd.contentRect();
        if (rect.h == 0) {
            return ScrollInfo{ .fraction_visible = 0, .scroll_fraction = 0 };
        }
        const max_hard_scroll = math.max(0, self.virtualSize.h - rect.h);
        var length = math.max(rect.h, self.virtualSize.h);
        if (self.scroll < 0) {
            // temporarily adding the dead space we are showing
            length += -self.scroll;
        } else if (self.scroll > max_hard_scroll) {
            length += (self.scroll - max_hard_scroll);
        }
        const fraction_visible = rect.h / length; // <= 1

        const max_scroll = math.max(0, length - rect.h);
        var scroll_fraction: f32 = 0;
        if (max_scroll != 0) {
            scroll_fraction = math.max(0, self.scroll / max_scroll);
        }

        return ScrollInfo{ .fraction_visible = fraction_visible, .scroll_fraction = scroll_fraction };
    }

    // rect in virtual coords that is being shown
    pub fn visibleRect(self: *const Self) Rect {
        var ret = Rect{};
        ret.x = 0;
        ret.w = math.max(0, self.wd.contentRect().w - grab_thick);
        ret.y = self.scroll;
        ret.h = self.wd.contentRect().h;
        return ret;
    }

    pub fn scrollToFraction(self: *Self, fin: f32) void {
        const f = math.max(0, math.min(1, fin));
        const max_hard_scroll = math.max(0, self.virtualSize.h - self.wd.contentRect().h);
        self.scroll = f * max_hard_scroll;
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        var child_size = minSize(id, min_size);

        const y = self.next_widget_ypos;
        const h = self.virtualSize.h - self.next_widget_ypos;
        const rect = Rect{ .x = 0, .y = y, .w = math.max(0, self.wd.contentRect().w - grab_thick), .h = math.min(h, child_size.h) };
        const ret = placeIn(id, rect, child_size, e, g);
        self.next_widget_ypos = (ret.y + ret.h);
        return ret;
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.nextVirtualSize.h += s.h;
        const padded = self.wd.padSize(s);
        self.wd.min_size.w = math.max(self.wd.min_size.w, padded.w + grab_thick);
    }

    pub fn screenRectScale(self: *Self, rect: Rect) RectScale {
        var r = rect;
        r.x += self.wd.contentRect().x;
        r.y += self.wd.contentRect().y - self.scroll;
        return self.wd.parent.screenRectScale(r);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        // scroll area does event processing after children
        _ = iter;

        if (bubbleable(e)) {
            self.bubbleEvent(e);
        }
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        switch (e.evt) {
            .key => {
                if (e.evt.key.keysym == .up and
                    (e.evt.key.state == .down or e.evt.key.state == .repeat))
                {
                    e.handled = true;
                    self.scrollAfter -= 10;
                    if (self.scroll + self.scrollAfter < 0) {
                        self.scrollAfter = math.min(0, -self.scroll);
                    }
                } else if (e.evt.key.keysym == .down and
                    (e.evt.key.state == .down or e.evt.key.state == .repeat))
                {
                    e.handled = true;
                    self.scrollAfter += 10;
                    const max_scroll = math.max(0, self.virtualSize.h - self.wd.contentRect().h);
                    if (self.scroll + self.scrollAfter > max_scroll) {
                        self.scrollAfter = math.max(0, max_scroll - self.scroll);
                    }
                }
            },
            else => {},
        }

        if (!e.handled) {
            self.wd.parent.bubbleEvent(e);
        }
    }

    pub fn processEventsAfter(self: *Self) void {
        const rs = self.wd.borderRectScale();
        var iter = EventIterator.init(self.wd.id, rs.r);
        while (iter.next()) |e| {
            switch (e.evt) {
                .mouse => {
                    if (e.evt.mouse.state == .focus) {
                        e.handled = true;
                        // focus so that we can receive keyboard input
                        focusWidget(self.wd.id, &iter);
                    } else if (e.evt.mouse.state == .wheel_y) {
                        e.handled = true;
                        self.scrollAfter -= e.evt.mouse.wheel * rs.s;
                    }
                },
                else => {},
            }
        }
    }

    pub fn deinit(self: *Self) void {
        self.processEventsAfter();

        clipSet(self.prevClip);

        var scroll = self.scroll;
        //std.debug.print("scroll {d} scrollAfter {d}\n", .{scroll, self.scrollAfter});
        if (self.scrollAfter != 0) {
            scroll += self.scrollAfter;
            cueFrame();
        }

        const d = Data{ .virtualSize = self.nextVirtualSize, .scroll = scroll };
        dataSet(self.wd.id, "_data", d);

        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub var separator_defaults: Options = .{
    .min_size = .{ .w = 1, .h = 1 },
    .border = .{ .x = 1, .y = 1, .w = 0, .h = 0 },
    .color_style = .content,
};

pub fn separator(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) void {
    var wd = WidgetData.init(src, id_extra, separator_defaults.override(opts));
    debug("{x} Separator {}", .{ wd.id, wd.rect });
    wd.borderAndBackground();
    wd.minSizeSetAndCue();
    wd.minSizeReportToParent();
}

pub fn spacer(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) WidgetData {
    var wd = WidgetData.init(src, id_extra, opts);
    debug("{x} Spacer {}", .{ wd.id, wd.rect });
    wd.minSizeSetAndCue();
    wd.minSizeReportToParent();
    return wd;
}

pub fn spinner(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) void {
    var defaults: Options = .{
        .min_size = .{ .w = 50, .h = 50 },
    };
    const options = defaults.override(opts);
    var wd = WidgetData.init(src, id_extra, options);
    debug("{x} Spinner {}", .{ wd.id, wd.rect });
    wd.minSizeSetAndCue();
    wd.minSizeReportToParent();

    if (wd.rect.empty()) {
        return;
    }

    const rs = wd.contentRectScale();
    const r = rs.r;

    var angle: f32 = 0;
    var anim = Animation{ .start_val = 0, .end_val = 2 * math.pi, .start_time = 0, .end_time = 4_500_000 };
    if (animationGet(wd.id, "_angle")) |a| {
        // existing animation
        var aa = a;
        if (aa.end_time <= 0) {
            // this animation is expired, seemlessly transition to next animation
            aa = anim;
            aa.start_time = a.end_time;
            aa.end_time += a.end_time;
            animate(wd.id, "_angle", aa);
        }
        angle = aa.lerp();
    } else {
        // first frame we are seeing the spinner
        animate(wd.id, "_angle", anim);
    }

    const center = Point{ .x = r.x + r.w / 2, .y = r.y + r.h / 2 };
    pathAddArc(center, math.min(r.w, r.h) / 3, angle, 0, false);
    //PathAddPoint(center);
    //PathFillConvex(options.color());
    pathStroke(false, 3.0 * rs.s, .none, options.color());
}

pub fn scale(src: std.builtin.SourceLocation, id_extra: usize, scale_in: f32, opts: Options) *ScaleWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(ScaleWidget) catch unreachable;
    ret.* = ScaleWidget.init(src, id_extra, scale_in, opts);
    ret.install();
    return ret;
}

pub const ScaleWidget = struct {
    const Self = @This();
    wd: WidgetData = undefined,
    scale_in: f32 = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, scale_in: f32, opts: Options) Self {
        var self = Self{};
        self.wd = WidgetData.init(src, id_extra, opts);
        self.scale_in = scale_in;
        return self;
    }

    pub fn install(self: *Self) void {
        _ = parentSet(self.widget());
        debug("{x} Scale {d} {}", .{ self.wd.id, self.scale_in, self.wd.rect });
        self.wd.borderAndBackground();
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect().justSize().scale(1.0 / self.scale_in), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s.scale(self.scale_in)));
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        const screenRS = self.wd.contentRectScale();
        const s = screenRS.s * self.scale_in;
        const scaled = r.scale(s);
        return RectScale{ .r = scaled.offset(screenRS.r), .s = s };
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub fn menu(src: std.builtin.SourceLocation, id_extra: usize, dir: Direction, opts: Options) *MenuWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(MenuWidget) catch unreachable;
    ret.* = MenuWidget.init(src, id_extra, dir, opts);
    ret.install();
    return ret;
}

pub const MenuWidget = struct {
    const Self = @This();

    wd: WidgetData = undefined,

    winId: u32 = undefined,
    dir: Direction = undefined,
    parentMenu: ?*MenuWidget = null,
    box: BoxWidget = undefined,

    submenus_activated: bool = false,
    // each MenuItemWidget child will set this if it has focus, so that we will
    // automatically turn it off if none of our children have focus
    submenus_activated_next_frame: bool = false,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, dir: Direction, opts: Options) MenuWidget {
        var self = Self{};
        self.wd = WidgetData.init(src, id_extra, opts);

        self.winId = windowCurrentId();
        self.dir = dir;
        if (dataGet(self.wd.id, "_sub_act", bool)) |a| {
            self.submenus_activated = a;
            //std.debug.print("menu dataGet {x} {}\n", .{self.wd.id, self.submenus_activated});
        } else if (menuGet()) |m| {
            self.submenus_activated = m.submenus_activated;
            //std.debug.print("menu menuGet {x} {}\n", .{self.wd.id, self.submenus_activated});
        }

        return self;
    }

    pub fn install(self: *Self) void {
        _ = parentSet(self.widget());
        self.parentMenu = menuSet(self);
        debug("{x} Menu {}", .{ self.wd.id, self.wd.rect });

        self.wd.borderAndBackground();

        self.box = BoxWidget.init(@src(), 0, self.dir, self.wd.options.strip());
        self.box.install();
    }

    pub fn close(self: *Self) void {
        // bubble this event to close all popups that had submenus leading to this
        var e = Event{ .evt = AnyEvent{ .close_popup = ClosePopupEvent{} } };
        self.bubbleEvent(&e);
        cueFrame();
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect(), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, rect: Rect) RectScale {
        return self.wd.parent.screenRectScale(rect);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        _ = self;
        _ = iter;
        _ = e;
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        switch (e.evt) {
            .close_popup => {
                self.submenus_activated = false;
            },
            else => {},
        }

        if (!e.handled) {
            self.wd.parent.bubbleEvent(e);
        }
    }

    pub fn deinit(self: *Self) void {
        self.box.deinit();
        if (self.submenus_activated_next_frame) {
            dataSet(self.wd.id, "_sub_act", self.submenus_activated);
        }
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = menuSet(self.parentMenu);
        _ = parentSet(self.wd.parent);
    }
};

pub var menuItemLabel_defaults: Options = .{
    .color_style = .content,
};

pub fn menuItemLabel(src: std.builtin.SourceLocation, id_extra: usize, label_str: []const u8, submenu: bool, opts: Options) ?Rect {
    const options = menuItemLabel_defaults.override(opts);
    var mi = menuItem(src, id_extra, submenu, options);

    var labelopts = options.strip();

    var ret: ?Rect = null;
    if (mi.activeRect()) |r| {
        ret = r;
    }

    var focused: bool = false;
    if (mi.wd.id == focusedWidgetId()) {
        focused = true;
    }

    if (mi.show_active) {
        labelopts = labelopts.override(.{ .color_style = .accent });
    }

    labelNoFormat(@src(), 0, label_str, labelopts);

    mi.deinit();

    return ret;
}

pub fn menuItemIcon(src: std.builtin.SourceLocation, id_extra: usize, submenu: bool, height: f32, name: []const u8, tvg_bytes: []const u8, opts: Options) ?Rect {
    const options = menuItemLabel_defaults.override(opts);
    var mi = menuItem(src, id_extra, submenu, options);

    var iconopts = options.strip();

    var ret: ?Rect = null;
    if (mi.activeRect()) |r| {
        ret = r;
    }

    var focused: bool = false;
    if (mi.wd.id == focusedWidgetId()) {
        focused = true;
    }

    if (mi.show_active) {
        iconopts = iconopts.override(.{ .color_style = .accent });
    }

    icon(@src(), 0, height, name, tvg_bytes, iconopts);

    mi.deinit();

    return ret;
}

pub fn menuItem(src: std.builtin.SourceLocation, id_extra: usize, submenu: bool, opts: Options) *MenuItemWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(MenuItemWidget) catch unreachable;
    ret.* = MenuItemWidget.init(src, id_extra, submenu, opts);
    ret.widget().processEvents();
    ret.install();
    return ret;
}

pub const MenuItemWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .corner_radius = Rect.all(5),
        .padding = Rect.all(4),
    };

    wd: WidgetData = undefined,
    focused_in_win: bool = false,
    highlight: bool = false,
    submenu: bool = false,
    activated: bool = false,
    show_active: bool = false,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, submenu: bool, opts: Options) Self {
        var self = Self{};
        const options = defaults.override(opts);
        self.wd = WidgetData.init(src, id_extra, options);
        self.submenu = submenu;
        if (self.wd.visible()) {
            tabIndexSet(self.wd.id, options.tab_index);
        }
        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} MenuItem {}", .{ self.wd.id, self.wd.rect });

        if (self.wd.id == focusedWidgetIdInCurrentWindow()) {
            self.focused_in_win = true;
            menuGet().?.submenus_activated_next_frame = true;
        }

        if (self.wd.options.borderGet().nonZero()) {
            const rs = self.wd.borderRectScale();
            pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
            var col = Color.lerp(self.wd.options.color_bg(), 0.3, self.wd.options.color());
            pathFillConvex(col);
        }

        var focused: bool = false;
        if (self.wd.id == focusedWidgetId()) {
            focused = true;
        }

        if (focused or (self.focused_in_win and self.highlight)) {
            if (!self.submenu or !menuGet().?.submenus_activated) {
                self.show_active = true;
            }
        }

        if (self.show_active) {
            const fill = themeGet().color_accent_bg;
            const rs = self.wd.backgroundRectScale();
            pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
            pathFillConvex(fill);
        } else if (self.focused_in_win or self.highlight) {
            // hovered
            const fill = Color.lerp(self.wd.options.color_bg(), 0.1, self.wd.options.color());
            const rs = self.wd.backgroundRectScale();
            pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
            pathFillConvex(fill);
        } else if (self.wd.options.background orelse false) {
            const fill = self.wd.options.color_bg();
            const rs = self.wd.backgroundRectScale();
            pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
            pathFillConvex(fill);
        }

        _ = parentSet(self.widget());
    }

    pub fn activeRect(self: *const Self) ?Rect {
        var act = false;
        if (self.submenu) {
            if (menuGet().?.submenus_activated and self.focused_in_win) {
                act = true;
            }
        } else if (self.activated) {
            act = true;
        }

        if (act) {
            const rs = self.wd.borderRectScale();
            return rs.r.scale(1 / windowNaturalScale());
        } else {
            return null;
        }
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect(), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, rect: Rect) RectScale {
        return self.wd.parent.screenRectScale(rect);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        switch (e.evt) {
            .mouse => {
                if (e.evt.mouse.state == .focus) {
                    e.handled = true;
                } else if (e.evt.mouse.state == .leftdown) {
                    e.handled = true;
                    if (self.submenu) {
                        focusWindow(null, null); // focuses the window we are in
                        focusWidget(self.wd.id, iter);
                        menuGet().?.submenus_activated = !menuGet().?.submenus_activated;
                    }
                } else if (e.evt.mouse.state == .leftup) {
                    e.handled = true;
                    if (!self.submenu) {
                        self.activated = true;
                    }
                } else if (e.evt.mouse.state == .position) {
                    e.handled = true;
                    self.highlight = true;

                    // We get a .position mouse event every frame.  If we
                    // focus the menu item under the mouse even if it's not
                    // moving then it breaks keyboard navigation.
                    if (mouseTotalMotion().nonZero()) {
                        // TODO don't do the rest here if the menu has an existing popup and the motion is towards the popup
                        focusWindow(null, null); // focuses the window we are in
                        focusWidget(self.wd.id, null);
                    }
                }
            },
            .key => {
                if (e.evt.key.state == .down and e.evt.key.keysym == .space) {
                    e.handled = true;
                    if (self.submenu) {
                        menuGet().?.submenus_activated = true;
                    } else {
                        self.activated = true;
                    }
                } else if (e.evt.key.state == .down and e.evt.key.keysym == .right) {
                    e.handled = true;
                    if (self.submenu) {
                        menuGet().?.submenus_activated = true;
                    }
                }
            },
            else => {},
        }

        if (bubbleable(e)) {
            self.bubbleEvent(e);
        }
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub const LabelWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .padding = Rect.all(4),
        .color_style = .control,
        .background = false,
    };

    wd: WidgetData = undefined,
    label_str: []const u8 = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, comptime fmt: []const u8, args: anytype, opts: Options) Self {
        var cw = current_window orelse unreachable;
        const l = std.fmt.allocPrint(cw.arena, fmt, args) catch unreachable;
        return Self.initNoFormat(src, id_extra, l, opts);
    }

    pub fn initNoFormat(src: std.builtin.SourceLocation, id_extra: usize, label_str: []const u8, opts: Options) Self {
        var self = Self{};
        const options = defaults.override(opts);
        self.label_str = label_str;
        const size = options.font().textSize(self.label_str);
        self.wd = WidgetData.init(src, id_extra, options.overrideMinSizeContent(size));
        self.wd.placeInsideNoExpand();
        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} Label \"{s:<10}\" {}", .{ self.wd.id, self.label_str, self.wd.rect });
        self.wd.borderAndBackground();
        const rs = self.wd.contentRectScale();

        const oldclip = clip(rs.r);
        if (!clipGet().empty()) {
            renderText(self.wd.options.font(), self.label_str, rs, self.wd.options.color());
        }
        clipSet(oldclip);

        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
    }
};

pub fn label(src: std.builtin.SourceLocation, id_extra: usize, comptime fmt: []const u8, args: anytype, opts: Options) void {
    var lw = LabelWidget.init(src, id_extra, fmt, args, opts);
    lw.install();
}

pub fn labelNoFormat(src: std.builtin.SourceLocation, id_extra: usize, str: []const u8, opts: Options) void {
    var lw = LabelWidget.initNoFormat(src, id_extra, str, opts);
    lw.install();
}

pub fn icon(src: std.builtin.SourceLocation, id_extra: usize, height: f32, name: []const u8, tvg_bytes: []const u8, opts: Options) void {
    const size = Size{ .w = iconWidth(name, tvg_bytes, height), .h = height };

    var wd = WidgetData.init(src, id_extra, opts.overrideMinSizeContent(size));
    debug("{x} Icon \"{s:<10}\" {}", .{ wd.id, name, wd.rect });

    wd.placeInsideNoExpand();
    wd.borderAndBackground();

    const rs = wd.contentRectScale();
    renderIcon(name, tvg_bytes, rs, opts.color());

    wd.minSizeSetAndCue();
    wd.minSizeReportToParent();
}

pub fn debugFontAtlases(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) void {
    const cw = current_window orelse unreachable;

    var size = Size{};
    var it = cw.font_cache.iterator();
    while (it.next()) |kv| {
        size.w = math.max(size.w, kv.value_ptr.texture_atlas_size.w);
        size.h += kv.value_ptr.texture_atlas_size.h;
    }

    // this size is a pixel size, so inverse scale to get natural pixels
    const ss = parentGet().screenRectScale(Rect{}).s;
    size = size.scale(1.0 / ss);

    var wd = WidgetData.init(src, id_extra, opts.overrideMinSizeContent(size));
    debug("{x} debugFontAtlases {} {}", .{ wd.id, wd.rect, opts.color() });

    wd.placeInsideNoExpand();
    wd.borderAndBackground();

    const rs = wd.contentRectScale();
    debugRenderFontAtlases(rs, opts.color());

    wd.minSizeSetAndCue();
    wd.minSizeReportToParent();
}

pub fn buttonContainer(src: std.builtin.SourceLocation, id_extra: usize, show_focus: bool, opts: Options) *ButtonContainerWidget {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(ButtonContainerWidget) catch unreachable;
    ret.* = ButtonContainerWidget.init(src, id_extra, show_focus, opts);
    ret.widget().processEvents();
    ret.install();
    return ret;
}

pub const ButtonContainerWidget = struct {
    const Self = @This();
    wd: WidgetData = undefined,
    highlight: bool = false,
    captured: bool = false,
    focused: bool = false,
    show_focus: bool = false,
    clicked: bool = false,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, show_focus: bool, opts: Options) Self {
        var self = Self{};
        self.wd = WidgetData.init(src, id_extra, opts);
        self.captured = captureMouseMaintain(self.wd.id);
        if (self.wd.visible()) {
            tabIndexSet(self.wd.id, opts.tab_index);
        }
        self.show_focus = show_focus;
        return self;
    }

    pub fn install(self: *Self) void {
        self.focused = (self.wd.id == focusedWidgetId());

        if (self.wd.options.borderGet().nonZero()) {
            const rs = self.wd.borderRectScale();
            pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
            var col = Color.lerp(self.wd.options.color_bg(), 0.3, self.wd.options.color());
            pathFillConvex(col);
        }

        if (self.wd.options.background orelse false) {
            const rs = self.wd.backgroundRectScale();
            var fill: Color = undefined;
            if (self.captured) {
                // pressed
                fill = Color.lerp(self.wd.options.color_bg(), 0.2, self.wd.options.color());
            } else if (self.highlight) {
                // hovered
                fill = Color.lerp(self.wd.options.color_bg(), 0.1, self.wd.options.color());
            } else {
                fill = self.wd.options.color_bg();
            }

            pathAddRect(rs.r, self.wd.options.corner_radiusGet().scale(rs.s));
            pathFillConvex(fill);
        }

        if (self.focused and self.show_focus) {
            self.wd.focusBorder();
        }

        _ = parentSet(self.widget());
        debug("{x} ButtonContainer {}", .{ self.wd.id, self.wd.rect });
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect(), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        return self.wd.parent.screenRectScale(r);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        switch (e.evt) {
            .mouse => {
                if (e.evt.mouse.state == .focus) {
                    e.handled = true;
                    focusWidget(self.wd.id, iter);
                } else if (e.evt.mouse.state == .leftdown) {
                    e.handled = true;
                    captureMouse(self.wd.id);
                    self.captured = true;
                } else if (e.evt.mouse.state == .leftup) {
                    e.handled = true;
                    if (self.captured) {
                        captureMouse(null);
                        self.captured = false;
                        if (iter.r.contains(e.evt.mouse.p)) {
                            self.clicked = true;
                            cueFrame();
                        }
                    }
                } else if (e.evt.mouse.state == .position) {
                    e.handled = true;
                    self.highlight = true;
                }
            },
            .key => {
                if (e.evt.key.state == .down and e.evt.key.keysym == .space) {
                    e.handled = true;
                    self.clicked = true;
                    cueFrame();
                }
            },
            else => {},
        }

        if (bubbleable(e)) {
            self.bubbleEvent(e);
        }
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);
    }
};

pub const ButtonWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .margin = Rect.all(4),
        .corner_radius = Rect.all(5),
        .padding = Rect.all(4),
        .background = true,
        .color_style = .control,
    };

    bc: ButtonContainerWidget = undefined,
    label_str: []const u8 = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, str: []const u8, opts: Options) Self {
        return Self{
            .bc = ButtonContainerWidget.init(src, id_extra, true, defaults.override(opts)),
            .label_str = str,
        };
    }

    pub fn show(self: *ButtonWidget) bool {
        debug("Button {s}", .{self.label_str});
        self.bc.widget().processEvents();
        self.bc.install();
        const clicked = self.bc.clicked;

        labelNoFormat(@src(), 0, self.label_str, self.bc.wd.options.strip().override(.{ .gravity = .center }));

        self.bc.deinit();
        return clicked;
    }
};

pub fn button(src: std.builtin.SourceLocation, id_extra: usize, label_str: []const u8, opts: Options) bool {
    var bw = ButtonWidget.init(src, id_extra, label_str, opts);
    return bw.show();
}

pub var buttonIcon_defaults: Options = .{
    .margin = gui.Rect.all(4),
    .corner_radius = Rect.all(5),
    .padding = Rect.all(4),
    .background = true,
    .color_style = .control,
    .gravity = .center,
};

pub fn buttonIcon(src: std.builtin.SourceLocation, id_extra: usize, height: f32, name: []const u8, tvg_bytes: []const u8, opts: Options) bool {
    const options = buttonIcon_defaults.override(opts);
    debug("ButtonIcon \"{s}\" {}", .{ name, options });
    var bc = buttonContainer(src, id_extra, true, options);
    defer bc.deinit();

    icon(@src(), 0, height, name, tvg_bytes, options.strip());

    return bc.clicked;
}

pub var checkbox_defaults: Options = .{
    .margin = .{ .x = 2, .y = 0, .w = 2, .h = 0 },
    .corner_radius = gui.Rect.all(2),
    .padding = Rect.all(2),
    .color_style = .content,
};

pub fn checkbox(src: std.builtin.SourceLocation, id_extra: usize, target: *bool, label_str: []const u8, opts: Options) void {
    const options = checkbox_defaults.override(opts);
    debug("Checkbox {s}", .{label_str});
    var bc = buttonContainer(src, id_extra, false, options.override(.{ .background = false }));
    defer bc.deinit();

    if (bc.clicked) {
        target.* = !target.*;
    }

    var b = box(@src(), 0, .horizontal, options.strip().override(.{ .expand = .both }));
    defer b.deinit();

    var check_size = options.font().lineSkip();
    const s = spacer(@src(), 0, .{ .min_size = Size.all(check_size), .gravity = .left });

    var rs = s.borderRectScale();
    rs.r = rs.r.insetAll(0.5 * rs.s);

    pathAddRect(rs.r, options.corner_radiusGet().scale(rs.s));
    var col = Color.lerp(options.color_bg(), 0.3, options.color());
    pathFillConvex(col);

    if (bc.focused) {
        pathAddRect(rs.r, options.corner_radiusGet().scale(rs.s));
        pathStroke(true, 2 * rs.s, .none, themeGet().color_accent_bg);
    }

    var fill = options.color_bg();
    if (target.*) {
        fill = themeGet().color_accent_bg;
        pathAddRect(rs.r.insetAll(0.5 * rs.s), options.corner_radiusGet().scale(rs.s));
    } else {
        pathAddRect(rs.r.insetAll(rs.s), options.corner_radiusGet().scale(rs.s));
    }

    if (bc.captured) {
        // pressed
        fill = Color.lerp(fill, 0.2, options.color());
    } else if (bc.highlight) {
        // hovered
        fill = Color.lerp(fill, 0.1, options.color());
    }

    pathFillConvex(fill);

    if (target.*) {
        rs.r = rs.r.insetAll(0.5 * rs.s);
        const pad = math.max(1.0, rs.r.w / 6);

        var thick = math.max(1.0, rs.r.w / 5);
        const size = rs.r.w - (thick / 2) - pad * 2;
        const third = size / 3.0;
        const x = rs.r.x + pad + (0.25 * thick) + third;
        const y = rs.r.y + pad + (0.25 * thick) + size - (third * 0.5);

        thick /= 1.5;

        pathAddPoint(Point{ .x = x - third, .y = y - third });
        pathAddPoint(Point{ .x = x, .y = y });
        pathAddPoint(Point{ .x = x + third * 2, .y = y - third * 2 });
        pathStroke(false, thick, .square, themeGet().color_accent);
    }

    _ = spacer(@src(), 0, .{ .min_size = Size.all(1), .gravity = .left });
    labelNoFormat(@src(), 0, label_str, options.styling());
}

pub fn textEntry(src: std.builtin.SourceLocation, id_extra: usize, width: f32, text: []u8, opts: Options) void {
    const cw = current_window orelse unreachable;
    var ret = cw.arena.create(TextEntryWidget) catch unreachable;
    ret.* = TextEntryWidget.init(src, id_extra, width, text, opts);
    ret.allocator = cw.arena;
    ret.widget().processEvents();
    ret.install();
    ret.deinit();
}

pub const TextEntryWidget = struct {
    const Self = @This();
    pub var defaults: Options = .{
        .margin = Rect.all(4),
        .corner_radius = Rect.all(5),
        .border = Rect.all(1),
        .padding = Rect.all(4),
        .background = true,
        .color_style = .content,
    };

    wd: WidgetData = undefined,

    allocator: ?std.mem.Allocator = null,
    captured: bool = false,
    text: []u8 = undefined,
    len: usize = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, width: f32, text: []u8, opts: Options) Self {
        var self = Self{};
        const options = defaults.override(opts);

        const msize = options.font().textSize("M");
        const size = Size{ .w = msize.w * width, .h = msize.h };
        self.wd = WidgetData.init(src, id_extra, options.overrideMinSizeContent(size));

        self.captured = captureMouseMaintain(self.wd.id);

        if (self.wd.visible()) {
            tabIndexSet(self.wd.id, options.tab_index);
        }
        self.text = text;
        self.len = std.mem.indexOfScalar(u8, self.text, 0) orelse self.text.len;
        return self;
    }

    pub fn install(self: *Self) void {
        debug("{x} Text {}", .{ self.wd.id, self.wd.rect });
        self.wd.borderAndBackground();

        const focused = (self.wd.id == focusedWidgetId());

        const rs = self.wd.contentRectScale();

        const oldclip = clip(rs.r);
        if (!clipGet().empty()) {
            renderText(self.wd.options.font(), self.text[0..self.len], rs, self.wd.options.color());
        }
        clipSet(oldclip);

        if (focused) {
            self.wd.focusBorder();
        }

        _ = parentSet(self.widget());
    }

    pub fn widget(self: *Self) Widget {
        return Widget.init(self, data, rectFor, minSizeForChild, screenRectScale, processEvent, bubbleEvent);
    }

    fn data(self: *const Self) *const WidgetData {
        return &self.wd;
    }

    pub fn rectFor(self: *Self, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return placeIn(id, self.wd.contentRect(), min_size, e, g);
    }

    pub fn minSizeForChild(self: *Self, s: Size) void {
        self.wd.minSizeMax(self.wd.padSize(s));
    }

    pub fn screenRectScale(self: *Self, r: Rect) RectScale {
        return self.wd.parent.screenRectScale(r);
    }

    pub fn processEvent(self: *Self, iter: *EventIterator, e: *Event) void {
        switch (e.evt) {
            .key => {
                if (e.evt.key.keysym == .backspace and
                    (e.evt.key.state == .down or e.evt.key.state == .repeat))
                {
                    e.handled = true;
                    self.len -|= 1;
                    self.text[self.len] = 0;
                } else if (e.evt.key.keysym == .v and e.evt.key.state == .down and e.evt.key.mod.gui()) {
                    //e.handled = true;
                    //const ct = c.SDL_GetClipboardText();
                    //defer c.SDL_free(ct);

                    //var i = self.len;
                    //while (i < self.text.len and ct.* != 0) : (i += 1) {
                    //  self.text[i] = ct[i - self.len];
                    //}
                    //self.len = i;
                }
            },
            .text => {
                e.handled = true;
                var new = std.mem.sliceTo(e.evt.text.text, 0);
                new.len = math.min(new.len, self.text.len - self.len);
                std.mem.copy(u8, self.text[self.len..], new);
                self.len += new.len;
            },
            .mouse => {
                if (e.evt.mouse.state == .focus) {
                    e.handled = true;
                    focusWidget(self.wd.id, iter);
                } else if (e.evt.mouse.state == .leftdown) {
                    e.handled = true;
                    captureMouse(self.wd.id);
                    self.captured = true;
                } else if (e.evt.mouse.state == .leftup) {
                    e.handled = true;
                    captureMouse(null);
                    self.captured = false;
                } else if (e.evt.mouse.state == .motion) {}
            },
            else => {},
        }

        if (bubbleable(e)) {
            self.bubbleEvent(e);
        }
    }

    pub fn bubbleEvent(self: *Self, e: *Event) void {
        self.wd.parent.bubbleEvent(e);
    }

    pub fn deinit(self: *Self) void {
        self.wd.minSizeSetAndCue();
        self.wd.minSizeReportToParent();
        _ = parentSet(self.wd.parent);

        if (self.allocator) |a| {
            a.destroy(self);
        }
    }
};

pub const Color = struct {
    r: u8 = 0xff,
    g: u8 = 0xff,
    b: u8 = 0xff,
    a: u8 = 0xff,

    pub fn transparent(x: Color, y: f32) Color {
        return Color{
            .r = x.r,
            .g = x.g,
            .b = x.b,
            .a = @floatToInt(u8, @intToFloat(f32, x.a) * y),
        };
    }

    pub fn darken(x: Color, y: f32) Color {
        return Color{
            .r = @floatToInt(u8, math.max(@intToFloat(f32, x.r) * (1 - y), 0)),
            .g = @floatToInt(u8, math.max(@intToFloat(f32, x.g) * (1 - y), 0)),
            .b = @floatToInt(u8, math.max(@intToFloat(f32, x.b) * (1 - y), 0)),
            .a = x.a,
        };
    }

    pub fn lighten(x: Color, y: f32) Color {
        return Color{
            .r = @floatToInt(u8, math.min(@intToFloat(f32, x.r) * (1 + y), 255)),
            .g = @floatToInt(u8, math.min(@intToFloat(f32, x.g) * (1 + y), 255)),
            .b = @floatToInt(u8, math.min(@intToFloat(f32, x.b) * (1 + y), 255)),
            .a = x.a,
        };
    }

    pub fn lerp(x: Color, y: f32, z: Color) Color {
        return Color{
            .r = @floatToInt(u8, @intToFloat(f32, x.r) * (1 - y) + @intToFloat(f32, z.r) * y),
            .g = @floatToInt(u8, @intToFloat(f32, x.g) * (1 - y) + @intToFloat(f32, z.g) * y),
            .b = @floatToInt(u8, @intToFloat(f32, x.b) * (1 - y) + @intToFloat(f32, z.b) * y),
            .a = @floatToInt(u8, @intToFloat(f32, x.a) * (1 - y) + @intToFloat(f32, z.a) * y),
        };
    }

    pub fn format(self: *const Color, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Color{{ {x} {x} {x} {x} }}", .{ self.r, self.g, self.b, self.a });
    }
};

pub const Point = struct {
    const Self = @This();
    x: f32 = 0,
    y: f32 = 0,

    pub fn nonZero(self: *const Self) bool {
        return (self.x != 0 or self.y != 0);
    }

    pub fn inRectScale(self: *const Self, rs: RectScale) Self {
        return Self{ .x = (self.x - rs.r.x) / rs.s, .y = (self.y - rs.r.y) / rs.s };
    }

    pub fn plus(self: *const Self, b: Self) Self {
        return Self{ .x = self.x + b.x, .y = self.y + b.y };
    }

    pub fn diff(a: Self, b: Self) Self {
        return Self{ .x = a.x - b.x, .y = a.y - b.y };
    }

    pub fn scale(self: *const Self, s: f32) Self {
        return Self{ .x = self.x * s, .y = self.y * s };
    }

    pub fn equals(self: *const Self, b: Self) bool {
        return (self.x == b.x and self.y == b.y);
    }

    pub fn length(self: *const Self) f32 {
        return @sqrt((self.x * self.x) + (self.y * self.y));
    }

    pub fn normalize(self: *const Self) Self {
        const d2 = self.x * self.x + self.y * self.y;
        if (d2 == 0) {
            return Self{ .x = 1.0, .y = 0.0 };
        } else {
            const inv_len = 1.0 / @sqrt(d2);
            return Self{ .x = self.x * inv_len, .y = self.y * inv_len };
        }
    }

    pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Point{{ {d} {d} }}", .{ self.x, self.y });
    }
};

pub const Size = struct {
    const Self = @This();
    w: f32 = 0,
    h: f32 = 0,

    pub fn all(v: f32) Self {
        return Self{ .w = v, .h = v };
    }

    pub fn rect(self: *const Self) Rect {
        return Rect{ .x = 0, .y = 0, .w = self.w, .h = self.h };
    }

    pub fn ceil(self: *const Self) Self {
        return Self{ .w = @ceil(self.w), .h = @ceil(self.h) };
    }

    pub fn pad(s: *const Self, padding: Rect) Self {
        return Size{ .w = s.w + padding.x + padding.w, .h = s.h + padding.y + padding.h };
    }

    pub fn max(a: Self, b: Self) Self {
        return Self{ .w = math.max(a.w, b.w), .h = math.max(a.h, b.h) };
    }

    pub fn scale(self: *const Self, s: f32) Self {
        return Self{ .w = self.w * s, .h = self.h * s };
    }

    pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Size{{ {d} {d} }}", .{ self.w, self.h });
    }
};

pub const Rect = struct {
    const Self = @This();
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,

    pub fn negate(self: *const Self) Rect {
        return Self{ .x = -self.x, .y = -self.y, .w = -self.w, .h = -self.h };
    }

    pub fn add(self: *const Self, r: Self) Rect {
        return Self{ .x = self.x + r.x, .y = self.y + r.y, .w = self.w + r.w, .h = self.h + r.h };
    }

    pub fn nonZero(self: *const Self) bool {
        return (self.x != 0 or self.y != 0 or self.w != 0 or self.h != 0);
    }

    pub fn all(v: f32) Self {
        return Self{ .x = v, .y = v, .w = v, .h = v };
    }

    pub fn fromPoint(p: Point) Self {
        return Self{ .x = p.x, .y = p.y };
    }

    pub fn toSize(self: *const Self, s: Size) Self {
        return Self{ .x = self.x, .y = self.y, .w = s.w, .h = s.h };
    }

    pub fn justSize(self: *const Self) Self {
        return Self{ .x = 0, .y = 0, .w = self.w, .h = self.h };
    }

    pub fn topleft(self: *const Self) Point {
        return Point{ .x = self.x, .y = self.y };
    }

    pub fn bottomRight(self: *const Self) Point {
        return Point{ .x = self.x + self.w, .y = self.y + self.h };
    }

    pub fn size(self: *const Self) Size {
        return Size{ .w = self.w, .h = self.h };
    }

    pub fn contains(self: *const Self, p: Point) bool {
        return (p.x >= self.x and p.x <= (self.x + self.w) and p.y >= self.y and p.y <= (self.y + self.h));
    }

    pub fn empty(self: *const Self) bool {
        return (self.w == 0 or self.h == 0);
    }

    pub fn scale(self: *const Self, s: f32) Self {
        return Self{ .x = self.x * s, .y = self.y * s, .w = self.w * s, .h = self.h * s };
    }

    pub fn offset(self: *const Self, r: Rect) Self {
        return Self{ .x = self.x + r.x, .y = self.y + r.y, .w = self.w, .h = self.h };
    }

    pub fn intersect(a: Self, b: Self) Self {
        const ax2 = a.x + a.w;
        const ay2 = a.y + a.h;
        const bx2 = b.x + b.w;
        const by2 = b.y + b.h;
        const x = math.max(a.x, b.x);
        const y = math.max(a.y, b.y);
        const x2 = math.min(ax2, bx2);
        const y2 = math.min(ay2, by2);
        return Self{ .x = x, .y = y, .w = math.max(0, x2 - x), .h = math.max(0, y2 - y) };
    }

    pub fn shrinkToSize(self: *const Self, s: Size) Self {
        return Self{ .x = self.x, .y = self.y, .w = math.min(self.w, s.w), .h = math.min(self.h, s.h) };
    }

    pub fn inset(self: *const Self, r: Rect) Self {
        return Self{ .x = self.x + r.x, .y = self.y + r.y, .w = math.max(0, self.w - r.x - r.w), .h = math.max(0, self.h - r.y - r.h) };
    }

    pub fn insetAll(self: *const Self, p: f32) Self {
        return self.inset(Rect.all(p));
    }

    pub fn outset(self: *const Self, r: Rect) Self {
        return Self{ .x = self.x - r.x, .y = self.y - r.y, .w = self.w + r.x + r.w, .h = self.h + r.y + r.h };
    }

    pub fn outsetAll(self: *const Self, p: f32) Self {
        return self.outset(Rect.all(p));
    }

    pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Rect{{ {d} {d} {d} {d} }}", .{ self.x, self.y, self.w, self.h });
    }
};

pub const RectScale = struct {
    r: Rect = Rect{},
    s: f32 = 0.0,

    pub fn child(rs: *const RectScale, r: Rect) RectScale {
        return .{ .r = r.scale(rs.s).offset(rs.r), .s = rs.s };
    }

    pub fn childPoint(rs: *const RectScale, p: Point) Point {
        return p.scale(rs.s).plus(rs.r.topleft());
    }
};

pub fn renderText(font: Font, text: []const u8, rs: RectScale, color: Color) void {
    if (text.len == 0 or clipGet().intersect(rs.r).empty()) {
        return;
    }

    //if (true) return;

    var cw = current_window orelse unreachable;

    if (cw.window_currentId != cw.wd.id) {
        var txt = cw.arena.alloc(u8, text.len) catch unreachable;
        std.mem.copy(u8, txt, text);
        var cmd = RenderCmd{ .snap = snap_to_pixels, .clip = clipGet(), .cmd = .{ .text = .{ .font = font, .text = txt, .rs = rs, .color = color } } };

        var i = cw.floating_data.items.len;
        while (i > 0) : (i -= 1) {
            const fw = &cw.floating_data.items[i - 1];
            if (fw.id == cw.window_currentId) {
                fw.render_cmds.append(cmd) catch unreachable;
                break;
            }
        }

        return;
    }

    // Make sure to always ask for a bigger size font, we'll reduce it down below
    const target_size = font.size * rs.s;
    const ask_size = @ceil(target_size);
    const target_fraction = target_size / ask_size;

    const sized_font = font.resize(ask_size);
    var fce = fontCacheGet(sized_font);

    // make sure the cache has all the glyphs we need
    var utf8it = (std.unicode.Utf8View.init(text) catch unreachable).iterator();
    while (utf8it.nextCodepoint()) |codepoint| {
        _ = fce.glyphInfoGet(@intCast(u32, codepoint));
    }

    // number of extra pixels to add on each side of each glyph
    const pad = 1;

    if (fce.texture_atlas_regen) {
        fce.texture_atlas_regen = false;
        cw.backend.textureDestroy(fce.texture_atlas);

        const row_glyphs = @floatToInt(u32, @ceil(@sqrt(@intToFloat(f32, fce.glyph_info.count()))));

        var size = Size{};
        {
            var it = fce.glyph_info.valueIterator();
            var i: u32 = 0;
            var rowlen: f32 = 0;
            while (it.next()) |gi| {
                if (i % row_glyphs == 0) {
                    size.w = math.max(size.w, rowlen);
                    size.h += fce.height + 2 * pad;
                    rowlen = 0;
                }

                rowlen += (gi.maxx - gi.minx) + 2 * pad;
                i += 1;
            } else {
                size.w = math.max(size.w, rowlen);
            }

            size = size.ceil();
        }

        // also add an extra padding around whole texture
        size.w += 2 * pad;
        size.h += 2 * pad;

        var pixels = cw.arena.alloc(u8, @floatToInt(usize, size.w * size.h) * 4) catch unreachable;
        // set all pixels as white but with zero alpha
        for (pixels) |*p, i| {
            if (i % 4 == 3) {
                p.* = 0;
            } else {
                p.* = 255;
            }
        }

        //const num_glyphs = fce.glyph_info.count();
        //std.debug.print("font size {d} regen glyph atlas num {d} max size {}\n", .{ sized_font.size, num_glyphs, size });

        {
            var x: i32 = pad;
            var y: i32 = pad;
            var it = fce.glyph_info.iterator();
            var i: u32 = 0;
            while (it.next()) |e| {
                e.value_ptr.uv[0] = @intToFloat(f32, x) / size.w;
                e.value_ptr.uv[1] = @intToFloat(f32, y) / size.h;

                fce.face.loadChar(@intCast(u32, e.key_ptr.*), .{ .render = true }) catch unreachable;
                const bitmap = fce.face.glyph().bitmap();
                //std.debug.print("codepoint {d} gi {d}x{d} bitmap {d}x{d}\n", .{ e.key_ptr.*, e.value_ptr.maxx - e.value_ptr.minx, e.value_ptr.maxy - e.value_ptr.miny, bitmap.width(), bitmap.rows() });
                var row: i32 = 0;
                while (row < bitmap.rows()) : (row += 1) {
                    var col: i32 = 0;
                    while (col < bitmap.width()) : (col += 1) {
                        const src = bitmap.buffer().?[@intCast(usize, row * bitmap.pitch() + col)];

                        // because of the extra edge, offset by 1 row and 1 col
                        const di = @intCast(usize, (y + row + pad) * @floatToInt(i32, size.w) * 4 + (x + col + pad) * 4);

                        // not doing premultiplied alpha (yet), so keep the white color but adjust the alpha
                        //pixels[di] = src;
                        //pixels[di+1] = src;
                        //pixels[di+2] = src;
                        pixels[di + 3] = src;
                    }
                }

                x += @intCast(i32, bitmap.width()) + 2 * pad;

                i += 1;
                if (i % row_glyphs == 0) {
                    x = pad;
                    y += @floatToInt(i32, fce.height) + 2 * pad;
                }
            }
        }

        fce.texture_atlas = cw.backend.textureCreate(pixels, @floatToInt(u32, size.w), @floatToInt(u32, size.h));
        fce.texture_atlas_size = size;
    }

    //std.debug.print("creating text texture size {} font size {d} for \"{s}\"\n", .{size, font.size, text});
    var vtx = std.ArrayList(Vertex).init(cw.arena);
    defer vtx.deinit();
    var idx = std.ArrayList(u32).init(cw.arena);
    defer idx.deinit();

    var x: f32 = if (snap_to_pixels) @round(rs.r.x) else rs.r.x;
    var y: f32 = if (snap_to_pixels) @round(rs.r.y) else rs.r.y;

    var utf8 = (std.unicode.Utf8View.init(text) catch unreachable).iterator();
    while (utf8.nextCodepoint()) |codepoint| {
        const gi = fce.glyphInfoGet(@intCast(u32, codepoint));

        // TODO: kerning

        const len = @intCast(u32, vtx.items.len);
        var v: Vertex = undefined;

        v.pos.x = x + (gi.minx - pad) * target_fraction;
        v.pos.y = y + (gi.miny - pad) * target_fraction;
        v.col = color;
        v.uv = gi.uv;
        vtx.append(v) catch unreachable;

        v.pos.x = x + (gi.maxx + pad) * target_fraction;
        v.uv[0] = gi.uv[0] + (gi.maxx - gi.minx + 2 * pad) / fce.texture_atlas_size.w;
        vtx.append(v) catch unreachable;

        v.pos.y = y + (gi.maxy + pad) * target_fraction;
        v.uv[1] = gi.uv[1] + (gi.maxy - gi.miny + 2 * pad) / fce.texture_atlas_size.h;
        vtx.append(v) catch unreachable;

        v.pos.x = x + (gi.minx - pad) * target_fraction;
        v.uv[0] = gi.uv[0];
        vtx.append(v) catch unreachable;

        idx.append(len + 0) catch unreachable;
        idx.append(len + 1) catch unreachable;
        idx.append(len + 2) catch unreachable;
        idx.append(len + 0) catch unreachable;
        idx.append(len + 2) catch unreachable;
        idx.append(len + 3) catch unreachable;

        x += gi.advance * target_fraction;
    }

    cw.backend.renderGeometry(fce.texture_atlas, vtx.items, idx.items);
}

pub fn debugRenderFontAtlases(rs: RectScale, color: Color) void {
    if (clipGet().intersect(rs.r).empty()) {
        return;
    }

    var cw = current_window orelse unreachable;

    if (cw.window_currentId != cw.wd.id) {
        var cmd = RenderCmd{ .snap = snap_to_pixels, .clip = clipGet(), .cmd = .{ .debug_font_atlases = .{ .rs = rs, .color = color } } };

        var i = cw.floating_data.items.len;
        while (i > 0) : (i -= 1) {
            const fw = &cw.floating_data.items[i - 1];
            if (fw.id == cw.window_currentId) {
                fw.render_cmds.append(cmd) catch unreachable;
                break;
            }
        }

        return;
    }

    var x: f32 = if (snap_to_pixels) @round(rs.r.x) else rs.r.x;
    var y: f32 = if (snap_to_pixels) @round(rs.r.y) else rs.r.y;

    var offset: f32 = 0;
    var it = cw.font_cache.iterator();
    while (it.next()) |kv| {
        var vtx = std.ArrayList(Vertex).init(cw.arena);
        defer vtx.deinit();
        var idx = std.ArrayList(u32).init(cw.arena);
        defer idx.deinit();

        const len = @intCast(u32, vtx.items.len);
        var v: Vertex = undefined;
        v.pos.x = x;
        v.pos.y = y + offset;
        v.col = color;
        v.uv = .{ 0, 0 };
        vtx.append(v) catch unreachable;

        v.pos.x = x + kv.value_ptr.texture_atlas_size.w;
        v.uv[0] = 1;
        vtx.append(v) catch unreachable;

        v.pos.y = y + offset + kv.value_ptr.texture_atlas_size.h;
        v.uv[1] = 1;
        vtx.append(v) catch unreachable;

        v.pos.x = x;
        v.uv[0] = 0;
        vtx.append(v) catch unreachable;

        idx.append(len + 0) catch unreachable;
        idx.append(len + 1) catch unreachable;
        idx.append(len + 2) catch unreachable;
        idx.append(len + 0) catch unreachable;
        idx.append(len + 2) catch unreachable;
        idx.append(len + 3) catch unreachable;

        cw.backend.renderGeometry(kv.value_ptr.texture_atlas, vtx.items, idx.items);

        offset += kv.value_ptr.texture_atlas_size.h;
    }
}

pub fn renderIcon(name: []const u8, tvg_bytes: []const u8, rs: RectScale, colormod: Color) void {
    if (clipGet().intersect(rs.r).empty()) {
        return;
    }

    //if (true) return;

    var cw = current_window orelse unreachable;

    if (cw.window_currentId != cw.wd.id) {
        var name_copy = cw.arena.alloc(u8, name.len) catch unreachable;
        std.mem.copy(u8, name_copy, name);
        var cmd = RenderCmd{ .snap = snap_to_pixels, .clip = clipGet(), .cmd = .{ .icon = .{ .name = name_copy, .tvg_bytes = tvg_bytes, .rs = rs, .colormod = colormod } } };

        var i = cw.floating_data.items.len;
        while (i > 0) : (i -= 1) {
            const fw = &cw.floating_data.items[i - 1];
            if (fw.id == cw.window_currentId) {
                fw.render_cmds.append(cmd) catch unreachable;
                break;
            }
        }

        return;
    }

    // Make sure to always ask for a bigger size icon, we'll reduce it down below
    const target_size = rs.r.h;
    const ask_height = @ceil(target_size);
    const target_fraction = target_size / ask_height;

    const ice = iconTexture(name, tvg_bytes, ask_height);

    var vtx = std.ArrayList(Vertex).initCapacity(cw.arena, 4) catch unreachable;
    defer vtx.deinit();
    var idx = std.ArrayList(u32).initCapacity(cw.arena, 6) catch unreachable;
    defer idx.deinit();

    var x: f32 = if (snap_to_pixels) @round(rs.r.x) else rs.r.x;
    var y: f32 = if (snap_to_pixels) @round(rs.r.y) else rs.r.y;

    var v: Vertex = undefined;
    v.pos.x = x;
    v.pos.y = y;
    v.col = colormod;
    v.uv[0] = 0;
    v.uv[1] = 0;
    vtx.append(v) catch unreachable;

    v.pos.x = x + ice.size.w * target_fraction;
    v.uv[0] = 1;
    vtx.append(v) catch unreachable;

    v.pos.y = y + ice.size.h * target_fraction;
    v.uv[1] = 1;
    vtx.append(v) catch unreachable;

    v.pos.x = x;
    v.uv[0] = 0;
    vtx.append(v) catch unreachable;

    idx.append(0) catch unreachable;
    idx.append(1) catch unreachable;
    idx.append(2) catch unreachable;
    idx.append(0) catch unreachable;
    idx.append(2) catch unreachable;
    idx.append(3) catch unreachable;

    cw.backend.renderGeometry(ice.texture, vtx.items, idx.items);
}

pub const KeyEvent = struct {
    pub const Kind = enum {
        down,
        repeat,
        up,
    };
    keysym: keys.Key,
    mod: keys.Mod,
    state: Kind,
};

pub const TextEvent = struct {
    text: []u8,
};

pub const MouseEvent = struct {
    pub const Kind = enum {
        leftdown,
        leftup,
        rightdown,
        rightup,
        wheel_y,
        // focus events come right before their associated mouse event, either
        // leftdown/rightdown or motion, because sometimes a scrollArea wants
        // to get the focus but let the underlying window handle the click
        focus,
        // if you just want to react to the current mouse position if it got
        // moved, use the .position event with mouseTotalMotion()
        motion,
        // only one position event per frame, and it's always after all other
        // mouse events, used to change mouse cursor and do widget highlighting
        // - also useful with mouseTotalMotion() to respond to mouse motion but
        // only at the final location
        position,
    };
    p: Point,
    dp: Point, // for .motion
    wheel: f32, // for .wheel_y
    floating_win: u32,
    state: Kind,
};

pub const ClosePopupEvent = struct {
    // are we closing because of a specific user action (clicked on menu item,
    // pressed escape), or because they clicked off the menu somewhere?
    intentional: bool = true,
};

pub const AnyEvent = union(enum) {
    key: KeyEvent,
    text: TextEvent,
    mouse: MouseEvent,
    close_popup: ClosePopupEvent,
};

pub const Event = struct {
    handled: bool = false,
    focus_windowId: u32 = 0,
    focus_widgetId: ?u32 = null,
    evt: AnyEvent,
};

pub const WidgetData = struct {
    id: u32 = undefined,
    parent: Widget = undefined,
    rect: Rect = Rect{},
    min_size: Size = Size{},
    options: Options = undefined,

    pub fn init(src: std.builtin.SourceLocation, id_extra: usize, opts: Options) WidgetData {
        var self = WidgetData{};
        self.options = opts;

        self.parent = parentGet();
        self.id = self.parent.extendID(src, id_extra);
        self.min_size = self.options.min_size orelse Size{};
        if (self.options.rect) |r| {
            self.rect = r;
            if (self.options.expandHorizontal()) {
                self.rect.w = self.parent.data().rect.w;
            }
            if (self.options.expandVertical()) {
                self.rect.h = self.parent.data().rect.h;
            }
        } else {
            self.rect = self.parent.rectFor(self.id, self.min_size, self.options.expandGet(), self.options.gravityGet());
        }

        return self;
    }

    pub fn visible(self: *const WidgetData) bool {
        return !clipGet().intersect(self.borderRectScale().r).empty();
    }

    pub fn borderAndBackground(self: *const WidgetData) void {
        var bg = self.options.background orelse false;
        if (self.options.borderGet().nonZero()) {
            bg = true;
            const rs = self.borderRectScale();
            pathAddRect(rs.r, self.options.corner_radiusGet().scale(rs.s));
            var col = Color.lerp(self.options.color_bg(), 0.3, self.options.color());
            pathFillConvex(col);
        }

        if (bg) {
            const rs = self.backgroundRectScale();
            pathAddRect(rs.r, self.options.corner_radiusGet().scale(rs.s));
            pathFillConvex(self.options.color_bg());
        }
    }

    pub fn focusBorder(self: *const WidgetData) void {
        const rs = self.borderRectScale();
        const thick = 2 * rs.s;
        pathAddRect(rs.r, self.options.corner_radiusGet().scale(rs.s));
        var color = themeGet().color_accent_bg;
        switch (self.options.color_style orelse .custom) {
            .err, .success, .accent => {
                if (themeGet().dark) {
                    color = self.options.color_bg().lighten(0.3);
                } else {
                    color = self.options.color_bg().darken(0.2);
                }
            },
            else => {},
        }
        pathStrokeAfter(true, true, thick, .none, color);
    }

    pub fn placeInsideNoExpand(self: *WidgetData) void {
        self.rect = placeIn(null, self.rect, self.min_size, .none, self.options.gravityGet());
    }

    pub fn scale(self: *const WidgetData) f32 {
        return self.parent.screenRectScale(self.rect).s;
    }

    pub fn borderRect(self: *const WidgetData) Rect {
        return self.rect.inset(self.options.marginGet());
    }

    pub fn borderRectScale(self: *const WidgetData) RectScale {
        return self.parent.screenRectScale(self.borderRect());
    }

    pub fn backgroundRect(self: *const WidgetData) Rect {
        return self.rect.inset(self.options.marginGet()).inset(self.options.borderGet());
    }

    pub fn backgroundRectScale(self: *const WidgetData) RectScale {
        return self.parent.screenRectScale(self.backgroundRect());
    }

    pub fn contentRect(self: *const WidgetData) Rect {
        return self.rect.inset(self.options.marginGet()).inset(self.options.borderGet()).inset(self.options.paddingGet());
    }

    pub fn contentRectScale(self: *const WidgetData) RectScale {
        return self.parent.screenRectScale(self.contentRect());
    }

    pub fn padSize(self: *const WidgetData, s: Size) Size {
        return s.pad(self.options.paddingGet()).pad(self.options.borderGet()).pad(self.options.marginGet());
    }

    pub fn minSizeMax(self: *WidgetData, s: Size) void {
        self.min_size = Size.max(self.min_size, s);
    }

    pub fn minSizeSetAndCue(self: *const WidgetData) void {
        if (minSizeGetPrevious(self.id)) |ms| {
            // If the size we got was exactly our previous min size then our min size
            // was a binding constraint.  So if our min size changed it might cause
            // layout changes.

            // If this was like a Label where we knew the min size before getting our
            // rect, then either our min size is the same as previous, or our rect is
            // a different size than our previous min size.
            if ((self.rect.w == ms.w and ms.w != self.min_size.w) or
                (self.rect.h == ms.h and ms.h != self.min_size.h))
            {
                cueFrame();
            }
        } else {
            // This is the first frame for this widget.  Almost always need a
            // second frame to appear correctly since nobody knew our min size the
            // first frame.
            cueFrame();
        }
        minSizeSet(self.id, self.min_size);
    }

    pub fn minSizeReportToParent(self: *const WidgetData) void {
        self.parent.minSizeForChild(self.min_size);
    }
};

pub const Widget = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        data: *const fn (ptr: *anyopaque) *const WidgetData,
        rectFor: *const fn (ptr: *anyopaque, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect,
        minSizeForChild: *const fn (ptr: *anyopaque, s: Size) void,
        screenRectScale: *const fn (ptr: *anyopaque, r: Rect) RectScale,
        processEvent: *const fn (ptr: *anyopaque, iter: *EventIterator, e: *Event) void,
        bubbleEvent: *const fn (ptr: *anyopaque, e: *Event) void,
    };

    pub fn init(
        pointer: anytype,
        comptime dataFn: fn (ptr: @TypeOf(pointer)) *const WidgetData,
        comptime rectForFn: fn (ptr: @TypeOf(pointer), id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect,
        comptime minSizeForChildFn: fn (ptr: @TypeOf(pointer), s: Size) void,
        comptime screenRectScaleFn: fn (ptr: @TypeOf(pointer), r: Rect) RectScale,
        comptime processEventFn: fn (ptr: @TypeOf(pointer), iter: *EventIterator, e: *Event) void,
        comptime bubbleEventFn: fn (ptr: @TypeOf(pointer), e: *Event) void,
    ) Widget {
        const Ptr = @TypeOf(pointer);
        const ptr_info = @typeInfo(Ptr);
        std.debug.assert(ptr_info == .Pointer); // Must be a pointer
        std.debug.assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer
        const alignment = ptr_info.Pointer.alignment;

        const gen = struct {
            fn dataImpl(ptr: *anyopaque) *const WidgetData {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, dataFn, .{self});
            }

            fn rectForImpl(ptr: *anyopaque, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, rectForFn, .{ self, id, min_size, e, g });
            }

            fn minSizeForChildImpl(ptr: *anyopaque, s: Size) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, minSizeForChildFn, .{ self, s });
            }

            fn screenRectScaleImpl(ptr: *anyopaque, r: Rect) RectScale {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, screenRectScaleFn, .{ self, r });
            }

            fn processEventImpl(ptr: *anyopaque, iter: *EventIterator, e: *Event) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, processEventFn, .{ self, iter, e });
            }

            fn bubbleEventImpl(ptr: *anyopaque, e: *Event) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, bubbleEventFn, .{ self, e });
            }

            const vtable = VTable{
                .data = dataImpl,
                .rectFor = rectForImpl,
                .minSizeForChild = minSizeForChildImpl,
                .screenRectScale = screenRectScaleImpl,
                .processEvent = processEventImpl,
                .bubbleEvent = bubbleEventImpl,
            };
        };

        return .{
            .ptr = pointer,
            .vtable = &gen.vtable,
        };
    }

    pub fn data(self: Widget) *const WidgetData {
        return self.vtable.data(self.ptr);
    }

    pub fn extendID(self: Widget, src: std.builtin.SourceLocation, id_extra: usize) u32 {
        var hash = fnv.init();
        hash.value = self.data().id;
        hash.update(src.file);
        hash.update(std.mem.asBytes(&src.line));
        hash.update(std.mem.asBytes(&src.column));
        hash.update(std.mem.asBytes(&id_extra));
        return hash.final();
    }

    pub fn processEvents(self: Widget) void {
        var iter = EventIterator.init(self.data().id, self.data().borderRectScale().r);
        while (iter.next()) |e| {
            self.processEvent(&iter, e);
        }
    }

    pub fn rectFor(self: Widget, id: u32, min_size: Size, e: Options.Expand, g: Options.Gravity) Rect {
        return self.vtable.rectFor(self.ptr, id, min_size, e, g);
    }

    pub fn minSizeForChild(self: Widget, s: Size) void {
        self.vtable.minSizeForChild(self.ptr, s);
    }

    pub fn screenRectScale(self: Widget, r: Rect) RectScale {
        return self.vtable.screenRectScale(self.ptr, r);
    }

    pub fn processEvent(self: Widget, iter: *EventIterator, e: *Event) void {
        self.vtable.processEvent(self.ptr, iter, e);
    }

    pub fn bubbleEvent(self: Widget, e: *Event) void {
        self.vtable.bubbleEvent(self.ptr, e);
    }
};

pub const Backend = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        begin: *const fn (ptr: *anyopaque, arena: std.mem.Allocator) void,
        end: *const fn (ptr: *anyopaque) void,
        pixelSize: *const fn (ptr: *anyopaque) Size,
        windowSize: *const fn (ptr: *anyopaque) Size,
        renderGeometry: *const fn (ptr: *anyopaque, texture: ?*anyopaque, vtx: []Vertex, idx: []u32) void,
        textureCreate: *const fn (ptr: *anyopaque, pixels: []u8, width: u32, height: u32) *anyopaque,
        textureDestroy: *const fn (ptr: *anyopaque, texture: *anyopaque) void,
    };

    pub fn init(
        pointer: anytype,
        comptime beginFn: fn (ptr: @TypeOf(pointer), arena: std.mem.Allocator) void,
        comptime endFn: fn (ptr: @TypeOf(pointer)) void,
        comptime pixelSizeFn: fn (ptr: @TypeOf(pointer)) Size,
        comptime windowSizeFn: fn (ptr: @TypeOf(pointer)) Size,
        comptime renderGeometryFn: fn (ptr: @TypeOf(pointer), texture: ?*anyopaque, vtx: []Vertex, idx: []u32) void,
        comptime textureCreateFn: fn (ptr: @TypeOf(pointer), pixels: []u8, width: u32, height: u32) *anyopaque,
        comptime textureDestroyFn: fn (ptr: @TypeOf(pointer), texture: *anyopaque) void,
    ) Backend {
        const Ptr = @TypeOf(pointer);
        const ptr_info = @typeInfo(Ptr);
        std.debug.assert(ptr_info == .Pointer); // Must be a pointer
        std.debug.assert(ptr_info.Pointer.size == .One); // Must be a single-item pointer
        const alignment = ptr_info.Pointer.alignment;

        const gen = struct {
            fn beginImpl(ptr: *anyopaque, arena: std.mem.Allocator) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, beginFn, .{ self, arena });
            }

            fn endImpl(ptr: *anyopaque) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, endFn, .{self});
            }

            fn pixelSizeImpl(ptr: *anyopaque) Size {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, pixelSizeFn, .{self});
            }

            fn windowSizeImpl(ptr: *anyopaque) Size {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, windowSizeFn, .{self});
            }

            fn renderGeometryImpl(ptr: *anyopaque, texture: ?*anyopaque, vtx: []Vertex, idx: []u32) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, renderGeometryFn, .{ self, texture, vtx, idx });
            }

            fn textureCreateImpl(ptr: *anyopaque, pixels: []u8, width: u32, height: u32) *anyopaque {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, textureCreateFn, .{ self, pixels, width, height });
            }

            fn textureDestroyImpl(ptr: *anyopaque, texture: *anyopaque) void {
                const self = @ptrCast(Ptr, @alignCast(alignment, ptr));
                return @call(.{ .modifier = .always_inline }, textureDestroyFn, .{ self, texture });
            }

            const vtable = VTable{
                .begin = beginImpl,
                .end = endImpl,
                .pixelSize = pixelSizeImpl,
                .windowSize = windowSizeImpl,
                .renderGeometry = renderGeometryImpl,
                .textureCreate = textureCreateImpl,
                .textureDestroy = textureDestroyImpl,
            };
        };

        return .{
            .ptr = pointer,
            .vtable = &gen.vtable,
        };
    }

    pub fn begin(self: *Backend, arena: std.mem.Allocator) void {
        self.vtable.begin(self.ptr, arena);
    }

    pub fn end(self: *Backend) void {
        self.vtable.end(self.ptr);
    }

    pub fn pixelSize(self: *Backend) Size {
        return self.vtable.pixelSize(self.ptr);
    }

    pub fn windowSize(self: *Backend) Size {
        return self.vtable.windowSize(self.ptr);
    }

    pub fn renderGeometry(self: *Backend, texture: ?*anyopaque, vtx: []Vertex, idx: []u32) void {
        self.vtable.renderGeometry(self.ptr, texture, vtx, idx);
    }

    pub fn textureCreate(self: *Backend, pixels: []u8, width: u32, height: u32) *anyopaque {
        return self.vtable.textureCreate(self.ptr, pixels, width, height);
    }

    pub fn textureDestroy(self: *Backend, texture: *anyopaque) void {
        self.vtable.textureDestroy(self.ptr, texture);
    }
};

pub const examples = struct {
    pub var show_demo_window: bool = true;
    var checkbox_bool: bool = false;
    var show_dialog: bool = false;
    var scale_val: f32 = 1.0;

    const IconBrowser = struct {
        var show: bool = false;
        var rect = gui.Rect{ .x = 0, .y = 0, .w = 300, .h = 400 };
        var row_height: f32 = 0;
    };

    pub fn demo() bool {
        if (show_demo_window) {
            var float = gui.floatingWindow(@src(), 0, false, null, &show_demo_window, .{ .min_size = .{ .w = 400, .h = 400 } });
            defer float.deinit();

            var buf: [100]u8 = undefined;
            const fps_str = std.fmt.bufPrint(&buf, "{d:4.0} fps", .{gui.FPS()}) catch unreachable;
            gui.windowHeader("GUI Demo", fps_str, &show_demo_window);

            var scroll = gui.scrollArea(@src(), 0, null, .{ .expand = .both, .color_style = .content, .background = false });
            defer scroll.deinit();

            var scaler = gui.scale(@src(), 0, scale_val, .{ .expand = .horizontal });
            defer scaler.deinit();

            var vbox = gui.box(@src(), 0, .vertical, .{ .expand = .horizontal });
            defer vbox.deinit();

            if (gui.expander(@src(), 0, "Basic Widgets", .{ .expand = .horizontal })) {
                basicWidgets();
            }

            if (gui.expander(@src(), 0, "Layout", .{ .expand = .horizontal })) {
                layout();
            }

            if (gui.expander(@src(), 0, "Show Font Atlases", .{ .expand = .horizontal })) {
                debugFontAtlases(@src(), 0, .{});
            }

            if (gui.expander(@src(), 0, "Text Layout", .{ .expand = .horizontal })) {
                textDemo();
            }

            if (gui.expander(@src(), 0, "Menus", .{ .expand = .horizontal })) {
                menus();
            }

            if (gui.expander(@src(), 0, "Dialogs", .{ .expand = .horizontal })) {
                dialogs();
            }

            if (gui.expander(@src(), 0, "Animations", .{ .expand = .horizontal })) {
                animations();
            }

            if (gui.button(@src(), 0, "Icon Browser", .{})) {
                IconBrowser.show = true;
            }

            if (gui.button(@src(), 0, "Toggle Theme", .{})) {
                if (gui.themeGet() == &gui.theme_Adwaita) {
                    gui.themeSet(&gui.theme_Adwaita_Dark);
                } else {
                    gui.themeSet(&gui.theme_Adwaita);
                }
            }

            if (gui.button(@src(), 0, "Zoom In", .{})) {
                scale_val = (themeGet().font_body.size * scale_val + 1.0) / themeGet().font_body.size;

                //std.debug.print("scale {d} {d}\n", .{ scale_val, scale_val * themeGet().font_body.size });
            }

            if (gui.button(@src(), 0, "Zoom Out", .{})) {
                scale_val = (themeGet().font_body.size * scale_val - 1.0) / themeGet().font_body.size;

                //std.debug.print("scale {d} {d}\n", .{ scale_val, scale_val * themeGet().font_body.size });
            }

            gui.checkbox(@src(), 0, &snap_to_pixels, "Snap to Pixels", .{});

            if (show_dialog) {
                dialogDirect();
            }

            if (IconBrowser.show) {
                icon_browser();
            }

            return true;
        }

        return false;
    }

    pub fn basicWidgets() void {
        var b = gui.box(@src(), 0, .vertical, .{ .expand = .horizontal, .margin = .{ .x = 10, .y = 0, .w = 0, .h = 0 } });
        defer b.deinit();

        {
            var hbox = gui.box(@src(), 0, .horizontal, .{});
            defer hbox.deinit();

            _ = gui.button(@src(), 0, "Normal", .{});
            _ = gui.button(@src(), 0, "Accent", .{ .color_style = .accent });
            _ = gui.button(@src(), 0, "Success", .{ .color_style = .success });
            _ = gui.button(@src(), 0, "Error", .{ .color_style = .err });
        }

        gui.checkbox(@src(), 0, &checkbox_bool, "Checkbox", .{});
    }

    pub fn layout() void {
        const opts: Options = .{ .color_style = .content, .border = gui.Rect.all(1), .min_size = .{ .w = 200, .h = 120 } };
        {
            gui.label(@src(), 0, "gravity options:", .{}, .{});
            var o = gui.overlay(@src(), 0, opts);
            defer o.deinit();

            inline for (@typeInfo(Options.Gravity).Enum.fields) |f, i| {
                _ = gui.button(@src(), i, f.name, .{ .gravity = @intToEnum(Options.Gravity, f.value) });
            }
        }

        {
            gui.label(@src(), 0, "expand options:", .{}, .{});
            var hbox = gui.box(@src(), 0, .horizontal, .{});
            defer hbox.deinit();
            {
                var vbox = gui.box(@src(), 0, .vertical, opts);
                defer vbox.deinit();

                _ = gui.button(@src(), 0, "none", .{ .expand = .none });
                _ = gui.button(@src(), 0, "horizontal", .{ .expand = .horizontal });
                _ = gui.button(@src(), 0, "vertical", .{ .expand = .vertical });
            }
            {
                var vbox = gui.box(@src(), 0, .vertical, opts);
                defer vbox.deinit();

                _ = gui.button(@src(), 0, "both", .{ .expand = .both });
            }
        }
    }

    pub fn textDemo() void {
        var b = gui.box(@src(), 0, .vertical, .{ .expand = .horizontal, .margin = .{ .x = 10, .y = 0, .w = 0, .h = 0 } });
        defer b.deinit();
        gui.label(@src(), 0, "Title", .{}, .{ .font_style = .title });
        gui.label(@src(), 0, "Title-1", .{}, .{ .font_style = .title_1 });
        gui.label(@src(), 0, "Title-2", .{}, .{ .font_style = .title_2 });
        gui.label(@src(), 0, "Title-3", .{}, .{ .font_style = .title_3 });
        gui.label(@src(), 0, "Title-4", .{}, .{ .font_style = .title_4 });
        gui.label(@src(), 0, "Heading", .{}, .{ .font_style = .heading });
        gui.label(@src(), 0, "Caption-Heading", .{}, .{ .font_style = .caption_heading });
        gui.label(@src(), 0, "Caption", .{}, .{ .font_style = .caption });

        {
            var tl = gui.textLayout(@src(), 0, .{ .expand = .horizontal });
            defer tl.deinit();

            var cbox = gui.box(@src(), 0, .vertical, gui.Options{ .gravity = .upleft });
            _ = gui.buttonIcon(@src(), 0, 18, "play", gui.icons.papirus.actions.media_playback_start_symbolic, .{ .padding = gui.Rect.all(6) });
            _ = gui.buttonIcon(@src(), 0, 18, "more", gui.icons.papirus.actions.view_more_symbolic, .{ .padding = gui.Rect.all(6) });
            cbox.deinit();

            const start = "Notice that the text in this box is wrapping around the buttons in the corners.";
            tl.addText(start, .{ .font_style = .title_4 });

            tl.addText("\n\n", .{});

            const lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.";
            tl.addText(lorem, .{});
        }
    }

    pub fn menus() void {
        const ctext = gui.context(@src(), 0, .{ .expand = .horizontal });
        defer ctext.deinit();

        if (ctext.activePoint()) |cp| {
            var fw2 = gui.popup(@src(), 0, gui.Rect.fromPoint(cp), .{});
            defer fw2.deinit();

            _ = gui.menuItemLabel(@src(), 0, "Cut", false, .{});
            if (gui.menuItemLabel(@src(), 0, "Close", false, .{}) != null) {
                gui.menuGet().?.close();
            }
            _ = gui.menuItemLabel(@src(), 0, "Paste", false, .{});
        }

        var vbox = gui.box(@src(), 0, .vertical, .{});
        defer vbox.deinit();

        {
            var m = gui.menu(@src(), 0, .horizontal, .{});
            defer m.deinit();

            if (gui.menuItemLabel(@src(), 0, "File", true, .{})) |r| {
                var fw = gui.popup(@src(), 0, gui.Rect.fromPoint(gui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                defer fw.deinit();

                submenus();

                if (gui.menuItemLabel(@src(), 0, "Close", false, .{}) != null) {
                    gui.menuGet().?.close();
                }

                gui.checkbox(@src(), 0, &checkbox_bool, "Checkbox", .{ .min_size = .{ .w = 100, .h = 0 } });

                if (gui.menuItemLabel(@src(), 0, "Dialog", false, .{}) != null) {
                    gui.menuGet().?.close();
                    show_dialog = true;
                }
            }

            if (gui.menuItemLabel(@src(), 0, "Edit", true, .{})) |r| {
                var fw = gui.popup(@src(), 0, gui.Rect.fromPoint(gui.Point{ .x = r.x, .y = r.y + r.h }), .{});
                defer fw.deinit();
                _ = gui.menuItemLabel(@src(), 0, "Cut", false, .{});
                _ = gui.menuItemLabel(@src(), 0, "Copy", false, .{});
                _ = gui.menuItemLabel(@src(), 0, "Paste", false, .{});
            }
        }

        gui.label(@src(), 0, "Right click for a context menu", .{}, .{});
    }

    pub fn submenus() void {
        if (gui.menuItemLabel(@src(), 0, "Submenu...", true, .{})) |r| {
            var menu_rect = r;
            menu_rect.x += menu_rect.w;
            var fw2 = gui.popup(@src(), 0, menu_rect, .{});
            defer fw2.deinit();

            submenus();

            if (gui.menuItemLabel(@src(), 0, "Close", false, .{}) != null) {
                gui.menuGet().?.close();
            }

            if (gui.menuItemLabel(@src(), 0, "Dialog", false, .{}) != null) {
                gui.menuGet().?.close();
                show_dialog = true;
            }
        }
    }

    pub fn dialogs() void {
        var b = gui.box(@src(), 0, .vertical, .{ .expand = .horizontal, .margin = .{ .x = 10, .y = 0, .w = 0, .h = 0 } });
        defer b.deinit();

        {
            var hbox = gui.box(@src(), 0, .horizontal, .{});
            defer hbox.deinit();

            if (gui.button(@src(), 0, "Ok Dialog", .{})) {
                gui.dialogOk(@src(), 0, false, "Ok Dialog", "This is a non modal dialog with no callafter", null);
            }

            const dialogsFollowup = struct {
                fn callafter(id: u32, response: gui.DialogResponse) void {
                    _ = id;
                    var buf: [100]u8 = undefined;
                    const text = std.fmt.bufPrint(&buf, "You clicked {s}", .{@tagName(response)}) catch unreachable;
                    gui.dialogOk(@src(), 0, true, "Ok Followup Response", text, null);
                }
            };

            if (gui.button(@src(), 0, "Ok Followup", .{})) {
                gui.dialogOk(@src(), 0, true, "Ok Followup", "This is a modal dialog with modal followup", dialogsFollowup.callafter);
            }
        }
    }

    pub fn animations() void {
        var b = gui.box(@src(), 0, .vertical, .{ .expand = .horizontal, .margin = .{ .x = 10, .y = 0, .w = 0, .h = 0 } });
        defer b.deinit();
        if (gui.expander(@src(), 0, "Spinner", .{ .expand = .horizontal })) {
            gui.label(@src(), 0, "Spinner maxes out frame rate", .{}, .{});
            gui.spinner(@src(), 0, .{ .color_style = .custom, .color_custom = .{ .r = 100, .g = 200, .b = 100 } });
        }

        if (gui.expander(@src(), 0, "Clock", .{ .expand = .horizontal })) {
            gui.label(@src(), 0, "Schedules a frame at the beginning of each second", .{}, .{});

            const millis = @divFloor(gui.frameTimeNS(), 1_000_000);
            const left = @intCast(i32, @rem(millis, 1000));

            var mslabel = gui.LabelWidget.init(@src(), 0, "{d} ms into second", .{@intCast(u32, left)}, .{});
            mslabel.install();

            if (gui.timerDone(mslabel.wd.id) or !gui.timerExists(mslabel.wd.id)) {
                const wait = 1000 * (1000 - left);
                gui.timerSet(mslabel.wd.id, wait);
            }
        }
    }

    pub fn dialogDirect() void {
        var dialog_win = gui.floatingWindow(@src(), 0, true, null, &show_dialog, .{ .color_style = .window });
        defer dialog_win.deinit();

        gui.windowHeader("Modal Dialog", "", &show_dialog);
        gui.label(@src(), 0, "Asking a Question", .{}, .{ .font_style = .title_4 });
        gui.label(@src(), 0, "This dialog is being shown in a direct style, controlled entirely in user code.", .{}, .{});

        {
            var hbox = gui.box(@src(), 0, .horizontal, .{ .gravity = .right });
            defer hbox.deinit();

            if (gui.button(@src(), 0, "Yes", .{})) {
                dialog_win.close();
            }

            if (gui.button(@src(), 0, "No", .{})) {
                show_dialog = false;
            }
        }
    }

    pub fn icon_browser() void {
        var fwin = gui.floatingWindow(@src(), 0, false, &IconBrowser.rect, &IconBrowser.show, .{});
        defer fwin.deinit();
        gui.windowHeader("Icon Browser", "", &IconBrowser.show);

        const num_icons = @typeInfo(gui.icons.papirus.actions).Struct.decls.len;
        const height = @intToFloat(f32, num_icons) * IconBrowser.row_height;

        var scroll = gui.scrollArea(@src(), 0, gui.Size{ .w = 0, .h = height }, .{ .expand = .both });
        defer scroll.deinit();

        const visibleRect = scroll.visibleRect();
        var cursor: f32 = 0;

        inline for (@typeInfo(gui.icons.papirus.actions).Struct.decls) |d, i| {
            if (cursor <= (visibleRect.y + visibleRect.h) and (cursor + IconBrowser.row_height) >= visibleRect.y) {
                const r = gui.Rect{ .x = 0, .y = cursor, .w = 0, .h = IconBrowser.row_height };
                var iconbox = gui.box(@src(), i, .horizontal, .{ .expand = .horizontal, .rect = r });
                //gui.icon(@src(), 0, 20, d.name, @field(gui.icons.papirus.actions, d.name), .{.margin = gui.Rect.all(2)});
                _ = gui.buttonIcon(@src(), 0, 20, d.name, @field(gui.icons.papirus.actions, d.name), .{ .min_size = gui.Size.all(r.h) });
                gui.label(@src(), 0, d.name, .{}, .{ .gravity = .left });

                iconbox.deinit();

                if (IconBrowser.row_height == 0) {
                    IconBrowser.row_height = iconbox.wd.min_size.h;
                }
            }

            cursor += IconBrowser.row_height;
        }
    }
};
