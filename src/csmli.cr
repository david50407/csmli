module Csmli; end

require "./csmli/exception"
require "./csmli/*"

if argv = ARGV.shift?
  Csmli::Compiler.run File.open argv
else
  Csmli::Compiler.run STDIN
end

