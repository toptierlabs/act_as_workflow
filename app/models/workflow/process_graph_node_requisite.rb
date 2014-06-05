module Workflow
  class ProcessGraphNodeRequisite < ActiveRecord::Base 
    belongs_to :process_graph_node, inverse_of: :process_instance_nodes

    scope :conditions,
      -> { where.not(validator_type: VALIDATOR_TYPES[:children_completed]) }

    scope :preconditions,
      -> { where(validator_type: VALIDATOR_TYPES[:children_completed]) }

    VALIDATOR_TYPES = {
       children_completed: 0,
       user: 1,
       query: 2,
       custom_logic: 3,
       other_nodes_completed: 4,
       validation_set: 5
    }

    validates :validator_type, inclusion: { in: VALIDATOR_TYPES.keys }

    # Getter and setter for the validator_type attribute.
    # This attribute is stored in the database as an integer
    # but the matching key for its value is returned when its loaded.
    def validator_type=(key)
      self[:validator_type] = VALIDATOR_TYPES[key]
    end

    def validator_type
      VALIDATOR_TYPES.key self[:validator_type]
    end

    # TODO create a class for each validator. Each of those class will
    # be created inside a module called Validators.
    # Also, each class must implement the methods validate(args*)
    def evaluate_requisite_for(node_instance, options = {})
      user_authorized = options[:user_authorized] || false
      case validator_type
      when :children_completed
        complete_children_ids = node_instance.children_nodes.completed.pluck(:id)
        children_ids = node_instance.children_nodes.pluck(:id)
        if (children_ids - complete_children_ids).blank?
          return true
        else
          node_instance.errors[:base] << 'previous steps must be completed'
          return false
        end
      when :user
        if user_authorized
          return true
        else
          node_instance.errors[:base] << 'not authorized by the user'
          return false
        end
      when :query
        # This should have limit 1 by default
        records_array =
          ActiveRecord::Base.connection.execute(validator_content)
        return records_array.present?
      when :custom_logic
        if node_instance.instance_entity.send(validator_content)
          return true
        else
          node_instance.errors[:base] << "#{validator_content} is not satisfied"
          return false
        end
      when :other_nodes_completed
        node_ids = validator_content.split(',').map(&:to_i).uniq
        nodes_length = node_instance.instance.process_instance_nodes.where(
          "process_graph_node_id IN ? AND completed_at IS NOT NULL",
          node_ids
        ).count
        return node_ids.length == nodes_length
      else
        return true       
      end
    end
  end
end
