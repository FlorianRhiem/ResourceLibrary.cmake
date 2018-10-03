cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

if (NOT CMAKE_ARGC)
    set(RESOURCE_LIBRARY_CMAKE_FILE "${CMAKE_CURRENT_LIST_FILE}")
    option(RESOURCE_LIBRARY_USE_ASM "ResourceLibrary.cmake uses assembly for embedding resources" OFF)
    enable_language(ASM)

    define_property(TARGET PROPERTY RESOURCES
        BRIEF_DOCS "Resource names specified for a resource library target."
        FULL_DOCS "List of resource names specified for a resource library target."
    )

    function(add_resource_library library_name library_type)
        set(library_h "${CMAKE_CURRENT_BINARY_DIR}/${library_name}/include/${library_name}.h")
        add_library(${library_name} ${library_type} ${library_h})
        set_property(TARGET ${library_name} PROPERTY CXX_STANDARD 11)
        set_property(TARGET ${library_name} PROPERTY RESOURCES "${ARGN}")
        file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${library_name}/include)
        file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${library_name}/src)
        target_include_directories(${library_name} PUBLIC ${CMAKE_CURRENT_BINARY_DIR}/${library_name}/include)

        # Generate targets for resource library header
        add_custom_command(OUTPUT "${library_h}"
            COMMAND ${CMAKE_COMMAND} -P "${RESOURCE_LIBRARY_CMAKE_FILE}" header "${library_h}" "${library_name}"
            COMMENT "Generating resource library '${library_name}' header"
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${library_name}
        )

        # Generate targets for resources
        set(resource_num "0")
        foreach(resource_file IN LISTS ARGN)
            if(IS_ABSOLUTE ${resource_file})
                set(resource_file_abspath "${resource_file}")
            else()
                set(resource_file_abspath "${CMAKE_CURRENT_LIST_DIR}/${resource_file}")
            endif()
            math(EXPR resource_num "${resource_num} + 1")
            if(RESOURCE_LIBRARY_USE_ASM)
                set(resource_file_asm "${CMAKE_CURRENT_BINARY_DIR}/${library_name}/src/${library_name}_${resource_num}.s")
                target_sources(${library_name} PRIVATE ${resource_file_asm})
                add_custom_command(OUTPUT "${resource_file_asm}"
                    COMMAND ${CMAKE_COMMAND} -P "${RESOURCE_LIBRARY_CMAKE_FILE}" resource_asm "${resource_file_asm}" "${library_name}" "${resource_num}" "${resource_file}" "${resource_file_abspath}" "${CMAKE_ASM_COMPILER_ID}"
                    COMMENT "Embedding resource '${resource_file}' in resource library '${library_name}'"
                    DEPENDS ${resource_file}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${library_name}
                )
            else()
                set(resource_file_cxx "${CMAKE_CURRENT_BINARY_DIR}/${library_name}/src/${library_name}_${resource_num}.cpp")
                target_sources(${library_name} PRIVATE ${resource_file_cxx})
                add_custom_command(OUTPUT "${resource_file_cxx}"
                    COMMAND ${CMAKE_COMMAND} -P "${RESOURCE_LIBRARY_CMAKE_FILE}" resource_cxx "${resource_file_cxx}" "${library_name}" "${resource_num}" "${resource_file}" "${resource_file_abspath}"
                    COMMENT "Embedding resource '${resource_file}' in resource library '${library_name}'"
                    DEPENDS ${resource_file}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${library_name}
                )
            endif()
        endforeach()

        # Generate target for resource library loader
        list(LENGTH ARGN max_resource_num)
        set(loader_cxx "${CMAKE_CURRENT_BINARY_DIR}/${library_name}/src/${library_name}_loader_${max_resource_num}.cpp")
        target_sources(${library_name} PRIVATE ${loader_cxx})
        add_custom_command(OUTPUT "${loader_cxx}"
            COMMAND ${CMAKE_COMMAND} -P "${RESOURCE_LIBRARY_CMAKE_FILE}" loader "${loader_cxx}" "${library_name}" "${max_resource_num}"
            COMMENT "Generating resource library '${library_name}' loader"
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${library_name}
        )
    endfunction()
