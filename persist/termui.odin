package persist

import "core:fmt"
import "core:runtime"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"

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
    person.name = "Hasen";
    person.job_title = "Programmer";
    person.birth_year = 1985;
    person.birth_month = 5;
    // fmt.printf("address of our object: %d\n", cast(rawptr)(&person));
    // edit_object(&person);

    fmt.println("object is:", person);
    buf := make([dynamic]byte);
    encode_object(&buf, person);
    fmt.println("Encoded to bytes:", buf);

    person2: SampleObject;
    person2.name = "something that will never be real";
    person2.birth_year = 4332;
    person2.birth_month = 523;
    fmt.println("new object:", person2);
    DecodeObject(&buf, person2);
    fmt.println("new object after decoding from buffer", person2);
}

Struct_Info :: struct {
    ptr: rawptr,
    info: runtime.Type_Info_Struct,
    type_name: string,
}

get_struct_info :: proc(obj: any) -> (Struct_Info, bool) {
    data: Struct_Info;
    data.ptr = obj.data;

    // generic typeinfo to use for looping
    info := type_info_of(obj.id);

    for {
        // fmt.println("type_info:", info.variant);
        switch v in info.variant {
            case runtime.Type_Info_Pointer:
                info = v.elem;
                data.ptr = (cast(^rawptr)data.ptr)^; // ptr was a pointer to a pointer; go inside!
            case runtime.Type_Info_Named:
                data.type_name = v.name;
                info = v.base;
            case runtime.Type_Info_Struct:
                data.info = v;
                return data, true;
            case:
                fmt.println("while looking for struct info, encountered an unknown variant: ", v);
                return Struct_Info{}, false;
        }
    }
    // should be unreachable
    return Struct_Info{}, false;
}

edit_object :: proc(obj: any) {
    // for now let it just list all the fields!
    fmt.println("Editing object:", obj);

    // expect a pointer to a struct, or the struct info to be in there somewhere!
    type_data, ok := get_struct_info(obj);
    if !ok {
        fmt.println("not a struct");
        return;
    }

    ptr := type_data.ptr;
    struct_info := type_data.info;

    input := make([]byte, 20);
    for name, index in struct_info.names {
        type := struct_info.types[index];
        offset := struct_info.offsets[index];
        fieldPtr := rawptr(uintptr(ptr) + offset);
        fieldValue := any{fieldPtr, type.id};
        // fmt.println("Field:", name, "\tType:", type);
        fmt.printf("%s> ", name);
        count, err := os.read(context.stdin, input);
        if err == 0 && count > 1 {
            userInput := string(input[:count-1]);
            // fmt.println("You want to assign", userInput, "to", name);
            assign_string(fieldValue, userInput);
        }
        fmt.println("object now is:", obj);
    }
}

assign_string :: proc(obj: any, input: string) {
    ptr := obj.data;
    switch it in obj {
        case int: (cast(^int)ptr)^ = strconv.parse_int(input);
        case uint: (cast(^uint)ptr)^ = strconv.parse_uint(input);
        case i64: (cast(^i64)ptr)^ = strconv.parse_i64(input);
        case u64: (cast(^u64)ptr)^ = strconv.parse_u64(input);
        case string: (cast(^string)ptr)^ = strings.clone(input);
        case: fmt.println("we don't know how to assigned a string to", obj);
    }
}

assign_i64 :: proc(obj: any, input: i64) {
    ptr := obj.data;
    switch it in obj {
        case i64: (cast(^i64)ptr)^ = input;
        case int: (cast(^int)ptr)^ = int(input);
        case u64: (cast(^u64)ptr)^ = u64(input);
        case uint: (cast(^uint)ptr)^ = uint(input);
        case string: (cast(^string)ptr)^ = i64_to_string(input);
        case: fmt.println("we don't know how to assigned i64 to", obj);
    }
}

assign_u64 :: proc(obj: any, input: u64) {
    ptr := obj.data;
    switch it in obj {
        case u64: (cast(^u64)ptr)^ = input;
        case uint: (cast(^uint)ptr)^ = uint(input);
        case i64: (cast(^i64)ptr)^ = i64(input);
        case int: (cast(^int)ptr)^ = int(input);
        case string: (cast(^string)ptr)^ = u64_to_string(input);
        case: fmt.println("we don't know how to assigned u64 to", obj);
    }
}

i64_to_string :: proc(x: i64) -> string {
    s := strings.make_builder();
    strings.write_i64(&s, x);
    return strings.to_string(s);
}

u64_to_string :: proc(x: u64) -> string {
    s := strings.make_builder();
    strings.write_u64(&s, x);
    return strings.to_string(s);
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

