### 1. Critical Missing Features & UI Modules to Include

1. **Voice Agents Studio (`Agents` — Top-Level Nav Item):**
* *Why it's missing:* You have **Campaigns** (who to call) and **Knowledge Base / MCP Gateway** (what the AI knows/does), but you need a dedicated **Voice Agents** screen where users create, clone, and configure the actual agent personas (voice selection, speaking speed, greeting script, system prompt, and attached Knowledge + MCP tools).
* *Subscription Tie-In:* This is also where users clearly see their active slot meter (e.g., `1 / 1 Free Agent Active` or `4 / 10 Pro Concurrent Agents`).


2. **Call Logs & Live Call Monitor (`Call Logs` — Top-Level Nav Item):**
* *Why it's missing:* **Analytics** shows aggregated charts, while **Call Logs** provides the granular, call-by-call operational feed. Admins need an audio player for recordings, speaker-separated transcripts, latency breakdowns (`< 600ms` badge), and an expandable **MCP Tool Execution Trace** showing which API calls fired mid-call and their HTTP status codes.
* *Live Monitor:* Include a **"Live Calls"** filter tab so supervisors can see active calls in real time and trigger a **Human Takeover / Whisper** if an agent gets stuck.


3. **Phone Numbers & Telephony Setup (`Phone Numbers` — Under Settings or Top-Level):**
* *Why it's missing:* Companies need a dedicated screen to buy/provision Indian (`+91`) or global phone numbers, connect their own SIP trunks (Exotel/Plivo/Twilio), and map which inbound number routes to which Voice Agent.


4. **Interactive Agent Playground / Test Call Simulator:**
* *Why it's missing:* Before launching an outbound campaign to 10,000 customers, admins must be able to click **"Test Agent"** right inside the browser (via WebRTC mic) or trigger a test call to their own phone to verify RAG answers and MCP tool execution safely.


5. **DNC (Do-Not-Call) & Compliance Guardrails (Inside `Contacts` & `Campaigns`):**
* *Why it's missing:* Outbound voice campaigns in India (TRAI DND rules) and globally (TCPA) require automated DNC list suppression, configurable calling windows (e.g., `9:00 AM – 8:00 PM` local time), and automatic retry backoff rules for unanswered calls.


6. **Developer API Keys & Outbound Webhooks (`Developers` — Inside `Settings`):**
* *Why it's missing:* Real-time customers like NoBroker trigger calls programmatically via `POST /v1/calls/outbound` and receive call outcomes via webhooks (`call.completed`, `tool.executed`). Admins need UI controls to rotate Solter API keys and configure webhook endpoints.



---

### 2. Complete UI Design & Functional Summary for Solter AI

#### A. Visual Identity & Layout System

* **Theme & Palette:** Sleek dark-first interface anchored in deep obsidian (`#09090B`) with elevated slate cards (`#111318`), subtle 1px glass borders, and electric cyan (`#38BDF8` / `#00E5FF`) accents matching the Solter AI logo. (Optional light-mode toggle for daytime operations).
* **Typography & Responsiveness:** Clean geometric sans-serif headings paired with high-legibility UI fonts and monospace (`JetBrains Mono`) for API schemas, phone numbers, and latency metrics. Collapsible left sidebar on desktop that transforms into a bottom tab bar + slide-over drawer on mobile devices.

#### B. Authentication & Multi-Organization Flow

1. **Auth & Verification:** Clean split-screen sign-up/login with email verification (OTP or magic link) and SSO readiness.
2. **Organization Switcher (`Workspace Hub`):** Post-login screen listing all organizations the user belongs to (with role badges like `Owner`, `Admin`, `Operator`), plus a **"Create New Organization"** flow. A persistent org-switcher dropdown also sits at the top-left of the sidebar for instant switching.

#### C. Refined Sidebar Navigation & Core Modules

| Nav Item (Refined Name) | Core UI & Functionality |
| --- | --- |
| **Dashboard** | Executive overview: Total calls (Inbound/Outbound), Call Resolution Rate, Average Turn Latency (`ms`), Active Concurrent Agents gauge (`1/1` Free vs `N/M` Pro), and recent call activity feed. |
| **Voice Agents** *(New)* | Create and manage AI agent personas. Configure voice model, language/accent, greeting message, system prompt, linked Knowledge Base collections, and enabled MCP tools. Includes an in-browser **Test Call Simulator**. |
| **Campaigns** | Outbound call orchestrator. Select a Voice Agent, target a Contact Segment, set campaign goals (e.g., *Visit Scheduling*, *CSAT Survey*, *Product Feedback*), configure calling hours/retry rules, and monitor live progress. |
| **Call Logs** *(New)* | Granular call history & live monitor. Filter by status (`Completed`, `Transferred`, `Voicemail`, `Failed`). Inspect audio waveform playback, full transcript, AI summary, and step-by-step MCP API execution logs. |
| **Contacts** | Customer CRM table with CSV/Excel bulk import & export, custom metadata columns (e.g., `property_id`, `order_id` passed as context into calls), tagging, search/filters, and DNC suppression flags. |
| **Knowledge Base** | Upload, edit, or organize PDFs, Markdown docs, FAQs, and product catalogs into collections. Shows indexing status (`Ready`, `Processing`) and lets users test semantic retrieval chunks. |
| **MCP Gateway** | Upload OpenAPI/Swagger specs or connect pre-built connectors (Twilio, Exotel, WhatsApp, HubSpot). Toggle individual endpoints ON/OFF, flatten parameters, inject encrypted API keys/OAuth credentials, and run sandbox tests. |
| **Analytics** | Deep-dive visual reports: Call outcomes over time, latency percentiles (p50/p95), top triggered MCP tools, failure breakdowns, and cost-per-resolved-call savings vs. human BPO benchmarks. |
| **Marketplace** | Directory of one-click installable MCP tool packs, industry agent templates (Real Estate, E-Commerce, Logistics), and premium voice packs available via one-time purchase or monthly add-on. |
| **Settings** | Organization profile, **Phone Numbers & SIP Trunks**, **Team & RBAC** (custom roles & permissions), **Developer API Keys & Webhooks**, and audit logs. |
| **Billing** | Subscription tier management (Free: 1 active agent / 1 concurrent call; Paid tiers: multi-agent parallel concurrency), real-time minute/token usage meters, payment methods, and downloadable invoices. |
| **Profile & Support** | Accessible from the bottom-left user menu: Personal profile/security settings, interactive documentation, searchable FAQs, live chat, and support ticket tracker. |

---

### D. Subscription-Driven Concurrency UX

* **Free Tier Experience:** Users can build and test 1 Voice Agent and run 1 active call at a time. Attempting to launch a parallel campaign or create a second active agent displays a clean, non-intrusive upgrade prompt explaining parallel call capacity.
* **Subscribed Tier Experience:** Users spin up multiple specialized agents simultaneously (e.g., *Agent A* handling inbound support while *Agent B* and *Agent C* run parallel outbound follow-up campaigns), with a real-time **Concurrency Monitor** in the top header showing active vs. available call slots.
