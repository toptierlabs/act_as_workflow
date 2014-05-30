module Workflow
  class ProcessVersion < ActiveRecord::Base
    belongs_to :process_graph_node
    belongs_to :process, inverse_of: :process_versions

    has_many :process_graph_nodes

    has_many :process_instances, inverse_of: :process_version

    validates :process, presence: true

    validates :version,
      presence: true,
      uniqueness: { scope: :process_id }

    class << self
      def find_version_instance_for(user, role, entity)
        instance = includes(:process_instances).find_by(
          workflow_process_instances: {
            user_id:     user.id,
            role:        role,
            entity_type: entity.class.name,
            entity_id:   entity.id
          }
        )
        instance.present? ? instance.process_instances.first : last.create_instance_for(user, role, entity)
      end
    end

    def create_instance_graph_for(instance)
      process_graph_nodes.each do |node|
        node.create_instance_node_for instance
      end
    end

    def create_instance_for(user, role, entity)
      process_instances.create(
        user_id:     user.id,
        role:        role,
        entity_type: entity.class.name,
        entity_id:   entity.id
      )
    end
  end
end
