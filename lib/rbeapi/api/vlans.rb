#
# Copyright (c) 2014,2015, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
require 'rbeapi/api'

##
# Rbeapi toplevel namespace
module Rbeapi
  ##
  # Api is module namespace for working with the EOS command API
  module Api
    ##
    # The Vlan class provides a class implementation for working with the
    # collection of Vlans on the node.  This class presents an abstraction
    # of the nodes configured vlan id's from the running configuration.
    #
    # @eos_version 4.13.7M
    class Vlans < Entity
      ##
      # get returns the specified vlan resource Hash that represents the
      # nodes current vlan configuration.
      #
      # @example
      #   {
      #     name: <string>
      #     state: <string>
      #     trunk_groups: array[<string]
      #   }
      #
      # @param [String] id The vlan id to return a resource for from the
      #   nodes configuration
      #
      # @return [nil, Hash<Symbol, Object>] Returns the vlan resource as a
      #   Hash.  If the specified vlan id is not found in the nodes current
      #   configuration a nil object is returned
      def get(id)
        config = get_block("vlan #{id}")
        return nil unless config
        response = {}
        response.merge!(parse_name(config))
        response.merge!(parse_state(config))
        response.merge!(parse_trunk_groups(config))
        response
      end

      ##
      # getall returns the collection of vlan resources from the nodes
      # running configuration as a hash.  The vlan resource collection
      # hash is keyed by the unique vlan id
      #
      # @example
      #   {
      #     <vlanid>: {...}
      #   }
      #
      # @see get Vlan resource example
      #
      # @return [Hash<Symbol, Object>] returns a hash that represents the
      #   entire vlan collection from the nodes running configuration.  If
      #   there are no vlans configured, this method will return an empty
      #   hash
      def getall
        vlans = config.scan(/(?<=^vlan\s)\d+$/)
        vlans.each_with_object({}) do |vid, hsh|
          resource = get vid
          hsh[vid] = resource if resource
        end
      end

      ##
      # parse_name scans the provided configuration block and parses the
      # vlan name value.  The vlan name should always return a value
      # from the running configuration.  The return value is intended to
      # be merged into the resource hash
      #
      # @api private
      #
      # @return [Hash<Symbol, Object>] resource hash attribute
      def parse_name(config)
        mdata = /name ([^\s]+)$/.match(config)
        { name: mdata[1] }
      end
      private :parse_name

      ##
      # parse_state scans the provided configuration block and parses the
      # vlan state value. The vlan state should always return a value from
      # the nodes running configuration.  The return hash is intended to be
      # merged into the resource hash
      #
      # @api private
      #
      # @return [Hash<Symbol, Object>] resource hash attribute
      def parse_state(config)
        mdata = /state (\w+)$/.match(config)
        { state: mdata[1] }
      end
      private :parse_state

      ##
      # parse_trunk_groups scans the provided configuration block and parses
      # the trunk groups.  If no trunk groups are found in the nodes
      # running configuration then an empty array is returned as the value.
      # The return hash is intended to be merged into the resource hash.
      #
      # @api private
      #
      # @return [Hash<Symbol, Object>] resource hash attribute
      def parse_trunk_groups(config)
        values = config.scan(/trunk group (.+)$/).first
        values = [] unless values
        { trunk_groups: values }
      end
      private :parse_trunk_groups

      ##
      # create will create a new vlan resource in the nodes current
      # configuration with the specified vlan id.  If the create method
      # is called and the vlan id already exists, this method will still
      # return true.
      #
      # @eos_version 4.13.7M
      #
      # @commands
      #   vlan <value>
      #
      # @param [String, Integer] :id The vlan id to create on the node.  The
      #   vlan id must be in the valid range of 1 to 4094
      #
      # @return [Boolean] returns true if the command completed successfully
      def create(id)
        configure("vlan #{id}")
      end

      ##
      # delete will delete an existing vlan resource from the nodes current
      # running configuration.  If the delete method is called and the vlan
      # id does not exist, this method will succeed.
      #
      # @eos_version 4.13.7M
      #
      # @commands
      #   no vlan <value>
      #
      # @param [String, Integer] :id The vlan id to delete from the node.  The
      #   id value should be in the valid range of 1 to 4094
      #
      # @return [Boolean] returns true if the command completed successfully
      def delete(id)
        configure("no vlan #{id}")
      end

      ##
      # default will configure the vlan using the default keyword.  This
      # command has the same effect as deleting the vlan from the nodes
      # running configuration.
      #
      # @eos_version 4.13.7M
      #
      # @commands
      #   default vlan <value>
      #
      # @param [String, Integer] :id The vlan id to default in the nodes
      #   configuration.  Ths vid value should be in the valid range of 1
      #   to 4094
      #
      # @return [Boolean] returns true if the command complete successfully
      def default(id)
        configure("default vlan #{id}")
      end

      ##
      # set_name configures the name value for the specified vlan id in the
      # nodes running configuration.  If enable is false in the
      # opts keyword Hash then the name value is negated using the no
      # keyword.  If the default keyword is set to true, then the name value
      # is defaulted using the default keyword.  The default keyword takes
      # precedence over the enable keyword
      #
      # @eos_version 4.13.7M
      #
      # @commands
      #   vlan <id>
      #     name <value>
      #     no name
      #     default name
      #
      # @param [String, Integer] :id The vlan id to apply the configuration
      #   to.  The id value should be in the valid range of 1 to 4094
      #
      # @param [Hash] :opts Optional keyword arguments
      #
      # @option :opts [String] :value The value to configure the vlan name
      #   to in the node configuration.  The name parameter accepts a-z, 0-9
      #   and _.
      #
      # @option :opts [Boolean] :enable If false then the command is
      #   negated. Default is true.
      #
      # @option :opts [Boolean] :default Configure the vlan name value using
      #   the default keyword
      #
      # @return [Boolean] returns true if the command completed successfully
      def set_name(id, opts = {})
        cmd = command_builder('name', opts)
        cmds = ["vlan #{id}", cmd]
        configure(cmds)
      end

      ##
      # set_state configures the state value for the specified vlan id in
      # the nodes running configuration.  If enable is set to false in
      # the opts keyword Hash then the state value is negated using the no
      # keyword.  If the default keyword is set to true, then the state
      # value is defaulted using the default keyword.  The default keyword
      # takes precedence over the enable keyword
      #
      # @eos_version 4.13.7M
      #
      # @commands
      #   vlan <id>
      #     state [active, suspend]
      #     no state
      #     default state
      #
      # @param [String, Integer] :id The vlan id to apply the configuration
      #   to.  The id value should be in the valid range of 1 to 4094
      #
      # @param [Hash] :opts Optional keyword arguments
      #
      # @option :opts [String] :value The value to configure the vlan state
      #   to in the node's configuration.  Accepted values are 'active' or
      #   'suspend'
      #
      # @option :opts [Boolean] :enable If false then the command is
      #   negated. Default is true.
      #
      # @option :opts [Boolean] :default Configure the vlan state value using
      #   the default keyword
      #
      # @return [Boolean] returns true if the command completed successfully
      #
      # @raise [ArgumentError] if the value is not in the accept list of
      #   values
      def set_state(id, opts = {})
        value = opts[:value]
        unless ['active', 'suspend', nil].include?(value)
          fail ArgumentError, 'state must be active, suspend or nil'
        end

        cmd = command_builder('state', opts)
        cmds = ["vlan #{id}", cmd]
        configure(cmds)
      end

      ##
      # add_trunk_group adds a new trunk group value to the specified vlan
      # id in the nodes running configuration.  The trunk group name value
      # accepts a-z 0-9 and _
      #
      # @version 4.13.7M
      #
      # @commands
      #   vlan <id>
      #     trunk group <value>
      #
      # @param [String, Integer] :id The vlan id to apply the configuration
      #   to.  the id value should be in the range of 1 to 4094
      #
      # @param [String] :value The value to add to the vlan id configuration
      #   on the node.
      #
      # @return [Boolean] returns true if the command completed successfully
      def add_trunk_group(id, value)
        configure(["vlan #{id}", "trunk group #{value}"])
      end

      ##
      # remove_trunk_group removes the specified trunk group value from the
      # specified vlan id in the node's configuration.  If the trunk group
      # name does not exist, this method will return success
      #
      # @eos_version 4.13.7M
      #
      # @commands
      #   vlan <id>
      #     no trunk group <value>
      #
      # @param [String, Integer] :id The vlan id to apply the configuration
      #   to.  the id value should be in the range of 1 to 4094
      #
      # @param [String] :value The value to remove from the list of trunk
      #   group names configured for the specified vlan
      #
      def remove_trunk_group(id, value)
        configure(["vlan #{id}", "no trunk group #{value}"])
      end
    end
  end
end
