#
# Cookbook Name:: cq
# Provider:: user
#
# Copyright (C) 2015 Jakub Wadolowski
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Provider
    class CqRegularUser < Chef::Provider::CqUser
      def load_current_resource
        @current_resource = Chef::Resource::CqUser.new(new_resource.id)

        # Query CRX to get admin node
        @current_resource.query_result = crx_query(
          new_resource.username,
          new_resource.password
        )
        # Verify whether given user exists
        @current_resource.exist = exist?(current_resource.query_result)

        populate_user_data(
          new_resource.username,
          new_resource.password
        ) if current_resource.exist

        # Mark current user as disabled if that's the case
        @current_resource.enabled(
          false
        ) if current_resource.exist &&
             current_resource.info['rep:disabled'] == 'inactive'
      end

      def modify_user
        if password_update?(
            new_resource.user_password
        ) || !profile_diff.empty? || status_update?
          converge_by("Update user #{new_resource.id}") do
            profile_update(
              new_resource.username,
              new_resource.password,
              new_resource.user_password
            )
          end
        else
          Chef::Log.info(
            "User #{new_resource.id} is already configured as defined"
          )
        end
      end
    end
  end
end
