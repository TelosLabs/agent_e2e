# frozen_string_literal: true

module AgentE2e
  class Railtie < Rails::Railtie
    generators do
      require "generators/agent_e2e/install/install_generator"
    end
  end
end
