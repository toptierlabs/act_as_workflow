module Workflow
  module Acts
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_workflow(options = {})
        Workflow::Process.find_or_create_by!(entity_class: name)

        class_eval do
          has_many :process_instances,
            class_name: Workflow::ProcessInstance,
            as: :entity

          has_many :process_instance_nodes,
            through: :process_instances,
            class_name: Workflow::ProcessInstanceNode

          def validate_with_custom_logic(&block)
            class_eval &block
          end

          def current_steps_for(user, role)
            instance = instances_for(user, role)
            instance.map{|v| v.next_nodes(owner: role) }.flatten.uniq
          end

          def complete_step(user, role, node)
            instance = instances_for(user, role)
            node.complete(role, user_authorized: true)
          end

          def instances_for(user, role)
            process = Workflow::Process.find_by!(entity_class: self.class.name)
            process.find_version_instances_for(user, role, self)
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Workflow::Acts
