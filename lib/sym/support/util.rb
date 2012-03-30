module Sym
  class Util
    def self.now
      Time.now.strftime("%b %d %Y %H:%M:%S")
    end

    def self.at(time)
      return "" unless time
      Time.at(time).strftime("%b %d %Y %H:%M:%S")
    end

    def self.constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
      end
      constant
    end
  end
end
