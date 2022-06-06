require "pathname"

require "vagrant-wsl/plugin"

module VagrantPlugins
  module ProviderWSL
    lib_path = Pathname.new(File.expand_path("../vagrant-wsl", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end