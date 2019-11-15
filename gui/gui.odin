package gui

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:unicode/utf8"

render_text :: proc(fonts: []^sdl_ttf.Font, color: sdl.Color, text: string) -> ^sdl.Surface {
    r0, _ := utf8.decode_rune_in_string(text);
    // for now just be simple and check only the first glyph!
    font: ^sdl_ttf.Font;
    for f in fonts {
        if sdl_ttf.glyph_is_provided(f, u16(r0)) != 0 {
            font = f;
            break;
        }
    }
    if font == nil {
        return nil; // no suitabe font found; can't render!
    }
    ctext := strings.clone_to_cstring(text);
    defer delete(ctext);
    return sdl_ttf.render_utf8_blended(font, ctext, color);
}

render_text_to_texture :: proc(renderer: ^sdl.Renderer, fonts: []^sdl_ttf.Font, color: sdl.Color, text: string) -> ^sdl.Texture {
    surface := render_text(fonts, color, text);
    if surface == nil {
        return nil;
    }
    defer sdl.free_surface(surface);
    return sdl.create_texture_from_surface(renderer, surface);
}

main :: proc() {
    bg_color := hsla(0, 0, 99.5);
    txt_color := hsla(0, 0, 30);
    ime_color := hsla(0, 0, 60);

    fmt.println(bg_color, txt_color, ime_color);

    sdl.init(sdl.Init_Flags.Everything);
    window := sdl.create_window("Test window", i32(sdl.Window_Pos.Undefined), i32(sdl.Window_Pos.Undefined), 1024, 900, sdl.Window_Flags(0));
    renderer := sdl.create_renderer(window, -1, sdl.Renderer_Flags(0));

    sdl_image.init(sdl_image.Init_Flags.PNG);
    sdl_ttf.init();

    texture := sdl_image.load_texture(renderer, "images/img1.png");

    en_font := sdl_ttf.open_font("fonts/NotoSans-Medium.ttf", 90);
    ar_font := sdl_ttf.open_font("fonts/DroidNaskh-Regular.ttf", 90);
    jp_font := sdl_ttf.open_font("fonts/AiharaHudemojiKaisho2.01.ttf", 90);

    known_fonts := []^sdl_ttf.Font {
        en_font, ar_font, jp_font,
    };

    text_surface0 := sdl_ttf.render_utf8_blended(en_font, "odin-sdl2 now supports packages!", txt_color);
    text_texture0 := sdl.create_texture_from_surface(renderer, text_surface0);
    sdl.free_surface(text_surface0);

    text : string = "كتابة عربية كلام عربي";
    text = shape(text);
    text = strings.reverse(text); // temporary until we get bidi
    ctext := strings.clone_to_cstring(text);
    text_surface1 := sdl_ttf.render_utf8_blended(ar_font, ctext, txt_color);
    text_texture1 := sdl.create_texture_from_surface(renderer, text_surface1);
    sdl.free_surface(text_surface1);

    text_surface2 := sdl_ttf.render_utf8_blended(jp_font, strings.clone_to_cstring(strings.reverse("日本語でも出来ます！")), txt_color);
    text_texture2 := sdl.create_texture_from_surface(renderer, text_surface2);
    sdl.free_surface(text_surface2);

    Input_State :: struct {
        data: [dynamic]byte,
        ime_data: [dynamic]byte,
        cursor: int,
        ui_pos: sdl.Rect,
        rendered_input: ^sdl.Texture,
        rendered_ime: ^sdl.Texture,
    };

    input_state: Input_State;
    input_state.data = make([dynamic]byte, 0, 32);
    input_state.ime_data = make([dynamic]byte, 0, 32);
    input_state.ui_pos = sdl.Rect{x = 100, y = 1200, w = 0, h = 0};

    sdl.start_text_input();
    sdl.set_text_input_rect(&input_state.ui_pos);

    running := true;
    for running {
        e: sdl.Event;
        for sdl.poll_event(&e) != 0 {
            switch e.type {
                case .Quit:
                    running = false;
                case .Text_Input:
                    input_string := as_string(e.text.text[:]);
                    fmt.println("text input event", input_string);
                    input_bytes := cast([]byte)input_string;
                    append(&input_state.data, ..input_bytes);
                    resize(&input_state.ime_data, 0);
                    if input_state.rendered_input != nil {
                        sdl.destroy_texture(input_state.rendered_input);
                        input_state.rendered_input = nil;
                    }
                    if input_state.rendered_ime != nil {
                        sdl.destroy_texture(input_state.rendered_ime);
                        input_state.rendered_ime = nil;
                    }
                    input_state.rendered_input = render_text_to_texture(renderer, known_fonts, txt_color, string(input_state.data[:]));
                case .Text_Editing:
                    input_string := as_string(e.text.text[:]);
                    fmt.println("text editing event", input_string);
                    resize(&input_state.ime_data, len(input_string));
                    copy(input_state.ime_data[:], cast([]byte)input_string);
                    if input_state.rendered_ime != nil {
                        sdl.destroy_texture(input_state.rendered_ime);
                        input_state.rendered_ime = nil;
                    }
                    input_state.rendered_ime = render_text_to_texture(renderer, known_fonts, ime_color, string(input_state.ime_data[:]));
            }
        }
        sdl.set_render_draw_color(renderer, bg_color.r, bg_color.g, bg_color.b, bg_color.a);
        sdl.render_clear(renderer);

        pos := sdl.Rect{20, 20, 800, 400};
        sdl.render_copy(renderer, texture, nil, &pos);

        pos.y = 500;
        pos.x = 100;

        sdl.query_texture(text_texture0, nil, nil, &pos.w, &pos.h);
        sdl.render_copy(renderer, text_texture0, nil, &pos);

        pos.y += pos.h + 20;
        sdl.query_texture(text_texture1, nil, nil, &pos.w, &pos.h);
        sdl.render_copy(renderer, text_texture1, nil, &pos);

        pos.y += pos.h + 20;
        sdl.query_texture(text_texture2, nil, nil, &pos.w, &pos.h);
        sdl.render_copy(renderer, text_texture2, nil, &pos);

        if input_state.rendered_input != nil {
            sdl.query_texture(input_state.rendered_input, nil, nil, &input_state.ui_pos.w, &input_state.ui_pos.h);
            sdl.render_copy(renderer, input_state.rendered_input, nil, &input_state.ui_pos);
        }
        if input_state.rendered_ime != nil {
            pos = input_state.ui_pos;
            pos.x += pos.w + 4;
            sdl.query_texture(input_state.rendered_ime, nil, nil, &pos.w, &pos.h);
            sdl.render_copy(renderer, input_state.rendered_ime, nil, &pos);
        }

        sdl.render_present(renderer);

        sdl.delay(100);
    }

    sdl.quit();
}

