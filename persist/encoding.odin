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
    // build a dependency graph and build the tables list so each table has its
    // dependencies before it!  this is important so that when we deserialize
    // the data we don't have any recursive back-and-forth.  or maybe it
    // doesn't matter - maybe move this logic to the deserialization part? or
    // create another array that is a list of numbers
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

DumpMemory :: proc(list: []byte) {
    fmt.printf("memory dump of: %v with %d elements\n", mem.raw_data(list), len(list));
    per_line :: 6;
    for index := 0; index < len(list); index += per_line {
        fmt.printf("%x: ", &list[index]);
        end := index + per_line;
        if end > len(list) {
            end = len(list);
        }
        for j := index; j < end; j+= 1 {
            fmt.printf("%x ", list[j]);
        }
        // in case this is the last line, append some extra space for the missing items
        if index + per_line > end {
            for j := end; j < index + per_line; j += 1 {
                fmt.print("   ");
            }
        }
        fmt.printf("  ");
        for j := index; j < end; j+= 1 {
            fmt.printf("%8b ", list[j]);
        }
        fmt.println();
    }
    fmt.println("----------");
    fmt.println(cast(string)list);
    fmt.println("End of memory dump");
}

Struct_Info :: struct {
    ptr: rawptr,
    info: runtime.Type_Info_Struct,
    type_name: string,
}

GetStructInfo :: proc(obj: any) -> (Struct_Info, bool) {
    data: Struct_Info;
    data.ptr = obj.data;

    // generic typeinfo to use for looping
    info := type_info_of(obj.id);

    for {
        // fmt.println("type_info:", info.variant);
        switch v in info.variant {
            case runtime.Type_Info_Pointer:
                info = v.elem;
                // ptr was a pointer to a pointer; go inside!
                data.ptr = (cast(^rawptr)data.ptr)^;
            case runtime.Type_Info_Named:
                data.type_name = v.name;
                info = v.base;
            case runtime.Type_Info_Struct:
                data.info = v;
                return data, true;
            case:
                fmt.println("while looking for struct info, encountered an type unknown variant: ", v);
                return Struct_Info{}, false;
        }
    }
    // should be unreachable
    return Struct_Info{}, false;
}


GetField :: proc(ptr: rawptr, tinfo: runtime.Type_Info_Struct, index: int) -> any {
    type := tinfo.types[index];
    offset := tinfo.offsets[index];
    fieldPtr := rawptr(uintptr(ptr) + offset);
    return any{fieldPtr, type.id};
}

GetFieldByName :: proc(ptr: rawptr, tinfo: runtime.Type_Info_Struct, name: string) -> any {
    for fname, findex in tinfo.names {
        if fname == name {
            return GetField(ptr, tinfo, findex);
        }
    }
    return nil;
}

// some magic values
Marker :: enum byte {
    Object = 1,
    Field,

    // values
    NoValue, // hack to simplify the encoding loop
    BoolValue,
    IntValue,
    UintValue,
    StringValue,
}

WriteBuffer :: [dynamic]byte;
ReadBuffer :: []byte;

List_Info :: struct {
    element_type: ^runtime.Type_Info,
    element_size: int,
    array_size: int,
    array_head: rawptr,
    element_type_name: string,
}

GetListInfo :: proc(list: any) -> (List_Info, bool) {
    data: List_Info;
    ptr: rawptr = list.data;
    info := type_info_of(list.id);

    // allow one level of pointer
    if ptr_info, ok := info.variant.(runtime.Type_Info_Pointer); ok {
        ptr = (cast(^rawptr)ptr)^; // was pointer to pointer, so go one level deeper
        info = ptr_info.elem;
    }

    switch v in info.variant {
        case runtime.Type_Info_Array:
            data.element_type = v.elem;
            data.element_size = v.elem_size;
            data.array_head = ptr;
            data.array_size = v.count;
        case runtime.Type_Info_Slice:
            arr := cast(^mem.Raw_Slice)ptr;
            data.element_type = v.elem;
            data.element_size = v.elem_size;
            data.array_size = arr.len;
            data.array_head = arr.data;
        case runtime.Type_Info_Dynamic_Array:
            arr := cast(^mem.Raw_Dynamic_Array)ptr;
            data.element_type = v.elem;
            data.element_size = v.elem_size;
            data.array_size = arr.len;
            data.array_head = arr.data;
        case:
            fmt.println("while looking for list info, encountered an unknown type variant: ", v);
            return data, false;
    }

    // we expect the element type to have a name!
    named, ok := data.element_type.variant.(runtime.Type_Info_Named);
    if !ok {
        fmt.println("name not provided!!!");
        return data, false;
    }
    data.element_type_name = named.name;
    data.element_type = named.base;
    if _, ok := data.element_type.variant.(runtime.Type_Info_Struct); !ok {
        fmt.println("array element is not a struct! can't handle");
        return data, false;
    }

    return data, true;
}