else()
    if(${CMAKE_ARGV3} STREQUAL "header")
        # Generate resource library header
        set(library_h "${CMAKE_ARGV4}")
        set(library_name "${CMAKE_ARGV5}")
        string(CONCAT library_h_content
            "/* Resource Library '${library_name}' header */\n"
            "#ifndef ${library_name}_H_INCLUDED\n"
            "#define ${library_name}_H_INCLUDED\n"
            "#include <vector>\n"
            "#include <string>\n"
            "#include <map>\n"
            "#include <cstdint>\n"
            "\n"
            "namespace ${library_name} {\n"
            "    const std::map<std::string, std::vector<std::uint8_t> >& resources();\n"
            "    const std::vector<std::uint8_t>& resourceData(const std::string& resource_name);\n"
            "    std::string resourceDataAsString(const std::string& resource_name);\n"
            "    bool hasResource(const std::string& resource_name);\n"
            "}\n"
            "#endif\n"
        )
        file(WRITE ${library_h} "${library_h_content}")
    elseif (${CMAKE_ARGV3} STREQUAL "resource_cxx")
        # Generate resource
        set(resource_file_cxx "${CMAKE_ARGV4}")
        set(library_name "${CMAKE_ARGV5}")
        set(resource_num "${CMAKE_ARGV6}")
        set(resource_file "${CMAKE_ARGV7}")
        set(resource_file_abspath "${CMAKE_ARGV8}")
        file(READ ${resource_file_abspath} resource_data HEX)
        string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1," resource_data ${resource_data})
        string(CONCAT resource_file_cxx_content
            "/* Resource Library '${library_name}' resource */\n"
            "\n"
            "char ${library_name}_resource_${resource_num}_name[] = \"${resource_file}\";\n"
            "unsigned char ${library_name}_resource_${resource_num}_data[] = {${resource_data}};\n"
            "unsigned int ${library_name}_resource_${resource_num}_size = sizeof(${library_name}_resource_${resource_num}_data);\n"
        )
        file(WRITE ${resource_file_cxx} "${resource_file_cxx_content}")
    elseif (${CMAKE_ARGV3} STREQUAL "resource_asm")
        # Generate resource
        set(resource_file_asm "${CMAKE_ARGV4}")
        set(library_name "${CMAKE_ARGV5}")
        set(resource_num "${CMAKE_ARGV6}")
        set(resource_file "${CMAKE_ARGV7}")
        set(resource_file_abspath "${CMAKE_ARGV8}")
        set(compiler_id "${CMAKE_ARGV9}")
        if(compiler_id STREQUAL "AppleClang")
            string(CONCAT resource_file_asm_content
                ".section __DATA,__data\n"
                ".global _${library_name}_resource_${resource_num}_name\n"
                ".align  4\n"
                "_${library_name}_resource_${resource_num}_name:\n"
                ".string \"${resource_file}\"\n"
                ".global _${library_name}_resource_${resource_num}_data\n"
                ".align  4\n"
                "_${library_name}_resource_${resource_num}_data:\n"
                ".incbin \"${resource_file_abspath}\"\n"
                "data_end:\n"
                ".global _${library_name}_resource_${resource_num}_size\n"
                ".align  4\n"
                "_${library_name}_resource_${resource_num}_size:\n"
                ".int    data_end - _${library_name}_resource_${resource_num}_data\n"
            )
        else()
            string(CONCAT resource_file_asm_content
                ".section .rodata\n"
                ".global ${library_name}_resource_${resource_num}_name\n"
                ".align  4\n"
                "${library_name}_resource_${resource_num}_name:\n"
                ".string \"${resource_file}\"\n"
                ".global ${library_name}_resource_${resource_num}_data\n"
                ".align  4\n"
                "${library_name}_resource_${resource_num}_data:\n"
                ".incbin \"${resource_file_abspath}\"\n"
                "data_end:\n"
                ".global ${library_name}_resource_${resource_num}_size\n"
                ".align  4\n"
                "${library_name}_resource_${resource_num}_size:\n"
                ".int    data_end - ${library_name}_resource_${resource_num}_data\n"
            )
        endif()
        file(WRITE ${resource_file_asm} "${resource_file_asm_content}")
    elseif(${CMAKE_ARGV3} STREQUAL "loader")
        # Generate resource library loader
        set(loader_cxx "${CMAKE_ARGV4}")
        set(library_name "${CMAKE_ARGV5}")
        set(max_resource_num "${CMAKE_ARGV6}")
        string(CONCAT loader_cxx_content
            "/* Resource Library '${library_name}' loader */\n"
            "#include <vector>\n"
            "#include <string>\n"
            "#include <map>\n"
            "#include <cstdint>\n"
            "\n"
        )
        foreach(resource_num RANGE 1 ${max_resource_num})
            string(CONCAT loader_cxx_content
                "${loader_cxx_content}"
                    "    extern char ${library_name}_resource_${resource_num}_name[];\n"
                    "    extern unsigned char ${library_name}_resource_${resource_num}_data[];\n"
                    "    extern unsigned int ${library_name}_resource_${resource_num}_size;\n"
            )
        endforeach()
        string(CONCAT loader_cxx_content
            "${loader_cxx_content}"
            "namespace ${library_name} {\n"
            "    const std::map<std::string, std::vector<std::uint8_t>>& resources() {\n"
            "        static std::map<std::string, std::vector<std::uint8_t>> resources;\n"
            "        if (!resources.empty()) {\n"
            "            return resources;\n"
            "        }\n"
        )
        foreach(resource_num RANGE 1 ${max_resource_num})
            string(CONCAT loader_cxx_content
                "${loader_cxx_content}"
                "        resources[std::string(${library_name}_resource_${resource_num}_name)] = {${library_name}_resource_${resource_num}_data, ${library_name}_resource_${resource_num}_data+${library_name}_resource_${resource_num}_size};\n"
            )
        endforeach()
        string(CONCAT loader_cxx_content
            "${loader_cxx_content}"
            "        return resources;\n"
            "    }\n"
            "    const std::vector<std::uint8_t>& resourceData(const std::string& resource_name) {\n"
            "        return resources().at(resource_name);\n"
            "    }\n"
            "    std::string resourceDataAsString(const std::string& resource_name) {\n"
            "        const auto& resource_data = resources().at(resource_name);\n"
            "        return std::string(resource_data.begin(), resource_data.end());\n"
            "    }\n"
            "    bool hasResource(const std::string& resource_name) {\n"
            "        return resources().find(resource_name) != resources().end();\n"
            "    }\n"
            "}\n"
        )
        file(WRITE ${loader_cxx} "${loader_cxx_content}")
    endif()
endif()
