module Workflow
  class ProcessGraphEdges < ActiveRecord::Base
    belongs_to :process_graph_node
  end
end
