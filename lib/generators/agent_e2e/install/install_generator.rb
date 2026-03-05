# frozen_string_literal: true

require "rails/generators/base"

module AgentE2e
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Sets up AI-powered E2E testing with Playwright, OpenAI, and letter_opener_web"

      def copy_agent_test_files
        say "Creating agent-tests/ directory...", :green
        directory_path = "agent-tests"

        copy_file "config.js", "#{directory_path}/config.js"
        copy_file "browser.js", "#{directory_path}/browser.js"
        copy_file "ai.js", "#{directory_path}/ai.js"
        copy_file "agent.js", "#{directory_path}/agent.js"
        copy_file "package.json", "#{directory_path}/package.json"
        create_file "#{directory_path}/tests.md"
      end

      def copy_e2e_script
        say "Creating bin/e2e script...", :green
        copy_file "e2e", "bin/e2e"
        chmod "bin/e2e", 0o755
      end

      def configure_development_mailer
        say "Configuring letter_opener_web for development...", :green
        env_file = "config/environments/development.rb"

        return if File.read(env_file).include?("letter_opener_web")

        inject_into_file env_file, before: /^end\s*\z/ do
          "\n  config.action_mailer.delivery_method = :letter_opener_web\n  config.action_mailer.perform_deliveries = true\n"
        end
      end

      def configure_test_mailer
        say "Configuring letter_opener_web for test...", :green
        env_file = "config/environments/test.rb"
        content = File.read(env_file)

        if content.include?("delivery_method = :test")
          gsub_file env_file,
            "config.action_mailer.delivery_method = :test",
            "config.action_mailer.delivery_method = :letter_opener_web"
        elsif !content.include?("letter_opener_web")
          inject_into_file env_file, before: /^end\s*\z/ do
            "\n  config.action_mailer.delivery_method = :letter_opener_web\n  config.action_mailer.perform_deliveries = true\n"
          end
        end

        unless content.include?("default_url_options") && content.include?("3001")
          inject_into_file env_file, before: /^end\s*\z/ do
            "\n  config.action_mailer.default_url_options = { host: \"localhost\", port: 3001 }\n"
          end
        end
      end

      def add_letter_opener_route
        say "Adding letter_opener_web route...", :green
        route_file = "config/routes.rb"

        return if File.read(route_file).include?("LetterOpenerWeb")

        inject_into_file route_file, before: /^end\s*\z/ do
          "\n  if Rails.env.local?\n    mount LetterOpenerWeb::Engine, at: \"/letter_opener\"\n  end\n"
        end
      end

      def update_gitignore
        say "Updating .gitignore...", :green
        gitignore = ".gitignore"

        entries = [
          "",
          "# Agent E2E tests",
          "/agent-tests/node_modules",
          "/agent-tests/failures.md",
          "/agent-tests/screenshots",
        ]

        existing = File.exist?(gitignore) ? File.read(gitignore) : ""

        entries_to_add = entries.reject { |e| e.empty? ? false : existing.include?(e.strip) }

        return if entries_to_add.empty?

        append_to_file gitignore, entries_to_add.join("\n") + "\n"
      end

      def install_node_dependencies
        say "Installing Node.js dependencies...", :green
        inside("agent-tests") do
          run "npm install"
        end
      end

      def install_playwright_browsers
        say "Installing Playwright Chromium browser...", :green
        inside("agent-tests") do
          run "npx playwright install chromium"
        end
      end

      def print_next_steps
        say ""
        say "=" * 60, :green
        say "  Agent E2E installed successfully!", :green
        say "=" * 60, :green
        say ""
        say "Next steps:", :yellow
        say ""
        say "  1. Add your OpenAI API key to .env:"
        say "     OPENAI_API_KEY=sk-..."
        say ""
        say "  2. Add data-testid attributes to key UI elements:"
        say '     <button data-testid="submit-login">Log in</button>'
        say ""
        say "  3. Create a QA seed user (e.g. in db/seeds.rb):"
        say "     User.find_or_create_by!(email: 'qa@example.com') do |u|"
        say "       u.password = 'Password123!'"
        say "     end"
        say ""
        say "  4. Write test cases in agent-tests/tests.md (one per line):"
        say "     - Log in with qa@example.com and verify the dashboard loads"
        say ""
        say "  5. Run your tests:"
        say "     bin/e2e"
        say ""
      end
    end
  end
end
