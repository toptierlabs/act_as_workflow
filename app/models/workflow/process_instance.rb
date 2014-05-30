module Workflow
  class ProcessInstance < ActiveRecord::Base
    belongs_to :process_version, inverse_of: :process_instances
    belongs_to :user
    belongs_to :entity, polymorphic: true
    belongs_to :dummy_instance_node,
      class_name: Workflow::ProcessInstanceNode

    has_many :process_instance_nodes

    after_create :initialize_instance_node

    delegate :next_nodes, :complete, to: :dummy_instance_node

    # returns the role value casted to Symbol
    def role
      self[:role].to_sym
    end

    private

    def initialize_instance_node
      process_version.create_instance_graph_for self
      # Loads the dummy node into the instance
      dummy_graph_node = process_version.process_graph_node
      dummy_node = process_instance_nodes.find_by(
        process_graph_node_id: dummy_graph_node.id
      )
      self.dummy_instance_node = dummy_node
      self.dummy_instance_node.complete
      # sets the user role
      save
    end
  end
end
