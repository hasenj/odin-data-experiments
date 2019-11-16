// stolen from https://gist.github.com/thebirk/f01d0ed63a61d86813fbbd4cc0badcc5
package freetype

using import "core:c"
import "core:os"

when os.OS == "windows" do foreign import ftlib "freetype.lib";
else when os.OS == "linux" do foreign import ftlib "system:freetype";
else when os.OS == "darwin" do foreign import ftlib "system:freetype";


FT_Library_ :: struct {}
FT_Library  :: ^FT_Library_;

FT_Size_Internal :: rawptr;
FT_Size_Metrics :: struct {
    x_ppem      : u16,
    y_ppem      : u16,
    x_scale     : long,
    y_scale     : long,
    ascender    : long,
    descender   : long,
    height      : long,
    max_advance : long,
}

FT_Generic_Finalizer :: proc "c" (object: rawptr);
FT_Generic :: struct {
    data: rawptr,
    finalizer: FT_Generic_Finalizer,
}

FT_SizeRec :: struct {
    face     : FT_Face,
    generic  : FT_Generic,
    metrics  : FT_Size_Metrics,
    internal : FT_Size_Internal,
}
FT_Size :: ^FT_SizeRec;

FT_Bitmap_Size :: struct {
    height : i16,
    width  : i16,
    size   : long,
    x_ppem : long,
    y_ppem : long,
}

FT_Encoding :: enum i32 {
    FT_ENCODING_NONE      = 0,
    FT_ENCODING_MS_SYMBOL = ('s' << 24) | ('y' << 16) | ('m' << 8) | 'b',
    FT_ENCODING_UNICODE   = ('u' << 24) | ('n' << 16) | ('i' << 8) | 'c',
    FT_ENCODING_SJIS      = ('s' << 24) | ('j' << 16) | ('i' << 8) | 's',
    FT_ENCODING_PRC       = ('g' << 24) | ('b' << 16) | (' ' << 8) | ' ',
    FT_ENCODING_BIG5      = ('b' << 24) | ('i' << 16) | ('g' << 8) | '5',
    FT_ENCODING_WANSUNG   = ('w' << 24) | ('a' << 16) | ('n' << 8) | 's',
    FT_ENCODING_JOHAB     = ('j' << 24) | ('o' << 16) | ('h' << 8) | 'a',

    /* for backward compatibility */
    FT_ENCODING_GB2312     = FT_ENCODING_PRC,
    FT_ENCODING_MS_SJIS    = FT_ENCODING_SJIS,
    FT_ENCODING_MS_GB2312  = FT_ENCODING_PRC,
    FT_ENCODING_MS_BIG5    = FT_ENCODING_BIG5,
    FT_ENCODING_MS_WANSUNG = FT_ENCODING_WANSUNG,
    FT_ENCODING_MS_JOHAB   = FT_ENCODING_JOHAB,

    FT_ENCODING_ADOBE_STANDARD = ('A' << 24) | ('D' << 16) | ('O' << 8) | 'B',
    FT_ENCODING_ADOBE_EXPERT   = ('A' << 24) | ('D' << 16) | ('B' << 8) | 'E',
    FT_ENCODING_ADOBE_CUSTOM   = ('A' << 24) | ('D' << 16) | ('B' << 8) | 'C',
    FT_ENCODING_ADOBE_LATIN_1  = ('l' << 24) | ('a' << 16) | ('t' << 8) | '1',
    FT_ENCODING_OLD_LATIN_2    = ('l' << 24) | ('a' << 16) | ('t' << 8) | '2',
    FT_ENCODING_APPLE_ROMAN    = ('a' << 24) | ('r' << 16) | ('m' << 8) | 'n',
}

FT_CharMapRec :: struct {
    face        : FT_Face,
    encoding    : FT_Encoding,
    platform_id : u16,
    encoding_id : u16,
}
FT_CharMap :: ^FT_CharMapRec;

FT_BBox :: struct {
    xMin, yMin: long,
    xMax, yMax: long,
}

FT_Glyph_Metrics :: struct {
    width        : long,
    height       : long,
    horiBearingX : long,
    horiBearingY : long,
    horiAdvance  : long,
    vertBearingX : long,
    vertBearingY : long,
    vertAdvance  : long,
}

FT_Glyph_Format :: enum i32 {
    FT_GLYPH_FORMAT_NONE      = 0,
    FT_GLYPH_FORMAT_COMPOSITE = ('c' << 24) | ('o' << 16) | ('m' << 8) | 'p',
    FT_GLYPH_FORMAT_BITMAP    = ('b' << 24) | ('i' << 16) | ('t' << 8) | 's',
    FT_GLYPH_FORMAT_OUTLINE   = ('o' << 24) | ('u' << 16) | ('t' << 8) | 'l',
    FT_GLYPH_FORMAT_PLOTTER   = ('p' << 24) | ('l' << 16) | ('o' << 8) | 't',
}

