# ResourceLibrary.cmake

[![pipeline status](https://gitlab.com/florianrhiem/resourcelibrary.cmake/badges/master/pipeline.svg)](https://gitlab.com/florianrhiem/resourcelibrary.cmake/pipelines?scope=branches)
[![CMake 3.1+ required](https://img.shields.io/badge/cmake-3.1%2B-blue.svg)](ResourceLibrary.cmake#L1)
[![MIT license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)


This CMake module provides the function `add_resource_library`, which can be used to embed binary or text resource files into a static or shared library.

```CMake
add_resource_library(name <STATIC | SHARED> [file1] [file2 ...])
```

## How to use it

1. Copy [ResourceLibrary.cmake](ResourceLibrary.cmake) to a directory in your module path, e.g. *cmake*
2. Include it in your *CMakeLists.txt* using `include(ResourceLibrary)`
3. (Optional) When using GCC, Clang or Apple Clang, set `RESOURCE_LIBRARY_USE_ASM` to `On` (see *How it works* below)
4. Define a resource library, either STATIC or SHARED, containing a list of files:
   ```CMake
   add_resource_library(ExampleResourceLibrary STATIC example.txt directory/example.png)
   ```
5. Add it to another target's link libraries:
   ```CMake
   target_link_libraries(ExampleTarget ExampleResourceLibrary)
   ```
6. Include the resource library's header file, with the same name as its target:
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

By default, the contents of the resource files are converted to byte-wise hex representation and then used as initializers for `unsigned char` arrays. When the CMake option `RESOURCE_LIBRARY_USE_ASM` is set to `On`, the resources are directly included in x86 assembly files using `.incbin`. In both cases, the arrays are used to create a `std::vector<std::uint8_t>` for each resource in a per-library `std::map` once the resource library is first used.
