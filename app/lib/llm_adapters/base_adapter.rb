module LlmAdapters
  class BaseAdapter
    def chat(system_prompt:, messages:, model: nil)
      raise NotImplementedError, "#{self.class}#chat not implemented"
    end
  end
end
