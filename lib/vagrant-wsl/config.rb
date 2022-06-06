module VagrantPlugins
  module ProviderWSL
    class Config < Vagrant.plugin("2", :config)

      # @return [String]
      attr_accessor :name

      def initialize
        @name             = UNSET_VALUE
      end

      # Customize the VM by calling `wsl` with the given
      # arguments.
      #
      # @param [Array] command An array of arguments to pass to wsl.
      def customize(*command)
        event   = command.first.is_a?(String) ? command.shift : "pre-import"
        command = command[0]
        @customizations << [event, command]
      end

      def finalize!
        @name = nil if @name == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        valid_events = %w[pre-import post-import pre-network post-network post-comm]
        @customizations.each do |event, _|
          unless valid_events.include?(event)
            errors << I18n.t(
              "vagrant_wfs.config.invalid_event",
              event: event.to_s,
              valid_events: valid_events.join(", "))
          end
        end

        { "WFS Provider" => errors }
      end

      def to_s
        "WFS"
      end
    end
  end
end