EncodeList :: proc(out: ^WriteBuffer, list: any) {
    // get the type name!
    info, ok := GetListInfo(list);
    if !ok {
        fmt.println("not a list");
        return;
    }
    if info.array_size == 0 {
        // nothing to encode!!
        fmt.println("empty array, nothing to encode");
        return;
    }

    fmt.println("list info:", info);
    b: object_marker;
    b.type = marker_type.object;
    b.name_length = len(info.element_type_name);
    fmt.printf("object_marker: %v 0b%8b\n", b, transmute(byte)b);
    append(out, transmute(byte)b);
    append(out, ..(cast([]byte)(info.element_type_name)));

    /*
    WriteListMarker(type_name);
    WriteInt(fields_count);
    for index in 0..< fields_count {
        WriteTypeMarker(field_encoding_type, field_name);
    }
    WriteObjectsMarker(objects_count);
    for object_index in 0 ..< objects_count {
        for field_index in 0 ..< fields_count {
        }
    }
    */
}


encode_object :: proc(out: ^[dynamic]byte, obj: any) {
    struct_info, ok := GetStructInfo(obj);
    if !ok {
        fmt.println("not a struct");
        return;
    }
    append(out, byte(Marker.Object));
    encode_string(out, struct_info.type_name);
    tinfo := struct_info.info;
    for name, index in tinfo.names {
        field := GetField(struct_info.ptr, tinfo, index);
        // TODO: maybe we need a function that returns an array of 'any' for
        // the object so that it can do things like recurse into structs (not
        // pointers)
        append(out, byte(Marker.Field));
        encode_string(out, name);
        switch v in field {
            case int:
                append(out, byte(Marker.IntValue));
                encode_i64(out, i64(v));
            case uint:
                append(out, byte(Marker.UintValue));
                encode_u64(out, u64(v));
            case bool:
                append(out, byte(Marker.BoolValue));
                append(out, byte(v));
            case string:
                append(out, byte(Marker.StringValue));
                encode_string(out, v);
            case []byte:
                append(out, byte(Marker.StringValue));
                encode_bytes(out, v);
            case:
                ref_id, ok := get_object_id(v);
                if ok {
                    append(out, byte(Marker.IntValue));
                    encode_i64(out, i64(ref_id));
                } else {
                    append(out, byte(Marker.NoValue)); // kind of a hack actually
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
        info, ok := GetStructInfo(obj);
        if !ok {
            return 0, false;
        }
        id_field := GetField(info.ptr, info.info, 0);
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

le_i64 :: proc(i: i64) -> i64 {
    when os.ENDIAN == "little" { return i; } else { return bits.byte_swap(i); }
}
le_u64 :: proc(i: u64) -> u64 {
    when os.ENDIAN == "little" { return i; } else { return bits.byte_swap(i); }
}

encode_i64 :: proc(out: ^[dynamic]byte, v: i64) {
    // write the bytes in little endian order
    v := le_i64(v);
    // copy the bytes to a local variable .. might be a superfluous step but I
    // think it adds clarity. Might be removed later.
    N :: size_of(v);
    b: [N]byte;
    mem.copy(&b, &v, N);
    append(out, ..b[:]);
}

encode_u64 :: proc(out: ^[dynamic]byte, v: u64) {
    // write the bytes in little endian order
    v := le_u64(v);
    // copy the bytes to a local variable .. might be a superfluous step but I
    // think it adds clarity. Might be removed later.
    N :: size_of(v);
    b: [N]byte;
    mem.copy(&b, &v, N);
    append(out, ..b[:]);
}

// ---- decoding

scanner :: struct(T: typeid) {
    buffer: []T,
    cursor: int,
}

AtEnd :: proc(sc: ^scanner($T)) -> bool {
    return sc.cursor >= len(sc.buffer);
}

ReadOne :: proc(sc: ^scanner($T)) -> (out: T) {
    if sc.cursor >= len(sc.buffer) {
        return;
    }
    out = sc.buffer[sc.cursor];
    sc.cursor += 1;
    return;
}

ReadN :: proc(sc: ^scanner($T), count: int) -> []T {
    start := sc.cursor;
    end := start + count;
    if end > len(sc.buffer) do end = len(sc.buffer);
    sc.cursor = end;
    return sc.buffer[start:end];
}

ReadByte :: proc(sc: ^scanner(byte)) -> byte {
    return ReadOne(sc);
}

ReadBytes :: proc(sc: ^scanner(byte), count: int) -> []byte {
    return ReadN(sc, count);
}

ReadMarker :: proc(sc: ^scanner(byte)) -> Marker {
    return Marker(ReadByte(sc));
}

/*DecodeValue :: proc(sc: ^scanner(byte)) -> any {
    // TODO
    return nil;
}
*/

field_type :: enum u8 {
    Int, // all signed integer types
    Uint, // all unsigned integer types, and bools
    Bytes, // []byte or string
    Chunked, // for large []byte or string ( > 4k)
}

type_encoding :: struct {
    // fields
    names: []string,
    types: []field_type,
}

// must fit into two bits!
marker_type :: enum u8 {
    object = 1,
    field = 2,
}

field_marker :: bit_field {
    type: 2,
    index: 4, // the field index in the []field_type array
    bytes: 2, // how many bytes are used for encoding (only if type is number)
}

object_marker :: bit_field {
    type: 2,
    name_length: 6,
}

decoder :: struct {
    types: map[string]type_encoding
}


DecodeObject :: proc(buf: ReadBuffer, obj: any) -> bool {
    fmt.println("DECODING: TODO!");
    sc := scanner(byte){buffer = buf};
    b := ReadMarker(&sc);
    if b != .Object {
        fmt.println("DBG:", "not an object!!");
        return false;
    }
    name := DecodeString(&sc);
    fmt.println("type name:", name);
    target, targetOk := GetStructInfo(obj);
    for !AtEnd(&sc) {
        b := ReadMarker(&sc);
        // boundary conditions
        if b == .Object {
            fmt.println("DBG:", "object boundary! it's the end!");
            return true;
        }
        if b != .Field {
            fmt.println("DBG:", "not a field! can't handle!");
            return false;
        }
        // good, now let's get the field name
        name := DecodeString(&sc);
        fmt.println("field name:", name);

        // find the field
        field: any;
        if targetOk do field = GetFieldByName(target.ptr, target.info, name);

        // now, decode the value!!!
        vm := ReadMarker(&sc);
        switch vm {
            case .NoValue: continue;
            case .BoolValue:
                // TODO simplify the error handling?
                v := ReadBool(&sc);
                fmt.println("field value:", v);
                if field != nil do assign_b8(v, field);
            case .IntValue:
                v := ReadInt(&sc);
                fmt.println("field value:", v);
                // TODO: if the field is a pointer we should get the pointed
                // item from the report hosting the type!!
                if field != nil do assign_i64(v, field);
            case .UintValue:
                v := ReadUint(&sc);
                fmt.println("field value:", v);
                if field != nil do assign_u64(v, field);
            case .StringValue:
                v := DecodeString(&sc);
                fmt.println("field value:", v);
                if field != nil do assign_string(v, field);
            case:
                fmt.println("unknown value marker", vm);
        }
    }
    return true;
}

ReadT :: proc(sc: ^scanner(byte), $T: typeid) -> T {
    n :: size_of(T);
    b := ReadBytes(sc, n);
    out: T;
    mem.copy(&out, &b[0], n);
    fmt.printf("Read %v :: %v -> %v\n", typeid_of(T), b, out);
    return out;
}

ReadInt :: inline proc(sc: ^scanner(byte)) -> i64 {
    return ReadT(sc, i64);
}

ReadUint :: inline proc(sc: ^scanner(byte)) -> u64 {
    return ReadT(sc, u64);
}

ReadBool :: inline proc(sc: ^scanner(byte)) -> b8 {
    return b8(ReadT(sc, byte));
}

DecodeString :: proc(sc: ^scanner(byte)) -> string {
    n := ReadInt(sc);
    buf := ReadBytes(sc, int(n));
    out := make([]byte, n);
    copy(out, buf);
    return string(out);
}

AssignNamedValue :: proc(name: string, value: any, target: any) -> bool {
    // TODO!
    fmt.println("Assigning", value, "to field:", name);
    return true;
}



/*
    current method is robust but wasteful. should we improve it now or improve it later?
    if we improve it now we might just be hitting our head against the wall
    if we defer improvement for later we might suffer a bit later but also we
    can get progress on other aspects

    encoding scheme:
        object marker
        object type name
        fields_count: int
        [field_type, name_bytes_count, name_bytes] -> field type and name
        elements_count: int -> how many items of this object are present
        field_index
        field_value
        separator marker
        repeat until we finish all elements of this type
        repeat until we finish all types

    would this lend itself nicely or poorly for network synchronization?
    would this lend itself nicely or poorly for schema changes?
    would this lend itself nicely or poorly if two different nodes have
    slightly different schemas? (from running a different version)

*/


