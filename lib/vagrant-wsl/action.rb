require "vagrant/action/builder"

module VagrantPlugins
  module ProviderWSL
    module Action
      autoload :Boot, File.expand_path("../action/boot", __FILE__)
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckCreated, File.expand_path("../action/check_created", __FILE__)
      autoload :CheckRunning, File.expand_path("../action/check_running", __FILE__)
      autoload :CheckWSL, File.expand_path("../action/check_wsl", __FILE__)
      autoload :CleanMachineFolder, File.expand_path("../action/clean_machine_folder", __FILE__)
      autoload :ClearForwardedPorts, File.expand_path("../action/clear_forwarded_ports", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)
      autoload :Customize, File.expand_path("../action/customize", __FILE__)
      autoload :Destroy, File.expand_path("../action/destroy", __FILE__)
      autoload :DiscardState, File.expand_path("../action/discard_state", __FILE__)
      autoload :Export, File.expand_path("../action/export", __FILE__)
      autoload :ForcedHalt, File.expand_path("../action/forced_halt", __FILE__)
      autoload :ForwardPorts, File.expand_path("../action/forward_ports", __FILE__)
      autoload :Import, File.expand_path("../action/import", __FILE__)
      autoload :IsRunning, File.expand_path("../action/is_running", __FILE__)
      autoload :MatchMACAddress, File.expand_path("../action/match_mac_address", __FILE__)
      autoload :MessageAlreadyRunning, File.expand_path("../action/message_already_running", __FILE__)
      autoload :MessageNotCreated, File.expand_path("../action/message_not_created", __FILE__)
      autoload :MessageNotRunning, File.expand_path("../action/message_not_running", __FILE__)
      autoload :MessageWillNotDestroy, File.expand_path("../action/message_will_not_destroy", __FILE__)
      autoload :Network, File.expand_path("../action/network", __FILE__)
      autoload :Package, File.expand_path("../action/package", __FILE__)
      autoload :PackageSetupFiles, File.expand_path("../action/package_setup_files", __FILE__)
      autoload :PackageSetupFolders, File.expand_path("../action/package_setup_folders", __FILE__)
      autoload :PackageVagrantfile, File.expand_path("../action/package_vagrantfile", __FILE__)
      autoload :PrepareCloneSnapshot, File.expand_path("../action/prepare_clone_snapshot", __FILE__)
      autoload :PrepareNFSSettings, File.expand_path("../action/prepare_nfs_settings", __FILE__)
      autoload :PrepareNFSValidIds, File.expand_path("../action/prepare_nfs_valid_ids", __FILE__)
      autoload :PrepareForwardedPortCollisionParams, File.expand_path("../action/prepare_forwarded_port_collision_params", __FILE__)
      autoload :SaneDefaults, File.expand_path("../action/sane_defaults", __FILE__)
      autoload :SetName, File.expand_path("../action/set_name", __FILE__)

      # Include the built-in modules so that we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action boots the VM, assuming the VM is in a state that requires a bootup
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckAccessible
          b.use CleanMachineFolder
          b.use SetName
          b.use ClearForwardedPorts
          b.use Provision
          b.use EnvSet, port_collision_repair: true
          b.use PrepareForwardedPortCollisionParams
          b.use HandleForwardedPortCollisions
          b.use PrepareNFSValidIds
          b.use SyncedFolderCleanup
          b.use SyncedFolders
          b.use PrepareNFSSettings
          b.use SetDefaultNICType
          b.use ClearNetworkInterfaces
          b.use Network
          b.use NetworkFixIPv6
          b.use ForwardPorts
          b.use SetHostname
          b.use SaneDefaults
          b.use Call, IsEnvSet, :cloud_init do |env, b2|
            if env[:result]
              b2.use CloudInitSetup
            end
          end
          b.use CleanupDisks
          b.use Disk
          b.use Customize, "pre-boot"
          b.use Boot
          b.use Customize, "post-boot"
          b.use WaitForCommunicator, [:starting, :running]
          b.use Call, IsEnvSet, :cloud_init do |env, b2|
            if env[:result]
              b2.use CloudInitWait
            end
          end
          b.use Customize, "post-comm"
          b.use CheckGuestAdditions
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use ConfigValidate
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use MessageNotRunning
                next
              end

              b3.use CheckAccessible
              b3.use Provision
            end
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHRun
        end
      end

      # This action starts a VM, assuming it is already imported and exists.
      # A precondition of this action is that the VM exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use ConfigValidate
          b.use BoxCheckOutdated
          b.use Call, IsRunning do |env, b2|
            # If the VM is running, run the necessary provisioners
            if env[:result]
              b2.use action_provision
              next
            end

            b2.use Call, IsSaved do |env2, b3|
              if env2[:result]
                # The VM is saved, so just resume it
                b3.use action_resume
                next
              end

              b3.use Call, IsPaused do |env3, b4|
                if env3[:result]
                  b4.use Resume
                  next
                end

                # The VM is not saved, so we must have to boot it up
                # like normal. Boot!
                b4.use action_boot
              end
            end
          end
        end
      end

      # This action brings the machine up from nothing, including importing
      # the box, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox

          # Handle box_url downloading early so that if the Vagrantfile
          # references any files in the box or something it all just
          # works fine.
          b.use Call, Created do |env, b2|
            if !env[:result]
              b2.use HandleBox
            end
          end

          b.use ConfigValidate
          b.use Call, Created do |env, b2|
            # If the VM is NOT created yet, then do the setup steps
            if !env[:result]
              b2.use CheckAccessible
              b2.use Customize, "pre-import"

              if env[:machine].provider_config.linked_clone
                # We are cloning from the box
                b2.use ImportMaster
              end

              b2.use PrepareClone
              b2.use PrepareCloneSnapshot
              b2.use Import
              b2.use DiscardState
              b2.use MatchMACAddress
            end
          end

          b.use EnvSet, cloud_init: true
          b.use action_start
        end
      end
    end
  end
end