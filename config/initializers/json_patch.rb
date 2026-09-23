# frozen_string_literal: true

# Compatibility patch for Ruby 4.0 / JSON gem 3.0+ with ActiveSupport JSON decoding.
#
# ActiveSupport 8.1 calls `::JSON.parse(json, options)` with a *positional*
# options hash, but json 3.x only accepts keyword arguments, so any call with a
# non-empty options hash raises "wrong number of arguments (given 2, expected 1)".
#
# Splatting the hash into keywords is not sufficient on its own: json 3.x
# rejects keywords it does not recognise, and ActiveRecord's JSON coder passes
# `escape: false` (a *generation* option, meaningless when parsing). That raised
# "unknown keyword: escape" and broke every ActiveRecord JSON column - including
# Solid Queue's job arguments, which crashed its workers, dispatcher and
# scheduler on boot, so no background job or recurring task ever ran.
#
# Unsupported keys are therefore dropped before delegating. PARSE_OPTIONS was
# determined empirically against json 3.0.2 rather than copied from docs.
module ActiveSupport
  module JSON
    PARSE_OPTIONS = %i[
      max_nesting
      allow_nan
      allow_trailing_comma
      symbolize_names
      freeze
      decimal_class
      allow_duplicate_key
      object_class
      array_class
      on_load
    ].freeze

    class << self
      def decode(json, options = {})
        options = options.to_h.symbolize_keys.slice(*PARSE_OPTIONS)

        data = if options.empty?
          ::JSON.parse(json)
        else
          ::JSON.parse(json, **options)
        end

        if ActiveSupport.parse_json_times
          convert_dates_from(data)
        else
          data
        end
      end

      # `load` was aliased to the original `decode` when ActiveSupport loaded, so
      # it still points at the unpatched implementation unless re-aliased here.
      alias_method :load, :decode
    end
  end
end
