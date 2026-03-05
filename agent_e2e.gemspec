# frozen_string_literal: true

require_relative "lib/agent_e2e/version"

Gem::Specification.new do |spec|
  spec.name = "agent_e2e"
  spec.version = AgentE2e::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your@email.com"]

  spec.summary = "AI-powered E2E testing for Rails using Playwright and OpenAI"
  spec.description = "Sets up an AI QA agent that drives a real browser with Playwright, " \
                     "guided by OpenAI, to run natural-language E2E tests against your Rails app. " \
                     "Includes letter_opener_web for email testing."
  spec.homepage = "https://github.com/your-org/agent_e2e"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "letter_opener_web", "~> 3.0"
end
