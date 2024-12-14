require 'pry'
require './check'

class NoopBinding
  def eval(code, path, line)
    # no-op
  end
end

def console_sandbox
  hooks = Pry::Hooks.new

  hooks.add_hook(:before_eval, :block_evaluation) do |code, _pry|
    begin
      assert_code_allowed(code)
    rescue SandboxException => e
      puts e
      _pry.binding_stack << NoopBinding.new
    end
  end

  hooks.add_hook(:after_eval, :unblock_evaluation) do |code, _pry|
    if _pry.current_binding.instance_of?(NoopBinding)
      _pry.binding_stack.pop
    end
  end

  Pry.config.pager = false

  Pry.config.commands.each do |pattern, command| 
    keep = ['help', 'show-', 'exit'].any? do |prefix|
      pattern.instance_of?(String) && pattern.start_with?(prefix)
    end
    Pry.config.commands.delete(pattern) unless keep
  end

  # Start a Pry session with the custom hooks
  Pry.start(self, hooks: hooks)
end
