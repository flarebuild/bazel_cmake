#include <iostream>
#include <boost/uuid/uuid_io.hpp>   

#include <example/liba/liba.hpp>
#include <example/libb/libb.hpp>

int main() {
    std::cout << uuida() << std::endl;
    std::cout << uuidb() << std::endl;

    return 0;
}