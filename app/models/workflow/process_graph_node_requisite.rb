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
       other_nodes_completed: 4
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

    def evaluate_requisite_for(instance_entity, node_instance, options = {})
      user_authorized = options[:user_authorized] || false
      case validator_type
      when :children_completed
        return node_instance.children_nodes.completed == node_instance.children_nodes
      when :user
        return user_authorized
      when :query
        # This should have limit 1 by default
        records_array =
          ActiveRecord::Base.connection.execute(validator_content)
        return records_array.present?
      when :custom_logic
        return instance_entity.send validator_content
      when :other_nodes_completed
        node_ids = validator_content.split(',').map(&:to_i).uniq
        nodes_length = node_instance.instance.process_instance_nodes.where(
          "process_graph_node_id IN ? AND completed_at IS NOT NULL",
          node_ids
        ).count
        return node_ids.length == nodes_length
      else        
      end
    end
  end
end
