package persist

import "core:os"
import "core:runtime"
import "core:fmt"
import "core:math/bits"
import "core:mem"

TableNo :: int; // basically an index
RowNo :: int; // also an index

Table :: struct {
    type: typeid, // odin type
    name: string, // unique name within the db
    dependencies: []TableNo, // tables referred to by this table

    // fields
    fields: []int, // field index in the Type_Info_Struct of the type

    idMap: map[int]RowNo, // maps 'id' value to an index in the table
    maxId: int,
}

Header :: struct {
    tables: []Table, // tablid is an index into this array
    tablesMap: map[typeid]TableNo,
    ordering: []TableNo, // which tables to serialize/deserialize first so we don't have to do complex dependency checks!
}

make_header :: proc(repoType: typeid) -> ^Header {
    // build a dependency graph and build the tables list so each table has its dependencies before it!
    // this is important so that when we deserialize the data we don't have any recursive back-and-forth.
    // or maybe it doesn't matter - maybe move this logic to the deserialization part? or create another array that is a list of numbers
    h := new(Header);

    // assuming T is a struct that contains only arrays of structs, iterate over its fields and generate a Table for each field that is an array of structs
    baseType := runtime.type_info_base(type_info_of(repoType));
    struct_info, ok := baseType.variant.(runtime.Type_Info_Struct);
    if !ok {
        fmt.println("error: type is not a struct", repoType);
        return nil;
    }
    // TODO!

    return h;
}

encode :: proc(repo: any, filename: string) {
    // TODO!
    header := make_header(repo.id);
    fmt.println("Header:", header);
}

decode :: proc(repo: any, filename: string) {
    // TODO!
}

// test!

enc_main :: proc() {
    repo: BlogRepo;
    append(&repo.users, User{id = 1, screen_name = "hasen", type = .Admin});
    fmt.println("Repo:");
    fmt.println(repo);
    encode(repo, "blog.repo");

    // decode!
    repo2: BlogRepo;
    decode(repo2, "blog.repo");
    fmt.println("Repo2:");
    fmt.println(repo2);
}

// some magic values
Markers :: enum byte {
    Object,
    Field,

    // values
    NoValue, // hack to simplify the encoding loop
    BoolValue,
    IntValue,
    UintValue,
    StringValue,
}

get_field :: proc(ptr: rawptr, tinfo: runtime.Type_Info_Struct, index: int) -> any {
    type := tinfo.types[index];
    offset := tinfo.offsets[index];
    fieldPtr := rawptr(uintptr(ptr) + offset);
    return any{fieldPtr, type.id};
}

encode_object :: proc(out: ^[dynamic]byte, obj: any) {
    struct_info, ok := get_struct_info(obj);
    if !ok {
        fmt.println("not a struct");
        return;
    }
    append(out, byte(Markers.Object));
    encode_string(out, struct_info.type_name);
    tinfo := struct_info.info;
    for name, index in tinfo.names {
        field := get_field(struct_info.ptr, tinfo, index);
        // TODO: maybe we need a function that returns an array of 'any' for the object so that it can do things like recurse into structs (not pointers)
        append(out, byte(Markers.Field));
        encode_string(out, name);
        switch v in field {
            case int:
                append(out, byte(Markers.IntValue));
                encode_i64(out, i64(v));
            case uint:
                append(out, byte(Markers.UintValue));
                encode_u64(out, u64(v));
            case bool:
                append(out, byte(Markers.BoolValue));
                append(out, byte(v));
            case string:
                append(out, byte(Markers.StringValue));
                encode_string(out, v);
            case []byte:
                append(out, byte(Markers.StringValue));
                encode_bytes(out, v);
            case:
                ref_id, ok := get_object_id(v);
                if ok {
                    append(out, byte(Markers.IntValue));
                    encode_i64(out, i64(ref_id));
                } else {
                    append(out, byte(Markers.NoValue)); // kind of a hack actually
                }
        }
    }
}

get_object_id :: proc(obj_: any) -> (int, bool) {
    // simplify: assume the first field is the id field
    // if it's an int, encode it.
    // if it's a pointer, let _that_ print its id
    obj := obj_;
    for {
        info, ok := get_struct_info(obj);
        if !ok {
            return 0, false;
        }
        id_field := get_field(info.ptr, info.info, 0);
        switch id in id_field {
            case int:
                return id, true;
            case:
                obj = id_field; // and continue the loop!
        }
    }
    // should not be reachable ..
    return 0, false;
}

encode_string :: proc(out: ^[dynamic]byte, t: string) {
    encode_bytes(out, cast([]byte)(t));
}

encode_bytes :: proc(out: ^[dynamic]byte, t: []byte) {
    encode_i64(out, i64(len(t)));
    append(out, ..t);
}

le_i64 :: proc(i: i64) -> i64 { when os.ENDIAN == "little" { return i; } else { return bits.byte_swap(i); } }
le_u64 :: proc(i: u64) -> u64 { when os.ENDIAN == "little" { return i; } else { return bits.byte_swap(i); } }

encode_i64 :: proc(out: ^[dynamic]byte, v: i64) {
    // write the bytes in little endian order
    v := le_i64(v);
    // copy the bytes to a local variable .. might be a superfluous step but I think it adds clarity. Might be removed later.
    N :: size_of(v);
    b: [N]byte;
    mem.copy(&b, &v, N);
    append(out, ..b[:]);
}

encode_u64 :: proc(out: ^[dynamic]byte, v: u64) {
    // write the bytes in little endian order
    v := le_u64(v);
    // copy the bytes to a local variable .. might be a superfluous step but I think it adds clarity. Might be removed later.
    N :: size_of(v);
    b: [N]byte;
    mem.copy(&b, &v, N);
    append(out, ..b[:]);
}

