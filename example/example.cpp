#include <iostream>
#include "ExampleResourceLibrary.h"

int main() {
    if (ExampleResourceLibrary::hasResource("example.txt")) {
      std::cout << "Content of example.txt:" << std::endl;
      std::cout << ExampleResourceLibrary::resourceDataAsString("example.txt") << std::endl;
    }
    return 0;
}
