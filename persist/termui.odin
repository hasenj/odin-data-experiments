package persist

import "core:fmt"
import "core:runtime"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"

IntType :: enum {
    unknown,
    i64,
    i32,
    i16,
    i8,
    u64,
    u32,
    u16,
    u8,
}

getIntType :: proc(signed: bool, size: int) -> IntType {
    if signed && size == 8 do return .i64;
    if signed && size == 4 do return .i32;
    if signed && size == 2 do return .i16;
    if signed && size == 1 do return .i8;
    if !signed && size == 8 do return .u64;
    if !signed && size == 4 do return .u32;
    if !signed && size == 2 do return .u16;
    if !signed && size == 1 do return .u8;
    return .unknown;
}

// this is just a demo for letting a user edit an object via the console!

SampleObject :: struct {
    name: string,
    job_title: string,
    birth_year: int,
    birth_month: int,
}


write_list :: proc(list: []$T, file: os.Handle) {
}

write_string :: proc(text: string, file: os.Handle) {
}

term_main :: proc() {
    person: SampleObject;
    person.name = "hasen";
    fmt.printf("address of our obect: %d\n", cast(rawptr)(&person));
    edit_object(&person);
    fmt.println("object now is:", person);
}

edit_object :: proc(obj: any) {
    // for now let it just list all the fields!
    fmt.println("Editing object:", obj);

    // expect a pointer to a struct, or the struct info to be in there somewhere!
    ptr : rawptr = obj.data;
    info := type_info_of(obj.id);
    struct_info: runtime.Type_Info_Struct;

    findloop: for {
        // fmt.println("type_info:", info.variant);
        switch v in info.variant {
            case runtime.Type_Info_Pointer:
                info = v.elem;
                ptr = (cast(^rawptr)ptr)^; // ptr was a pointer to a pointer; go inside!
            case runtime.Type_Info_Named:
                info = v.base;
            case runtime.Type_Info_Struct:
                struct_info = v;
                break findloop;
            case:
                fmt.println("unknown variant!", v);
                return;
        }
    }
    // fmt.println("type:", struct_info);
    fmt.printf("edit_object :: pointer is: %d\n", ptr);

    input := make([]byte, 20);
    for name, index in struct_info.names {
        type := struct_info.types[index];
        offset := struct_info.offsets[index];
        fieldPtr := rawptr(uintptr(ptr) + offset);
        // fmt.println("Field:", name, "\tType:", type);
        fmt.printf("%s> ", name);
        count, err := os.read(context.stdin, input);
        if err == 0 && count > 1 {
            userInput := string(input[:count-1]);
            // fmt.println("You want to assign", userInput, "to", name);
            dynamically_assign(fieldPtr, type, userInput);
        }
        fmt.println("object now is:", obj);
    }
}

dynamically_assign :: proc(ptr: rawptr, type: ^runtime.Type_Info, userInput: string) {
    switch t in type.variant {
        case runtime.Type_Info_Integer:
        // it = integer type
        it := getIntType(t.signed, type.size);
        switch it {
            case .i64:
            (cast(^i64)ptr)^ = strconv.parse_i64(userInput);
            case:
            fmt.println("Not supporting:", it);
        }
        case runtime.Type_Info_String:
        v:= cast(^string)ptr;
        v^ = strings.clone(userInput);
        case:
        fmt.println("we don't know how to assigned to", t);
    }
}


// -------------------------- TEST DATA ----------------------------------------
// -----------------------------------------------------------------------------


// Note: next step, make a structure that nests another structure and make it possible to serialize/deserialize

BlogRepo :: struct {
    users: [dynamic]User,
    user_auths: [dynamic]UserAuth,
    user_sessions: [dynamic]UserSession,
    posts: [dynamic]Post,
    comments: [dynamic]Comment,
}

UserType :: enum u8 {
    Anon = 0,
    User = 1,
    Admin = 2,
}

User :: struct {
    id: int,
    screen_name: string,
    type: UserType,
    email: string,
    bio: string,
}

UserAuth :: struct {
    user: ^User,
    hashed_password: string,
    email_confirmed: bool,
    email_token: string, // if email needs confirmation
}

UserSession :: struct {
    user: ^User,
    session_token: string,
}

Post :: struct {
    id: int,
    posted_by: ^User,
    title: string,
    content: string, // could be large? do we care? for now, no!
    time: string,
}

PostTag :: struct {
    id: int,
    tag: string,
    post: ^Post,
}


Comment :: struct {
    id: int,
    posted_by: ^User,
    posted_on: ^Post,
    time: string,
    parent_comment: ^Comment, // fragility point: parent comment must have a lower id, or else we have a problem! (it will be deserialized as nil)
}

