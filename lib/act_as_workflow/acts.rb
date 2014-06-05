module Workflow
  module Acts
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_workflow(options = {})
        name = options[:name]
        workflow = Workflow::Process.find_or_create_by!(
          entity_class: name,
          name: name
        )

        class_variable_set( "@@#{name}", workflow)

        # Method used to give custom validation to the workflow
        def validate_with_custom_logic(&block)
          class_eval &block
        end

        # Adds the relation to process instances to the class
        has_many :process_instances,
          class_name: Workflow::ProcessInstance,
          as: :entity

        has_many :process_instance_nodes,
          through: :process_instances,
          class_name: Workflow::ProcessInstanceNode


        class_eval do
          def current_steps_for(user, options)
            name = options[:name]
            workflow = self.class.class_variable_get( "@@#{name}")
            role = role_for_user user
            workflow.current_actions_for(user, role, self)
          end

          def completed_actions_for(user, options)
            name = options[:name]
            workflow = self.class.class_variable_get( "@@#{name}")
            role = role_for_user user
            workflow.completed_actions_for(user, role, self)
          end
      
          def complete_step(user, node)
            node = Workflow::ProcessInstanceNode.find(node) if node.is_a?(Integer)
            role = role_for_user user
            if node.complete(role, user_authorized: true)
              true
            else
              errors[:workflow] = node.errors[:base]
              false
            end
          end

          def role_for_user(user)
            return :seller if self.user == user
            return :admin if user.role == :admin
            return :buyer
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Workflow::Acts
