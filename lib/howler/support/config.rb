module Howler
  class Config
    @@options = {}

    def self.[](key)
      @@options[key]
    end

    def self.[]=(key, value)
      @@options[key] = value
    end

  end
end
