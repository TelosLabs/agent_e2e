# Agent E2E

AI-powered end-to-end testing for Rails applications. An OpenAI agent drives a real Chromium browser via Playwright to execute natural-language test cases against your running app.

Write tests like plain English:

```
- Log in, navigate to Settings, and change the display name to "Test User"
- Register a new account, confirm the email, and verify the dashboard loads
- Search for "rails" and verify results appear
```

The agent reads the page, decides what to click/fill/navigate, and reports pass/fail — no selectors to maintain.

## What gets installed

| Component | Purpose |
|---|---|
| `letter_opener_web` | Captures emails in dev/test and exposes them at `/letter_opener` so the agent can handle email confirmations |
| `agent-tests/` directory | Contains the AI agent, browser helpers, and your test cases |
| `bin/e2e` script | One command to boot a test server, run all tests, and clean up |
| Playwright + Chromium | Real browser automation |

## Requirements

- **Ruby** >= 3.1, **Rails** >= 7.0
- **Node.js** >= 18
- **OpenAI API key** (GPT-4o or newer recommended)

## Installation

### Step 1: Add the gem

```ruby
# Gemfile
group :development, :test do
  gem "agent_e2e", git: "https://github.com/TelosLabs/agent_e2e.git"
end
```

```sh
bundle install
```

### Step 2: Set up your environment

Add your OpenAI API key to your `.env` file in the Rails root:

```env
OPENAI_API_KEY=sk-proj-...
```

> **Important:** Make sure `.env` is in your `.gitignore` (Rails apps typically ignore `/.env*` by default). This key is needed both for the install generator (to generate test seeds) and for running the E2E tests.

### Step 3: Run the install generator

```sh
bin/rails generate agent_e2e:install
```

This will:

1. Create `agent-tests/` with all necessary JS files (`config.js`, `browser.js`, `ai.js`, `agent.js`, `tests.md`)
2. Create the `bin/e2e` runner script
3. Configure `letter_opener_web` as the mailer delivery method in **development** and **test** environments
4. Mount the `LetterOpenerWeb` engine at `/letter_opener` in your routes
5. Update `.gitignore` to exclude `node_modules`, `failures.md`, and `screenshots`
6. Run `npm install` in `agent-tests/`
7. Install the Chromium browser for Playwright
8. **Generate `db/test_seeds.rb`** by analyzing your models with OpenAI

The generator reads all your models and `db/schema.rb`, then calls OpenAI to generate `db/test_seeds.rb` with realistic seed data for E2E testing — including a QA user (`qa@example.com` / `Password123!`), associated records, and proper handling of validations, enums, and Devise.

To regenerate seeds after adding new models:

```sh
bin/rails generate agent_e2e:test_seeds
```

The generated file uses `find_or_create_by!` so it's safe to run multiple times. Review and adjust it as needed.

You can override the AI model used with the `SEED_AI_MODEL` environment variable (defaults to `o3`).

### Step 4: Add `data-testid` attributes to your views

The agent can interact with elements by visible text, labels, and roles — but `data-testid` attributes make interactions more reliable, especially for buttons and form elements.

```erb
<button data-testid="submit-login">Log in</button>
<input data-testid="search-input" type="text" placeholder="Search...">
<a data-testid="nav-settings" href="/settings">Settings</a>
```

**Recommendation:** Add `data-testid` to every interactive element (buttons, links, inputs, selects). This doesn't affect your production HTML and makes tests much more stable.

### Step 5: Handle asset compilation (if needed)

If your app uses Tailwind CSS, esbuild, or another build step, uncomment the relevant line in `bin/e2e`:

```sh
# Uncomment if your app needs asset precompilation (e.g. Tailwind CSS):
# echo "==> Compiling assets..."
# bin/rails tailwindcss:build
# bin/rails assets:precompile
```

## Writing tests

Edit `agent-tests/tests.md`. Each line is a test case (lines starting with `#` are comments):