// does not allocate. Just slices the data up to the null terminator
as_string :: proc(data: []u8) -> string {
    // find the zero term
    z := 0;
    for b, i in data {
        if b == 0 {
            z = i;
            break;
        }
    }
    return string(data[:z]);
}

hsla :: proc(h, s, l: f64, a: f64 = 1) -> sdl.Color {
    r, g, b := float_hsl_to_rgb(h / 255.0, s / 100.0, l / 100.0);
    fmt.printf("hsl(%v, %v, %v) -> rgb(%v, %v, %v)\n", h, s, l, r, g, b);
    return sdl.Color {
        r = u8(int(r * 255)),
        g = u8(int(g * 255)),
        b = u8(int(b * 255)),
        a = u8(int(a * 255)),
    };
}

// taken from https://github.com/alessani/ColorConverter/blob/master/ColorSpaceUtilities.h
float_hsl_to_rgb :: proc(h: f64, s: f64, l: f64) -> (r: f64, g: f64, b: f64) {
    // Check for saturation. If there isn't any just return the luminance value for each, which results in gray.
    if s == 0.0 {
        return l, l, l;
    }

    temp2: f64;
    // Test for luminance and compute temporary values based on luminance and saturation
    if(l < 0.5) {
        temp2 = l * (1.0 + s);
    } else {
        temp2 = l + s - l * s;
    }
    temp1 := 2.0 * l - temp2;

    // Compute intermediate values based on hue
    temp := []f64{
        h + 1.0 / 3.0,
        h,
        h - 1.0 / 3.0,
    };

    for i in 0..<3 {
        // Adjust the range
        if(temp[i] < 0.0) {
            temp[i] += 1.0;
        }
        if(temp[i] > 1.0) {
            temp[i] -= 1.0;
        }

        if(6.0 * temp[i] < 1.0) {
            temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
        } else {
            if(2.0 * temp[i] < 1.0) {
                temp[i] = temp2;
            } else {
                if(3.0 * temp[i] < 2.0) {
                    temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
                } else {
                    temp[i] = temp1;
                }
            }
        }
    }

    return temp[0], temp[1], temp[2];
}
