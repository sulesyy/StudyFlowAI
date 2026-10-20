# StudyFlow AI local Gemini proxy

This local-only proxy keeps the Gemini API key out of the iOS app bundle. It binds to `127.0.0.1` by default, does not log prompts or credentials, limits prompt size, and applies a small per-IP request limit.

## Run locally

1. Revoke any API key previously embedded in source code and create a replacement key in Google AI Studio. Check the selected project's quota; creating another key in the same project does not reset its quota.
2. In Terminal, from this folder, create a private local environment file and add the key there:

   ```sh
   cp .env.example .env
   open -e .env
   ```

   Paste the key after `GEMINI_API_KEY=` and save. Keep `.env` private; it is ignored by Git.
3. Start the proxy:

   ```sh
   node server.mjs
   ```

4. Leave that Terminal window open and run StudyFlowAI in the iOS Simulator. Check `http://127.0.0.1:3000/health`; it should return `{"status":"ok","aiConfigured":true}`. The app connects to `http://127.0.0.1:3000/generate`.

The Xcode app target allows local networking for this development-only loopback URL. Do not expose this proxy to the public internet as-is. Before deployment, host it behind HTTPS and add user authentication, abuse controls, and secret rotation. Set the Xcode app target's `AI_PROXY_URL` build setting to the deployed HTTPS endpoint; it is read from the generated app Info.plist.
