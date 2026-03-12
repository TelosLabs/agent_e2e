# frozen_string_literal: true

require "json"
require_relative "llm_client"
require_relative "prompt_builder"

module TechDebt
  module Semantic
    class Triage
      def initialize(config, prompt_path:)
        @config = config
        @prompt_path = prompt_path
        @llm_client = LlmClient.new(config)
      end

      def call(candidates)
        system_prompt = File.read(@prompt_path)
        user_prompt = PromptBuilder.new(candidates: candidates).build
        content = @llm_client.triage(system_prompt: system_prompt, user_prompt: user_prompt)
        parse_json(content)
      end

      private

      def parse_json(content)
        parsed = JSON.parse(strip_code_fences(content))
        return parsed if parsed.is_a?(Array)

        raise "LLM response was not an array"
      rescue JSON::ParserError => e
        raise "Unable to parse LLM JSON response: #{e.message}"
      end

      def strip_code_fences(content)
        content.gsub(/\A```(?:json)?\s*/m, "").gsub(/\s*```\z/m, "").strip
      end
    end
  end
end
