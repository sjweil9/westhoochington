module Discord
  module Bots
    module Commands
      class Base
        include Singleton

        def name
          raise NotImplementedError, "must implement name in command subclass"
        end

        def execute(_event, *_args)
          raise NotImplementedError, "must implement execute in command subclass"
        end

        def opts
          {
            min_args: min_args,
            max_args: max_args,
            channels: channels,
            description: description,
            usage: usage,
          }.compact
        end

        private

        RANGE_REGEX = /(\d+)-(\d+)/

        def min_args; end
        def max_args; end
        def channels; end
        def description; end
        def usage; end
      end
    end
  end
end