FT_Bitmap :: struct {
    rows         : u32,
    width        : u32,
    pitch        : int,
    buffer       : ^u8,
    num_grays    : u16,
    pixel_mode   : u8,
    palette_mode : u8,
    palette      : rawptr,
}

FT_Vector :: struct {
    x: long,
    y: long,
}

FT_Outline :: struct {
    n_contours : i16,
    n_points   : i16,
    points     : ^FT_Vector,
    tags       : ^u8,
    contours   : ^i16,
    flags      : i32,
}

FT_SubGlyph :: rawptr;
FT_Slot_Internal :: rawptr;

FT_GlyphSlotRec :: struct {
    library           : FT_Library,
    face              : FT_Face,
    next              : FT_GlyphSlot,
    reserved          : u32,
    generic           : FT_Generic,
    metrics           : FT_Glyph_Metrics,
    linearHoriAdvance : long,
    linearVertAdvance : long,
    advance           : FT_Vector,
    format            : FT_Glyph_Format,
    bitmap            : FT_Bitmap,
    bitmap_left       : i32,
    bitmap_top        : i32,
    outline           : FT_Outline,
    num_subglyphs     : u32,
    subglyphs         : FT_SubGlyph,
    control_data      : rawptr,
    control_len       : long,
    lsb_delta         : long,
    rsb_delta         : long,
    other             : rawptr,
    internal          : FT_Slot_Internal,
}
FT_GlyphSlot :: ^FT_GlyphSlotRec;

FT_Driver :: rawptr;

FT_Alloc_Func   :: proc"c"(memory: FT_Memory, size: long) -> rawptr;
FT_Free_Func    :: proc"c"(memory: FT_Memory, block: rawptr);
FT_Realloc_Func :: proc"c"(memory: FT_Memory, cur_size: long, new_size: long, block: rawptr) -> rawptr;

FT_MemoryRec :: struct {
    user    : rawptr,
    alloc   : FT_Alloc_Func,
    free    : FT_Free_Func,
    realloc : FT_Realloc_Func,
}
FT_Memory :: ^FT_MemoryRec;

FT_Stream_IoFunc    :: proc"c"(stream: FT_Stream, offset: ulong, buffer: ^u8, count: ulong) -> ulong;
FT_Stream_CloseFunc :: proc"c"(stream: FT_Stream);

FT_StreamDesc :: struct #raw_union {
    value: long,
    pointer: rawptr,
}

FT_StreamRec :: struct {
    base       : ^u8,
    size       : ulong,
    pos        : ulong,
    descriptor : FT_StreamDesc,
    pathname   : FT_StreamDesc,
    read       : FT_Stream_IoFunc,
    close      : FT_Stream_CloseFunc,
    memory     : FT_Memory,
    cursor     : ^u8,
    limit      : ^u8,
}
FT_Stream :: ^FT_StreamRec;

FT_ListNode :: rawptr;
FT_ListRec :: struct {
    head : FT_ListNode,
    tail : FT_ListNode,
}
FT_List :: ^FT_ListRec;

FT_Face_Internal :: rawptr;

FT_FaceFlag :: enum long {
    FT_FACE_FLAG_SCALABLE          = 1 <<  0,
    FT_FACE_FLAG_FIXED_SIZES       = 1 <<  1,
    FT_FACE_FLAG_FIXED_WIDTH       = 1 <<  2,
    FT_FACE_FLAG_SFNT              = 1 <<  3,
    FT_FACE_FLAG_HORIZONTAL        = 1 <<  4,
    FT_FACE_FLAG_VERTICAL          = 1 <<  5,
    FT_FACE_FLAG_KERNING           = 1 <<  6,
    FT_FACE_FLAG_FAST_GLYPHS       = 1 <<  7,
    FT_FACE_FLAG_MULTIPLE_MASTERS  = 1 <<  8,
    FT_FACE_FLAG_GLYPH_NAMES       = 1 <<  9,
    FT_FACE_FLAG_EXTERNAL_STREAM   = 1 << 10,
    FT_FACE_FLAG_HINTER            = 1 << 11,
    FT_FACE_FLAG_CID_KEYED         = 1 << 12,
    FT_FACE_FLAG_TRICKY            = 1 << 13,
    FT_FACE_FLAG_COLOR             = 1 << 14,
    FT_FACE_FLAG_VARIATION         = 1 << 15,
}

