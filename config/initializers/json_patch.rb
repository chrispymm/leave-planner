# frozen_string_literal: true

# Compatibility patch for Ruby 4.0 / JSON gem 3.0+ with ActiveSupport JSON decoding
module ActiveSupport
  module JSON
    class << self
      def decode(json, options = {})
        data = if options.is_a?(Hash) && !options.empty?
                 ::JSON.parse(json, **options)
        else
                 ::JSON.parse(json)
        end

        if ActiveSupport.parse_json_times
          convert_dates_from(data)
        else
          data
        end
      end
    end
  end
end
