class Pinguin
  module Registry
    def register(key, value)
      string_key = key.to_s

      raise ArgumentError  if _entries.has_key?(string_key)
      _entries[string_key] = value
    end

    def get(key)
      _entries.fetch(key.to_s)
    end

    def _entries
      @_entries ||= {}
    end
  end
end
