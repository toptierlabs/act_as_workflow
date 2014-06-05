module ActionDispatch::Routing
  class Mapper
    def workflow_routes_for(resource_name)
      scope :module => 'workflow' do
        get "#{resource_name.to_s.pluralize}/:resource_id/next_actions",
          to: 'actions#index',
          as: "next_#{resource_name}_actions"
        post "#{resource_name.to_s.pluralize}/:resource_id/next_actions/:node_id",
          to: 'actions#complete',
          as: "complete_#{resource_name.to_s.pluralize}_action"
        get "#{resource_name.to_s.pluralize}/:resource_id/completed_actions",
          to: 'actions#completed_actions',
          as: "completed_#{resource_name}_actions"
      end
      # 
    end
  end
end
