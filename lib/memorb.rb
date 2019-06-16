module Memorb

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:prepend, InstanceMethods)
  end

  # def c
  #   caller_locations(1, 1).first.base_label
  # end

end

require_relative 'memorb/core'
require_relative 'memorb/class_methods'
require_relative 'memorb/instance_methods'
