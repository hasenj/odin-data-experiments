package gui

import sdl "shared:odin-sdl2"
import sdl_image "shared:odin-sdl2/image"
import sdl_ttf "shared:odin-sdl2/ttf"

import "core:mem"
import "core:strings"

main :: proc() {
    sdl.init(sdl.Init_Flags.Everything);
    window := sdl.create_window("Test window", i32(sdl.Window_Pos.Undefined), i32(sdl.Window_Pos.Undefined), 1024, 900, sdl.Window_Flags(0));
    renderer := sdl.create_renderer(window, -1, sdl.Renderer_Flags(0));

    sdl_image.init(sdl_image.Init_Flags.PNG);
    sdl_ttf.init();

    texture := sdl_image.load_texture(renderer, "images/img1.png");

    en_font := sdl_ttf.open_font("fonts/NotoSans-Medium.ttf", 90);
    ar_font := sdl_ttf.open_font("fonts/DroidNaskh-Regular.ttf", 90);
    jp_font := sdl_ttf.open_font("fonts/AiharaHudemojiKaisho2.01.ttf", 90);

    text_surface0 := sdl_ttf.render_utf8_blended(en_font, "odin-sdl2 now supports packages!", sdl.Color{157, 136, 221, 255});
    text_texture0 := sdl.create_texture_from_surface(renderer, text_surface0);
    sdl.free_surface(text_surface0);

    text : string = "كتابة عربية كلام عربي";
    text = shape(text);
    text = strings.reverse(text); // temporary until we get bidi
    ctext := strings.clone_to_cstring(text);
    text_surface1 := sdl_ttf.render_utf8_blended(ar_font, ctext, sdl.Color{157, 136, 221, 255});
    text_texture1 := sdl.create_texture_from_surface(renderer, text_surface1);
    sdl.free_surface(text_surface1);

    text_surface2 := sdl_ttf.render_utf8_blended(jp_font, strings.clone_to_cstring(strings.reverse("日本語でも出来ます！")), sdl.Color{157, 136, 221, 255});
    text_texture2 := sdl.create_texture_from_surface(renderer, text_surface2);
    sdl.free_surface(text_surface2);

    running := true;
    for running {
        e: sdl.Event;
        for sdl.poll_event(&e) != 0 {
            if e.type == sdl.Event_Type.Quit {
                running = false;
            }
        }
        sdl.set_render_draw_color(renderer, 0, 0, 0, 255);
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

        sdl.render_present(renderer);
    }

    sdl.quit();
}
