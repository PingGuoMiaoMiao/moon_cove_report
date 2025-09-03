import test_parser
import test_serializer
import test_merger
import test_query
import test_visualize

fn main() {
  println("Running MoonCove Tests")
  println("======================")
  
  test_parser::run_tests()
  test_serializer::run_tests()
  test_merger::run_tests()
  test_query::run_tests()
  test_visualize::run_tests()
  
  println("\nAll tests completed")
}