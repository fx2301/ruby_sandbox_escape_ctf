require './check'

REJECTION_CASES = '''
exec("ls")
system("ls")
open("|ls")
IO.popen("ls")
require "open3"; Open3.capture3("ls")
spawn("ls")
%x{ls}
PTY.spawn("ls")
Object.open("|ls")
Kernel.open("|ls")
`ls`
eval("`ls`")
f = "|ls"; open(f)
Object.send(:open, "|ls")
Object.send("open", "|ls")
m = :open; Object.send(m, "|ls")
Object.send("op"+"en", "|ls")
Object.send("#{:open}", "|ls")
Object.public_send(:open, "|ls")
String.open("|ls")
Object.method(:open).call("|ls")
Object.method(:open)["|ls"]
Object.alias_method(:foobar, :open); Object.send(:foobar, "|ls")
:send.to_proc.call(Object, :open, "|ls")
["|ls"].map(&Object.method(:open))
def Object.foobaz(path); self.open(path); end; Object.foobaz("|ls")
Object.class_eval \'open("|ls")\'
Object.module_eval \'open("|ls")\'
Object.new.instance_eval \'open("|ls")\'
Object.instance_method(:open).bind_call(Object, "|ls")
require "fiddle"; libc = Fiddle.dlopen("/lib/x86_64-linux-gnu/libc.so.6"); # ...snip...
File.write("./hack.rb", "puts open(\'|ls\').read()"); load "./hack.rb"
File.write("./hack.rb", "puts open(\'|ls\').read()"); autoload :Foo, "./hack.rb"; Foo.new
File.write("./hack.rb", "puts open(\'|ls\').read()"); require_relative "hack.rb"
Kernel.syscall(0) # syscall, ", profit!
binding.irb # a fresh IRB session!
'''.split("\n").reject { |line| line.strip.size == 0 }

# TODO: IO::Buffer.new(8) # mmap, ?, profit!

REJECTION_CASES.each do |rejection_case|
  begin
    assert_code_allowed(rejection_case, debug=false)
    puts "Expected to reject:"
    puts rejection_case
    assert_code_allowed(rejection_case, debug=true)
    exit(0)
  rescue SandboxException
  end
end
