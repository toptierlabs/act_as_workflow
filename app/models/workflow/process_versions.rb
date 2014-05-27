module Workflow
  class ProcessVersions < ActiveRecord::Base
    belongs_to :process_graph_node
  end
end
