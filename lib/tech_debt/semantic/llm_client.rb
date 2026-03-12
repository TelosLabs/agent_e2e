# frozen_string_literal: true

require "faraday"
require "json"
require "openai"

module TechDebt
  module Semantic
    class LlmClient
      GITHUB_MODELS_URL = "https://models.github.ai/inference/chat/completions"

      def initialize(config)
        @config = config
      end

      def triage(system_prompt:, user_prompt:)
        provider = @config.llm.fetch("provider", "github")

        case provider
        when "github"
          triage_via_github_models(system_prompt, user_prompt)
        when "openai"
          triage_via_openai(system_prompt, user_prompt)
        else
          raise ArgumentError, "Unknown LLM provider: #{provider}. Supported: github, openai"
        end
      end

      private

      def triage_via_github_models(system_prompt, user_prompt)
        token = ENV.fetch(@config.llm.fetch("api_key_env", "GITHUB_TOKEN"))
        model = @config.llm.fetch("model")
        model = "openai/#{model}" unless model.include?("/")

        body = {
          model: model,
          temperature: @config.llm.fetch("temperature", 0.2),
          max_tokens: @config.llm.fetch("max_tokens", 4096),
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_prompt }
          ]
        }

        conn = Faraday.new do |f|
          f.request :json
          f.response :json
        end

        response = conn.post(GITHUB_MODELS_URL) do |req|
          req.headers["Authorization"] = "Bearer #{token}"
          req.headers["Accept"] = "application/vnd.github+json"
          req.headers["X-GitHub-Api-Version"] = "2022-11-28"
          req.body = body
        end

        raise Faraday::UnauthorizedError, "GitHub Models returned 401. Ensure your token has 'models' scope (classic PAT) or 'models: read' (fine-grained PAT)." if response.status == 401
        raise "GitHub Models API error: #{response.status} #{response.body}" unless response.success?

        extract_content(response.body)
      end

      def triage_via_openai(system_prompt, user_prompt)
        key = ENV.fetch(@config.llm.fetch("api_key_env", "OPENAI_API_KEY"))
        client = OpenAI::Client.new(access_token: key)
        response = client.chat(
          parameters: {
            model: @config.llm.fetch("model"),
            temperature: @config.llm.fetch("temperature", 0.2),
            max_tokens: @config.llm.fetch("max_tokens", 4096),
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: user_prompt }
            ]
          }
        )

        extract_content(response)
      end

      def extract_content(response)
        message = response.dig("choices", 0, "message", "content")
        return message if message.is_a?(String)

        if message.is_a?(Array)
          return message.filter_map { |block| block["text"] }.join("\n")
        end

        raise "Unexpected LLM response format"
      end
    end
  end
end
