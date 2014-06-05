module Workflow
  class ProcessGraphNode < ActiveRecord::Base
    belongs_to :process_version

    has_many :process_graph_node_requisites
    has_many :process_graph_successor_edges,
      class_name: Workflow::ProcessGraphEdge

    has_many :process_graph_children_edges,
      class_name: Workflow::ProcessGraphEdge,
      foreign_key: :end_node_id

    has_many :successor_nodes,
      through: :process_graph_successor_edges,
      source: :end_node

    has_many :children_nodes,
      through: :process_graph_children_edges,
      source: :process_graph_node

    has_many :process_instance_nodes, inverse_of: :process_graph_node

    serialize :when_complete_invalidate_nodes, Array

    def owner
      self[:owner].to_sym unless self[:owner].nil?
    end

    def create_instance_node_for(instance)
      node_for instance
      process_graph_successor_edges.find_each do |edge|
        edge.create_instance_edge_for instance
      end
    end

    def node_for(instance)
      completed_at = node_completed_at_for(instance)

      process_instance_nodes
        .find_or_create_by(
          process_instance_id: instance.id,
          completed_at: completed_at
        )
    end

    def validates_conditions_for_instance(instance_node, options = {})
      validates_requisites(
        process_graph_node_requisites.conditions,
        instance_node,
        options
      )
    end

    def validates_preconditions_for_instance(instance_node, options = {})
      validates_requisites(
        process_graph_node_requisites.preconditions,
        instance_node,
        options
      )
    end

    def validates_requisites(requsite_set, instance_node, options)
      user_authorized = options[:user_authorized] || false
      result = true
      requsite_set.each do |requisite|
        result = requisite.evaluate_requisite_for(
          instance_node,
          user_authorized: user_authorized
        )
        # If the result is false, then it goes out from the each block
        break unless result
      end
      result
    end

    private

    def node_completed_at_for(instance)
      if complete_globally?        
        node = instance.entity.process_instance_nodes.completed.find_by(
            process_graph_node_id: id
          )
        return node.completed_at if node.present?
      end
    end
  end
end
