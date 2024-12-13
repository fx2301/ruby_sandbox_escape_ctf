require 'parser/current'
require 'json'

class SandboxException < StandardError; end;

def assert_code_allowed(code, debug=false)
  begin
    parser = Parser::CurrentRuby.new
    parser.diagnostics.consumer = lambda do |diag|
      # Suppress parse errors
    end

    expr = parser.parse(Parser::Source::Buffer.new('(string)', source: code))

    assert_node_allowed(expr, debug=debug)
  rescue Parser::SyntaxError => e
    # Suppress parse exceptions
  end
end

CODE_EVAL = [:eval, :load, :module_eval, :class_eval, :instance_eval, :require, :require_relative, :autoload, :restore, :start]
SYSTEM_CALL = [:open, :exec, :system, :spawn, :popen, :capture2, :pipeline_rw, :pipeline_r, :pipeline_w, :pipeline_start, :pipeline, :popen3, :popen2, :popen2e, :capture2e, :capture3]
BYPASSES = [:alias_method, :method, :to_proc, :instance_method, :bind_call, :irb, :syscall, :pry]

ERROR_SYSTEM_COMMANDS = "System commands are not allowed. Use pure Ruby code instead."
ERROR_META_PROGRAMMING = "Introspection and metaprogramming calls are limited. Use direct method calls instead."
ERROR_DYNAMIC_METHOD_CALLS = "Dynamic method callingThanks! I've patched the code to catch this. See if you can find another! not allowed. Use a symbol for the method you need to call."
ERROR_CODE_EVALUATION = "Dynamic code evaluation not allowed. Use code that can be statically determined to be safe."

def assert_node_allowed(expr, debug=false)
  return if expr.nil?
  
  concise = "#{expr}".gsub(/\s+/, ' ')
  puts(">> #{concise}") if debug
  
  if expr.type == :xstr
    # Backticks are system calls
    raise SandboxException.new ERROR_SYSTEM_COMMANDS
  elsif expr.type == :alias
    raise SandboxException.new ERROR_META_PROGRAMMING
  elsif expr.type == :send
    if concise.start_with?("(send (const nil :File) :open ")
      # Allow reads of hardcoded file names
    elsif concise.start_with?("(send (const nil :CSV) :open ")
      # Allow calls to CSV.open
    elsif concise.start_with?("(send (const nil :YAML) :load ")
      # Allow YAML.load
    else
      method = expr.children[1]
      assert_method_allowed(method)
      
      if expr.children.size >= 3
        arg_1 = expr.children[2]

        if simplify_expression(method) == :send
          assert_method_allowed(arg_1)
        end
      end
    end
  end

  if expr.respond_to?(:children)
    expr.children.each do |expr|
      if expr.instance_of?(::Parser::AST::Node)  
        assert_node_allowed(expr, debug=debug)
      end
    end
  end

  return
end

def assert_method_allowed(method_expr)
  if complex_expression?(method_expr)
    raise SandboxException.new ERROR_DYNAMIC_METHOD_CALLS
  end
  method_simple = simplify_expression(method_expr)
  if CODE_EVAL.include?(method_simple)
    raise SandboxException.new ERROR_CODE_EVALUATION
  elsif SYSTEM_CALL.include?(method_simple)
    raise SandboxException.new ERROR_SYSTEM_COMMANDS
  elsif BYPASSES.include?(method_simple)
    raise SandboxException.new ERROR_META_PROGRAMMING
  end
end

def complex_expression?(expr)
  if expr.instance_of?(::Parser::AST::Node)
    return false if expr.type == :sym
    return false if expr.type == :str && !expr.children[0].include?("#")
    return true 
  end
  return false
end

def simplify_expression(expr)
  if expr.instance_of?(Symbol)
    value = expr
  elsif expr.instance_of?(String)
    value = expr.to_sym 
  elsif expr.type == :str
    value = expr.children[0].to_sym
  elsif expr.type == :sym
    value = expr.children[0]
  else
    raise "Cannot simplify: #{expr}"
  end

  value = :send if value == :public_send || value == :__send__

  return value
end

# codes = JSON.parse(File.read('code_reject.json'))
# codes.each_with_index do |code, i|
#   begin
#     assert_code_allowed(code, debug=false)

#     puts "#{i+1}: Expected code to be rejected:\n#{code}"
#     assert_code_allowed(code, debug=true)
#     exit(0)
#   rescue SandboxException
#   end
# end

# codes = JSON.parse(File.read('code_accept.json'))
# codes.each_with_index do |code, i|
#   begin
#     assert_code_allowed(code, debug=false)
#   rescue SandboxException
#     puts "#{i+1}: Expected code to be accepted:\n#{code}"
#     begin
#       assert_code_allowed(code, debug=true)
#     rescue
#     end
#     exit(0)
#   end
# end
