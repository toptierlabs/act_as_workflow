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

    serialize :owner, Symbol

    def create_instance_node_for(instance)
      node_for instance
      process_graph_successor_edges.find_each do |edge|
        edge.create_instance_edge_for instance
      end
    end

    def node_for(instance)
      process_instance_nodes
        .find_or_create_by(process_instance_id: instance.id)
    end
  end
end
