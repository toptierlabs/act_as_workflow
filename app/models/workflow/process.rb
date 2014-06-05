module Workflow
  class Process < ActiveRecord::Base
    has_many :process_versions

    delegate :find_version_instances_for, to: :process_versions

    def current_actions_for(user, role, entity)
      instances = find_version_instances_for(user, role, entity)
      result = instances.map{|v| v.next_nodes(owner: role) }
      sanitize_nodes_array(result)
    end

    def completed_actions_for(user, role, entity)
      instances = find_version_instances_for(user, role, entity)
      result = instances.map{|v| v.completed_nodes(owner: role) }
      sanitize_nodes_array(result)
    end

    private

    def sanitize_nodes_array(nodes_params)
      nodes = nodes_params.flatten.select{ |v| v.present? }
      complete_globally = nodes.select{ |v| v.complete_globally? == true }
      complete_globally.uniq!{ |v| v.process_graph_node_id }
      result = nodes.select{ |v| v.complete_globally? == false } +
        complete_globally
      result.uniq!
      result
    end
  end
end
