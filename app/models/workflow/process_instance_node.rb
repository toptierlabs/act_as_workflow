module Workflow
  class ProcessInstanceNode < ActiveRecord::Base
    belongs_to :process_instance
    belongs_to :process_graph_node

    has_many :process_instance_successor_edges,
      class_name: Workflow::ProcessInstanceEdge,
      inverse_of: :process_instance_node

    has_many :process_instance_children_edges,
      foreign_key: :end_instance_node_id,
      class_name: Workflow::ProcessInstanceEdge,
      inverse_of: :end_instance_node

    has_many :successor_nodes,
      through: :process_instance_successor_edges,
      source: :end_instance_node

    has_many :children_nodes,
      through: :process_instance_children_edges,
      source: :process_instance_node

    delegate :owner,
      :priority,
      :when_complete_invalidate_nodes,
      :process_graph_node_requisites,
      :complete_globally?,
      to: :process_graph_node

    delegate :entity, :role, to: :process_instance, prefix: :instance

    validates :process_instance,   presence: true
    validates :process_graph_node, presence: true

    def completed?
      completed_at.present?
    end

    def complete(options = {})
      user_authorized = options[:user_authorized] || false
      return false \
        if completed? || !validate_owner ||
          !validates_preconditions(user_authorized: user_authorized)

      if complete_globally?
        # only the nodes with the same definition
        instance_nodes_with_same_definition.update_all(:completed_at, DateTime.now)

      else
        update_column(:completed_at, DateTime.now)
      end
      successor_nodes.each(&:complete)
    end

    def next_nodes
      if self.completed? || !validate_owner
        successor_nodes.map(&:next_nodes).flatten!
      elsif validates_preconditions
        [process_graph_node]
      else
        []
      end
    end

    private

    def instance_nodes_with_same_definition
      instance_entity.process_instance_nodes.where(
        process_graph_node: process_graph_node_id
      )
    end

    def validates_preconditions(options = {})
      user_authorized = options[:user_authorized] || false
      result = true
      process_graph_node_requisites.preconditions.each do |requisite|
        result = requisite.evaluate_requisite_for(
          instance_entity,
          self,
          user_authorized: user_authorized
        )
        # If the result is false, then it goes out from the each block
        break unless result
      end
      result
    end

    def validate_owner
      instance_role == owner
    end
  end
end
