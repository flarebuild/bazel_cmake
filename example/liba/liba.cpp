#include <boost/uuid/uuid_generators.hpp>
#include "liba.hpp"

boost::uuids::uuid uuida() {
    boost::uuids::random_generator generator;
    return generator();
}