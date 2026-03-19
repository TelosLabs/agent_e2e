import dotenv from "dotenv";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import OpenAI from "openai";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../.env") });

const apiKey = process.env.AI_API_KEY || process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error("Error: Set AI_API_KEY (or OPENAI_API_KEY) in your .env file.");
  process.exit(1);
}

const clientOptions = { apiKey };
if (process.env.AI_BASE_URL) {
  let baseURL = process.env.AI_BASE_URL.trim();
  baseURL = baseURL.replace(/\/$/, "");
  baseURL = baseURL.replace(/\/chat\/completions$/, "");
  clientOptions.baseURL = baseURL;
}

export const client = new OpenAI(clientOptions);
export const BASE_URL = process.env.BASE_URL || "http://localhost:3000";
export const MAX_STEPS = parseInt(process.env.MAX_STEPS || "25", 10);
export const MODEL = process.env.AI_MODEL || "gpt-4o";
export const ACTION_TIMEOUT = parseInt(process.env.ACTION_TIMEOUT || "8000", 10);
export const TESTS_DIR = __dirname;

export const QA_EMAIL = process.env.QA_EMAIL || "qa@example.com";
export const QA_PASSWORD = process.env.QA_PASSWORD || "Password123!";
