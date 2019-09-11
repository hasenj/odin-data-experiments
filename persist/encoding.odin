package persist

import "core:runtime"
import "core:fmt"

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
