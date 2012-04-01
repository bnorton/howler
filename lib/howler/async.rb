module Howler
  module Async
    def async(*methods)
      methods = methods.to_a.flatten.compact.map(&:to_s)

      class_eval do
        methods.each do |method|
          define_singleton_method :"async_#{method}" do |*args|
            Howler::Manager.current.push(self.to_s, method.to_sym, args)
          end
        end
      end
    end
  end
end
