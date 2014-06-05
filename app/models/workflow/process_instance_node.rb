module Workflow
  class ProcessInstanceNode < ActiveRecord::Base
    scope :completed,
      -> { where('completed_at IS NOT NULL') }
    scope :uncompleted,
      -> { where('completed_at IS NULL') }
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
      :complete_globally?,
      :when_complete_invalidate_nodes,
      :validates_preconditions_for_instance,
      :validates_conditions_for_instance,
      to: :process_graph_node

    delegate :entity, :role, to: :process_instance, prefix: :instance

    validates :process_instance,   presence: true
    validates :process_graph_node, presence: true

    def completed?
      completed_at.present?
    end

    def canceled?
      canceled_at.present?
    end

    def complete(owner_params = nil, options = {})
      owner_params ||= owner
      user_authorized = options[:user_authorized] || false

      return false unless can_be_completed_by?(owner_params, options)

      complete_instance_node
      process_instance.cancel_instance_nodes(when_complete_invalidate_nodes)

      successor_nodes.each(&:complete)
      true
    end

    def next_nodes(options = {})
      owner_params = options[:owner] || owner
      return [] if (!completed? && validates_preconditions_for_instance(self)) || canceled?
      if self.completed? || (self.completed?  && !validate_owner(owner_params))
        successor_nodes.map{ |v| v.next_nodes(options) }.flatten!
      elsif validate_owner(owner_params)
        [self]
      else
        []
      end
    end

    def completed_nodes(options = {})
      owner_params = options[:owner] || owner
      if self.completed?
        result = successor_nodes.map{ |v| v.completed_nodes(options) }
        result << self
        result
      else
        []
      end
    end

    def validate_owner(owner_params = nil)
      (owner_params == owner) || (owner == :all)
    end

    def can_be_completed_by?(owner_params = nil, options = {})
      user_authorized = options[:user_authorized] || false
      !completed? && validate_owner(owner_params) && !canceled? &&
        validates_preconditions_for_instance(self, user_authorized: user_authorized) &&
        validates_conditions_for_instance(self, user_authorized: user_authorized)
    end

    def complete_instance_node
      if complete_globally?
        # updates nodes with the same graph definition
        # related to the same entity
        nodes = entity_nodes_with_the_same_definition.uncompleted
        nodes.update_all(completed_at: DateTime.now)
      else
        update_column(:completed_at, DateTime.now)
      end
    end

    def cancel_node
      if complete_globally?
        # updates nodes with the same graph definition
        # related to the same entity
        nodes = entity_nodes_with_the_same_definition.uncompleted
        nodes.update_all(canceled_at: DateTime.now)
      else
        update_column(:canceled_at, DateTime.now)
      end
    end

    def entity_nodes_with_the_same_definition
      instance_entity.process_instance_nodes.where(
        process_graph_node_id: process_graph_node_id
      )
    end
  end
end
