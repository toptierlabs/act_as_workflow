require 'act_as_workflow'
require 'rails'

module Workflow
  class Railtie < Rails::Railtie
    railtie_name :act_as_workflow
  end
end
