# ResourceLibrary.cmake

This CMake module provides the function `add_resource_library`, which can be used to embed binary or text resource files into a static or shared library.

```CMake
add_resource_library(name <STATIC | SHARED> [file1] [file2 ...])
```

## How to use it

1. Copy [ResourceLibrary.cmake](ResourceLibrary.cmake) to a directory in your module path, e.g. *cmake*
2. Include it in your *CMakeLists.txt* using `include(ResourceLibrary)`
3. Define a resource library, either STATIC or SHARED, containing a list of files:
   ```CMake
   add_resource_library(ExampleResourceLibrary STATIC example.txt directory/example.png)
   ```
4. Add it to another target's link libraries:
   ```CMake
   target_link_libraries(ExampleTarget ExampleResourceLibrary)
   ```
5. Include the resource library's header file, with the same name as its target:
   ```C++
   #include<ExampleResourceLibrary.h>
   ```
   The resource library will then be available in a namespace containing functions for accessing the embedded resources:
   ```C++
   namespace ExampleResourceLibrary {
       const std::map<std::string, std::vector<std::uint8_t>>& resources();
       const std::vector<std::uint8_t>& resourceData(const std::string& resource_name);
       std::string resourceDataAsString(const std::string& resource_name);
       bool hasResource(const std::string& resource_name);
   }
   ```
   Use the file names passed to `add_resource_library` to identify a resource:
   ```C++
   std::string contents = ExampleResourceLibrary::resourceDataAsString("example.txt");
   ```

See the [example](example) directory for a minimal project using a resource library.

## How it works

Calling `add_resource_library` will create a library target and a series of custom commands, one to create the header file, one for each resource, and one for a loader file which contains the implementations of the functions above. These commands call [ResourceLibrary.cmake](ResourceLibrary.cmake) in script mode to generate the files.

The resource files are read, their contents are converted to byte-wise hex representation and then used as initializers for a `std::vector<std::uint8_t>`. These are stored in structs, along with their file names, and moved to a per-library `std::map` when the resource library is first used.
