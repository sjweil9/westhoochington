module Discord
  module Bots
    module Commands
      class Base
        include Singleton

        module Instrumentation
          def execute(event, *args)
            # handle arguments wrapped in double quotes as one argument
            while quoted_arg = args.detect { |arg| arg[0] == '"' }
              close_quote_arg = args.detect { |arg| arg[-1] == '"' }
              start_index = args.index(quoted_arg)
              end_index = args.index(close_quote_arg)
              # remove elements after (but not including) start_index up to end_index into this variable
              later_args = args.slice!(start_index + 1, end_index - start_index)
              # combine all args including the starting quote together with spaces
              args[start_index] = [quoted_arg, *later_args].join(" ")
              # remove the first and last characters (the open and close quotes)
              args[start_index] = args[start_index][1..-2]
            end
            super
          end
        end

        def self.inherited(base)
          base.prepend Instrumentation
          super
        end

        def name
          raise NotImplementedError, "must implement name in command subclass"
        end

        def execute(_event, *_args)
          raise NotImplementedError, "must implement execute in command subclass"
        end

        def opts
          {
            min_args: min_args,
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

        def find_user(discord_mention)
          discord_id = discord_mention.gsub(/\D+/, '')
          u = User.find_by(discord_id: discord_id)
          return u if u&.discord_id.present?

          n = Nickname.find_by(name: discord_mention)
          n&.user
        end

        def valid_year?(year)
          if RANGE_REGEX.match?(year)
            start, finish = year.split("-")
            valid_year?(start) && valid_year?(finish)
          else
            year.to_i >= 2012 && year.to_i <= Date.today.year
          end
        end

        def invalid_user!(event, user)
          event << "Sorry, user #{user} was not recognized."
          nil
        end

        def invalid_year!(event, year)
          event << "Year #{year} is invalid. Must be between 2012 and the present."
          nil
        end
      end
    end
  end
end