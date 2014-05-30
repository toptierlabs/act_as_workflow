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
        instance = includes(:process_instances).where(
          workflow_process_instances: {
            user_id:     user.id,
            role:        role,
            entity_type: entity.class.name,
            entity_id:   entity.id
          }
        )
        instance.present? ? instance : last.instance_for(user, entity)
      end
    end

    def create_instance_graph_for(instance)
      process_graph_nodes.each do |node|
        node.create_instance_node_for instance
      end
    end

    def instance_for(user, entity)
      process_instances.find_or_create_by(
        user_id:     user.id,
        entity_type: entity.class.name,
        entity_id:   entity.id
      )
    end
  end
end
