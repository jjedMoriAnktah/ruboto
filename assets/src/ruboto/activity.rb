require 'ruboto/base'
require 'ruboto/package'

#######################################################
#
# ruboto/activity.rb
#
# Basic activity set up.
#
#######################################################

#
# Context
#
module Ruboto
  module Context
    def start_ruboto_dialog(remote_variable, theme=Java::android.R.style::Theme_Dialog, &block)
      java_import 'org.ruboto.RubotoDialog'
      start_ruboto_activity(remote_variable, RubotoDialog, theme, &block)
    end

    def start_ruboto_activity(class_name = nil, options = nil, &block)
      # FIXME(uwe):  Deprecated.  Remove june 2014.
      if options[:class_name]
        puts "\nDEPRECATON: The ':class_name' option is deprecated.  Put the class name in the first argument instead."
      end

      if options.nil?
        if class_name.is_a?(Hash)
          options = class_name
        else
          options = {}
        end
      end

      java_class = options.delete(:java_class) || RubotoActivity
      theme = options.delete(:theme)

      # FIXME(uwe):  Remove the use of the :class_name option in june 2014
      class_name_option = options.delete(:class_name)
      class_name ||= class_name_option
      # EMXIF

      script_name = options.delete(:script)
      raise "Unknown options: #{options}" unless options.empty?

      if class_name.nil? && block_given?
        class_name =
            "#{java_class.name.split('::').last}_#{source_descriptor(block)[0].split('/').last.gsub(/[.-]+/, '_')}_#{source_descriptor(block)[1]}"
      end

      if Object.const_defined?(class_name)
        Object.const_get(class_name).class_eval(&block) if block_given?
      else
        Object.const_set(class_name, Class.new(&block))
      end
      i = android.content.Intent.new
      i.setClass self, java_class.java_class
      i.putExtra(Ruboto::THEME_KEY, theme) if theme
      i.putExtra(Ruboto::CLASS_NAME_KEY, class_name) if class_name
      i.putExtra(Ruboto::SCRIPT_NAME_KEY, script_name) if script_name
      startActivity i
      self
    end

    private

    def source_descriptor(proc)
      if md = /^#<Proc:0x[0-9A-Fa-f]+@(.+):(\d+)(?: \(lambda\))?>$/.match(proc.inspect)
        filename, line = md.captures
        return filename, line.to_i
      end
    end

  end

end

java_import 'android.content.Context'
Context.class_eval do
  include Ruboto::Context
end

#
# Basic Activity Setup
#

module Ruboto
  module Activity
    def method_missing(method, *args, &block)
      return @ruboto_java_instance.send(method, *args, &block) if @ruboto_java_instance && @ruboto_java_instance.respond_to?(method)
      super
    end
  end
end

def ruboto_configure_activity(klass)
  klass.class_eval do
    include Ruboto::Activity
  end
end

java_import 'android.app.Activity'
java_import 'org.ruboto.RubotoActivity'
ruboto_configure_activity(RubotoActivity)

