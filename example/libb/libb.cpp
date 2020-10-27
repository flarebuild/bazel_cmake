#include <boost/uuid/uuid_generators.hpp>
#include "libb.hpp"

boost::uuids::uuid uuidb() {
    boost::uuids::random_generator generator;
    return generator();
}