FT_FaceRec :: struct {
    num_faces       : long,
    face_index      : long,
    face_flags      : FT_FaceFlag,
    style_flags     : long,
    num_glyphs      : long,
    family_name     : ^u8,
    style_name      : ^u8,
    num_fixed_sizes : i32,
    available_sizes : ^FT_Bitmap_Size,
    num_charmaps    : i32,
    charmaps        : ^FT_CharMap,
    generic         : FT_Generic,

    /*# The following member variables (down to `underline_thickness') */
    /*# are only relevant to scalable outlines; cf. @FT_Bitmap_Size    */
    /*# for bitmap fonts.                                              */
    bbox                : FT_BBox,
    units_per_EM        : u16,
    ascender            : i16,
    descender           : i16,
    height              : i16,
    max_advance_width   : i16,
    max_advance_height  : i16,
    underline_position  : i16,
    underline_thickness : i16,
    glyph               : FT_GlyphSlot,
    size                : FT_Size,
    charmap             : FT_CharMap,

    /*@private begin */
    driver      : FT_Driver,
    memory      : FT_Memory,
    stream      : FT_Stream,
    sizes_list  : FT_ListRec,
    autohint    : FT_Generic,
    extensions  : rawptr,
    internal    : FT_Face_Internal,
}
FT_Face     :: ^FT_FaceRec;

FT_Load_Flags :: enum i32 {
    FT_LOAD_DEFAULT                     = 0x0,
    FT_LOAD_NO_SCALE                    = 1 << 0,
    FT_LOAD_NO_HINTING                  = 1 << 1,
    FT_LOAD_RENDER                      = 1 << 2,
    FT_LOAD_NO_BITMAP                   = 1 << 3,
    FT_LOAD_VERTICAL_LAYOUT             = 1 << 4,
    FT_LOAD_FORCE_AUTOHINT              = 1 << 5,
    FT_LOAD_CROP_BITMAP                 = 1 << 6,
    FT_LOAD_PEDANTIC                    = 1 << 7,
    FT_LOAD_IGNORE_GLOBAL_ADVANCE_WIDTH = 1 << 9,
    FT_LOAD_NO_RECURSE                  = 1 << 10,
    FT_LOAD_IGNORE_TRANSFORM            = 1 << 11,
    FT_LOAD_MONOCHROME                  = 1 << 12,
    FT_LOAD_LINEAR_DESIGN               = 1 << 13,
    FT_LOAD_NO_AUTOHINT                 = 1 << 15,
    FT_LOAD_COLOR                       = 1 << 20,
    FT_LOAD_COMPUTE_METRICS             = 1 << 21,
    FT_LOAD_BITMAP_METRICS_ONLY         = 1 << 22,
}

FT_Render_Mode :: enum i32 {
    FT_RENDER_MODE_NORMAL = 0,
    FT_RENDER_MODE_LIGHT,
    FT_RENDER_MODE_MONO,
    FT_RENDER_MODE_LCD,
    FT_RENDER_MODE_LCD_V,
    FT_RENDER_MODE_MAX,
}

FT_Kerning_Mode :: enum u32 {
    FT_KERNING_DEFAULT = 0,
    FT_KERNING_UNFITTED,
    FT_KERNING_UNSCALED,
}

FT_HAS_GLYPH_NAMES :: proc(face: FT_Face) -> bool {
    using FT_FaceFlag;
    return (face.face_flags & FT_FACE_FLAG_GLYPH_NAMES) > FT_FaceFlag(0);
}

FT_HAS_COLOR :: proc(face: FT_Face) -> bool {
    using FT_FaceFlag;
    return (face.face_flags & FT_FACE_FLAG_COLOR) > FT_FaceFlag(0);
}

@(default_calling_convention="c")
foreign ftlib {
    FT_Init_FreeType :: proc(lib: ^FT_Library) -> i32 ---;
    FT_Done_FreeType :: proc(lib: FT_Library)  -> i32 ---;

    FT_New_Face  :: proc(library: FT_Library, path: cstring, face_index: long, face: ^FT_Face) -> i32 ---;
    FT_Done_Face :: proc(face: FT_Face) -> i32 ---;
    FT_Set_Pixel_Sizes :: proc(face: FT_Face, pixel_width: u32, pixel_height: u32) -> i32 ---;

    FT_Load_Glyph      :: proc(face: FT_Face, glyph_index: u32, load_flags: FT_Load_Flags) -> i32 ---;
    FT_Load_Char       :: proc(face: FT_Face, char_code: ulong, load_flags: FT_Load_Flags) -> i32 ---;
    FT_Render_Glyph    :: proc(slot: FT_GlyphSlot, render_mode: FT_Render_Mode) -> i32 ---;

    FT_Get_Char_Index  :: proc(face: FT_Face, charcode: ulong) -> u32 ---;
    FT_Get_Kerning     :: proc(face: FT_Face, left_glyph, right_glyph: u32, kern_mode: u32, kerning: ^FT_Vector) -> i32 ---;
    FT_Get_Glyph_Name  :: proc(face: FT_Face, glyph_index: u32, buffer: ^u8, buffer_max: u32) -> i32 ---;

    FT_Get_First_Char  :: proc(face: FT_Face, agindex: ^c.uint) -> ulong ---;
    FT_Get_Next_Char   :: proc(face: FT_Face, char_code: ulong, agindex: ^c.uint) -> ulong ---;
}
