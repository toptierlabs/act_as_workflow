module Workflow
  class ProcessInstanceEdge < ActiveRecord::Base
    belongs_to :process_instance_node,
      inverse_of: :process_instance_successor_edges
    belongs_to :process_graph_edge,
      inverse_of: :process_instance_edges
    belongs_to :end_instance_node,
      class_name: Workflow::ProcessInstanceNode,
      inverse_of: :process_instance_children_edges

    validates :process_instance_node, presence: true
    validates :process_graph_edge,    presence: true
  end
end
