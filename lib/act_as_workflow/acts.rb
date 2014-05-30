module Workflow
  module Acts
    extend ActiveSupport::Concern

    included do
      def validates_for_workflow(attr_route, options = {})
        run_callbacks :workflow_validation do
        end
      end
    end

    module ClassMethods
      def acts_as_workflow(options = {})

        class_eval do
          define_callbacks :workflow_validation,
            terminator: 'result == false',
            skip_after_callbacks_if_terminated: true

          has_many :process_instances,
            class_name: Workflow::ProcessInstance,
            as: :entity

          has_many :process_instance_nodes,
            through: :process_instances,
            class_name: Workflow::ProcessInstanceNode

          def validate_with_custom_logic(base = nil, &block)
            class_eval &block
          end

          def current_steps_for(user, role)
            instance = instance_for(user, role)
            instance.next_nodes
          end

          def complete_steps_for(user, role)
            instance = instance_for(user, role)
            instance.complete(user_authorized: true)
          end

          def instance_for(user, role)
            process = Workflow::Process.find_or_create_by!(entity_class: self.class.name)
            process.find_version_instance_for(user, role, self)
          end
        end
      end


    end
  end
end

ActiveRecord::Base.send :include, Workflow::Acts