```markdown
# Authentication
- Log in and verify the home page loads
- Try to log in with wrong@example.com / badpassword and verify an error message appears

# Navigation
- Navigate to the About page and verify it contains company information
- Use the search bar to search for "hello" and verify results appear

# Email flows
- Register a new account, click the confirmation link, and verify the account is activated

# Mobile
- On mobile viewport, open the hamburger menu and navigate to Settings
```

**Tips for good test cases:**
- Be specific about what to do and what to verify
- Include the full flow (e.g., "log in, then navigate to X, then do Y")
- The agent knows to use `/letter_opener` for email confirmation automatically
- Add "mobile viewport" in the test description to run with a mobile screen size
- One test case = one logical user journey

## Running tests

```sh
bin/e2e
```

This will:
1. Prepare the test database and seed it with `db/test_seeds.rb`
2. Start a Rails server on port 3001 (configurable via `PORT`)
3. Run each test case with the AI agent
4. Print a summary of results
5. Write `agent-tests/failures.md` with detailed failure reports (if any)
6. Save screenshots on failure to `agent-tests/screenshots/`
7. Clean up: stop the server and reset the database

> If `db/test_seeds.rb` doesn't exist, the script will stop and show you the steps to generate it.

## Configuration

All configuration is via environment variables. Set them in `.env` or pass them directly:

| Variable | Default | Description |
|---|---|---|
| `OPENAI_API_KEY` | *(required)* | Your OpenAI API key |
| `AI_MODEL` | `gpt-5.1` | OpenAI model to use for the test agent |
| `SEED_AI_MODEL` | `o3` | OpenAI model to use for generating test seeds |
| `BASE_URL` | `http://localhost:3000` | Base URL of the app (overridden to port 3001 by `bin/e2e`) |
| `MAX_STEPS` | `25` | Maximum steps per test before timeout |
| `ACTION_TIMEOUT` | `8000` | Timeout in ms for each browser action |
| `QA_EMAIL` | `qa@example.com` | Login email for the test user |
| `QA_PASSWORD` | `Password123!` | Login password for the test user |
| `PORT` | `3001` | Port for the test server (used by `bin/e2e`) |

## How it works

1. The agent reads the current page (visible text + interactive controls)
2. Sends a snapshot to OpenAI with the test goal and action history
3. OpenAI returns the next action (click, fill, navigate, etc.)
4. The agent executes the action via Playwright
5. Repeats until the goal is done, fails, or hits the step limit
6. Loop detection aborts tests that get stuck cycling the same actions

## Output files

| File | Description |
|---|---|
| `db/test_seeds.rb` | AI-generated seed data for E2E testing (generated by `agent_e2e:test_seeds`) |
| `agent-tests/tests.md` | Your test cases (you write this) |
| `agent-tests/failures.md` | Detailed failure reports with action history (auto-generated, gitignored) |
| `agent-tests/screenshots/` | Screenshots captured on failure (auto-generated, gitignored) |

## Troubleshooting

**"db/test_seeds.rb not found"**
Run `bin/rails generate agent_e2e:test_seeds` to generate it. Make sure `OPENAI_API_KEY` is set in your `.env`.

**"No test cases found in tests.md"**
Add at least one test case line (not starting with `#`) to `agent-tests/tests.md`.

**Agent keeps failing on email confirmation**
Make sure `letter_opener_web` is properly configured. Visit `http://localhost:3000/letter_opener` in development to verify it works. Check that your mailer is actually sending emails (e.g., Devise confirmation).

**Tests time out**
Increase `MAX_STEPS` or `ACTION_TIMEOUT` in your `.env`. Some complex flows need more steps.

**Agent clicks the wrong elements**
Add `data-testid` attributes to ambiguous elements. The agent prefers `data-testid` for reliable targeting.

**Asset compilation issues**
Uncomment the asset build step in `bin/e2e` that matches your setup.

**Regenerating seeds after model changes**
Run `bin/rails generate agent_e2e:test_seeds` again. It will overwrite the existing file.

## License

MIT
