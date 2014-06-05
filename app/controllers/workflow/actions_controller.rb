module Workflow
  class ActionsController < ActionController::Base
    before_action :load_user
    respond_to :json

    def index
      workflow_name = params[:workflow_name].to_sym
      a = resource.current_steps_for(@user, name: workflow_name)
      render json: a.as_json(include: [:process_graph_node])
    end

    def complete
      node_id = params[:node_id].to_i
      if resource.complete_step(@user, node_id)
        render json: { status: :completed }
      else
        render json: { status: :error, errors: resource.errors.as_json }
      end
    end

    def completed_actions
      workflow_name = params[:workflow_name].to_sym
      actions = resource.completed_actions_for @user, name: workflow_name
      render json: actions.as_json
    end

    private

    def load_user
      @user = User.find(params[:user_id])
    end

    def resource
      @resource ||= resource_class.find(params[:resource_id])
    end

    def resource_class
      @klass ||= resource_name.constantize
    end

    def resource_name
      request.env['PATH_INFO'].split('/')[1].singularize.camelize
    end
  end
end
