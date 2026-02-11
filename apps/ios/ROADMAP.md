# Clawdbot iOS App - Complete Product & Architecture Roadmap

**Version:** 2.0
**Date:** February 2026
**Status:** Living Document
**Cost Model:** Maximize free resources (Ollama/Groq/Gemini), minimize Claude API usage

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Assessment](#current-state-assessment)
3. [Product Vision](#product-vision)
4. [Technical Architecture](#technical-architecture)
5. [Feature Roadmap (Phases)](#feature-roadmap-phases)
6. [Data Models & API Contracts](#data-models--api-contracts)
7. [UI/UX Specifications](#uiux-specifications)
8. [Real-Time Communication Architecture](#real-time-communication-architecture)
9. [Offline & Sync Strategy](#offline--sync-strategy)
10. [Testing & Quality Assurance](#testing--quality-assurance)
11. [Deployment & CI/CD Pipeline](#deployment--cicd-pipeline)
12. [Security & Privacy](#security--privacy)
13. [Performance Optimization](#performance-optimization)
14. [Analytics & Monitoring](#analytics--monitoring)
15. [Appendix: API Endpoints](#appendix-api-endpoints)

---

## Executive Summary

The Clawdbot iOS app is Will's **personal command center** for managing his AI agent federation (Jordan, Hunter, Bob, Clawd). It is NOT a generic Clawdbot node app for public consumption.

**Core Purpose:**
- Monitor and control 4 autonomous AI agents (trading, sales, engineering, orchestration)
- Unified dashboard for work, personal life, trading, and HOA management
- Real-time visibility into agent activity and decision-making
- Direct communication with agents via natural language
- Native mobile experience with Coinbase-inspired design system

**Key Principles:**
1. **Personal First:** Built for Will's specific workflows and preferences
2. **Real-Time:** WebSocket connections for live agent updates
3. **Native Feel:** SwiftUI, no web views (except Screen tab), iOS design patterns
4. **Agent-Centric:** Every feature surfaces agent intelligence
5. **Coinbase UI:** Clean, professional, data-dense financial app aesthetic

---

## Current State Assessment

### Existing Features (Built)

**App Structure:**
- 5 tabs: Today, Personal, Work, Trading, HOA
- TabView with custom Coinbase color scheme (CB.blue, CB.green, CB.red)
- StatusPill overlay showing gateway connection + activity
- VoiceWakeToast for voice command feedback

**Tab Implementations:**

**Today Tab:**
- ❌ **Not implemented** (placeholder view)
- **Needed:** Notification bar, Maps integration, Calendar view, Clawd chat

**Personal Tab:**
- ✅ **Partially implemented**
- Has: Responses section (iMessage/email), Smart Home section, Lists section
- Needs: Real data integration with ClawdV2 backend

**Work Tab:**
- ✅ **Partially implemented**
- Has: Emails section (Outlook), Leads section (Hunter agent), To-do section
- Needs: Real-time Hunter prospect updates, Salesforce integration

**Trading Tab:**
- ✅ **Fully implemented**
- P&L chart with scrubbing
- Open positions list
- Recent trades (closed positions)
- ClawdV2Client integration for Jordan's Kalshi data
- Coinbase-style design (hero stats, charts, time range picker)

**HOA Tab:**
- ✅ **Partially implemented**
- Has: Emails section, Projects section, To-do section
- Needs: Harvard HOA specific data sources

**Core Infrastructure:**
- ✅ Gateway connection (GatewayConnectionController)
- ✅ ClawdV2Client (HTTP REST API)
- ✅ Voice Wake Manager (local STT + command routing)
- ✅ Camera Controller (photo/video capture)
- ✅ Location Service (GPS tracking)
- ✅ Screen Record Service (screen capture)
- ✅ Chat interface (IOSGatewayChatTransport)
- ✅ Watch relay (Apple Watch companion)
- ✅ Keychain storage (secure credentials)
- ✅ Coinbase Design System (CoinbaseDesignSystem.swift)

### Technical Debt & Gaps

**Critical:**
1. ❌ No WebSocket implementation (polling REST API only)
2. ❌ No offline-first architecture (network failures = broken UI)
3. ❌ No background task support (app must be foregrounded)
4. ❌ Limited error handling and retry logic
5. ❌ No analytics/crash reporting

**High Priority:**
1. ⚠️ Today Tab completely missing
2. ⚠️ Personal/Work/HOA tabs have mock data
3. ⚠️ No agent "thoughts" or reasoning visibility
4. ⚠️ No push notifications for agent decisions
5. ⚠️ No deep linking for actions (open specific trade, lead, email)

**Medium Priority:**
1. Voice wake word detection only works in foreground
2. No iPad optimization (scales iPhone UI)
3. No dark mode testing (CB colors may need adjustment)
4. No accessibility audit (VoiceOver, Dynamic Type)

---

## Product Vision

### North Star

**"The iOS app should feel like having Will's entire life in his pocket, with AI agents as intelligent assistants proactively managing everything while keeping him informed and in control."**

### User Personas

**Primary:** Will Shanahan
- **Context:** Busy professional managing multiple roles (Smartsheet SDR, trader, HOA board member)
- **Goals:**
  - Stay informed about agent activity without constant monitoring
  - Quickly review and approve high-impact decisions (trades, outreach, deployments)
  - Communicate with agents naturally via voice/text
  - Track progress on work/personal/HOA tasks
  - Monitor trading P&L and positions in real-time
- **Pain Points:**
  - Information overload from 4 autonomous agents
  - Context switching between work/personal/HOA domains
  - Missing important agent decisions while mobile
  - Lack of visibility into agent reasoning

### Key Use Cases

1. **Morning Routine (7:00 AM):**
   - Open app → Today Tab shows: morning briefing from Clawd, calendar for the day, weather, commute time
   - Swipe to Trading Tab → check overnight P&L, review Jordan's trades while sleeping
   - Swipe to Work Tab → scan Hunter's overnight lead research, top 3 prospects to contact today

2. **Commute (8:30 AM):**
   - Voice wake: "Hey Clawd, what's on my calendar?"
   - Clawd responds via voice + updates Today Tab with visual
   - Push notification: "Jordan executed BUY_YES on KXBTC15M @95¢ (edge: 12¢)"
   - Tap notification → deep link to TradingTab showing the specific trade

3. **Work Day (9 AM - 5 PM):**
   - Work Tab always visible: emails auto-triaged by Clawd (respond/delegate/archive)
   - Hunter surfaces high-value leads with context (LinkedIn profile, tech stack, pain points)
   - Tap lead → review Hunter's research + suggested outreach → approve/edit/reject
   - Push notification: "Bob deployed clawd-v2.1 to GCP (tests passing)"

4. **Evening Review (6:00 PM):**
   - Clawd sends evening briefing: "Jordan made 3 trades (+$12.50), Hunter contacted 8 leads (2 replies), Bob fixed 1 bug"
   - Today Tab shows: what got done, what needs attention tomorrow, family calendar
   - HOA Tab: check project updates, upcoming meetings, outstanding to-dos

5. **Late Night Trading (11:00 PM):**
   - Trading Tab: Jordan's real-time positions, P&L fluctuating with market moves
   - Tap position → see Jordan's reasoning: "High conviction - Trump odds vs. actual polling data"
   - Voice command: "Jordan, why did you buy this?" → agent explains decision

---

## Technical Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                        │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │  Today   │ Personal │   Work   │ Trading  │   HOA    │      │
│  │   Tab    │   Tab    │   Tab    │   Tab    │   Tab    │      │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘      │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              App Model (Observable)                       │  │
│  │  - Gateway connection state                               │  │
│  │  - Voice wake manager                                     │  │
│  │  - Location/Camera/Screen services                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Network Layer                                │  │
│  │  ┌─────────────────┬──────────────────┬────────────────┐ │  │
│  │  │ ClawdV2Client   │ WebSocketManager │ PushNotif Svc  │ │  │
│  │  │ (REST API)      │ (Live Updates)   │ (APNs)         │ │  │
│  │  └─────────────────┴──────────────────┴────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Data Layer (CoreData / SwiftData)            │  │
│  │  - Trades, Positions, P&L History (Jordan)                │  │
│  │  - Leads, Prospects, Pipeline (Hunter)                    │  │
│  │  - Emails, Tasks, Projects (All agents)                   │  │
│  │  - Chat history, Voice commands                           │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            ▼
                     Network (WiFi/Cellular)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Clawd Federation Backend                        │
│  ┌──────────┬──────────┬──────────┬──────────────────────────┐ │
│  │  Jordan  │  Hunter  │   Bob    │        Clawd             │ │
│  │ (Trader) │  (SDR)   │ (SRE)    │   (Orchestrator)         │ │
│  └──────────┴──────────┴──────────┴──────────────────────────┘ │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Redis Pub/Sub (Synapse - Nervous System)          │  │
│  │  - Agent messages (STATUS_REPORT, TRADE_EXECUTED, etc.)   │  │
│  │  - Heartbeats (30s intervals)                              │  │
│  │  - Pain signals (errors, warnings)                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              HTTP API Server (FastAPI)                     │  │
│  │  - /api/v2/trades                                          │  │
│  │  - /api/v2/positions                                       │  │
│  │  - /api/v2/agents/status                                   │  │
│  │  - /api/v2/chat (send/receive)                             │  │
│  │  - /ws/live (WebSocket endpoint)                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │             Databases (SQLite + Redis)                     │  │
│  │  - jordan.db (trades, positions, P&L)                      │  │
│  │  - hunter.db (leads, prospects, outreach)                  │  │
│  │  - memory.db (episodic, semantic, lessons learned)         │  │
│  │  - Redis (real-time state, pub/sub)                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            ▼
                   External Integrations
┌──────────┬──────────┬──────────┬──────────┬──────────────────┐
│  Kalshi  │Smartsheet│  Gmail   │ iMessage │   Calendar, etc. │
│  (API)   │  (API)   │  (CDP)   │  (imsg)  │   (Many more)    │
└──────────┴──────────┴──────────┴──────────┴──────────────────┘
```

### Core Components

#### 1. **Network Layer**

**ClawdV2Client (REST API):**
- Base URL: `http://localhost:28789` (local) or `http://34.162.215.220:18789` (GCP)
- Authentication: Session token in Keychain
- Endpoints:
  - `GET /api/v2/agents/status` → All agent states + heartbeats
  - `GET /api/v2/trades` → Jordan's trades
  - `GET /api/v2/positions` → Open Kalshi positions
  - `GET /api/v2/pnl/history` → Historical P&L data
  - `GET /api/v2/leads` → Hunter's prospect pipeline
  - `POST /api/v2/chat` → Send message to agent
  - `GET /api/v2/briefing/morning` → Clawd's morning briefing

**WebSocketManager (Real-Time):**
- WebSocket URL: `ws://localhost:28789/ws/live` or `wss://34.162.215.220:18789/ws/live`
- Protocol: JSON messages with `type`, `source`, `payload`
- Message types:
  - `HEARTBEAT` (every 30s from each agent)
  - `TRADE_EXECUTED` (Jordan trade notification)
  - `TRADE_CLOSED` (Jordan position closed)
  - `LEAD_QUALIFIED` (Hunter found hot lead)
  - `AGENT_STATE_CHANGE` (emotional state shift)
  - `PAIN_SIGNAL` (agent error/warning)
  - `BRIEFING_READY` (Clawd completed briefing)
- Reconnection: Exponential backoff (1s, 2s, 4s, 8s, max 30s)
- Ping/Pong: Send ping every 15s, disconnect if no pong in 30s

**PushNotificationService (APNs):**
- Device token registration on app launch
- Backend sends notifications via APNs for:
  - High-impact trades (P&L > $50 or |edge| > 15¢)
  - Hot leads (Hunter qualification score > 0.8)
  - System alerts (agent down, safety violation)
  - Briefing ready (morning/evening)
- Deep links: `clawdbot://trade/:id`, `clawdbot://lead/:id`, `clawdbot://chat/:agent`

#### 2. **Data Layer**

**Local Persistence:** SwiftData (iOS 17+) or CoreData fallback

**Entities:**

**Trade:**
- `id: String` (UUID)
- `ticker: String`
- `side: String` (YES/NO)
- `quantity: Int`
- `entryPriceCents: Int`
- `exitPriceCents: Int?`
- `pnlCents: Int`
- `status: String` (OPEN/CLOSED)
- `timestamp: Date`
- `reasoning: String?` (Jordan's decision rationale)

**Position:**
- `id: String`
- `marketId: String`
- `marketTitle: String`
- `side: String`
- `quantity: Int`
- `avgPriceCents: Int`
- `currentPriceCents: Int?`
- `unrealizedPnlCents: Int`
- `timestamp: Date`

**Lead:**
- `id: String`
- `companyName: String`
- `contactName: String`
- `contactTitle: String`
- `email: String`
- `phone: String?`
- `qualificationScore: Double` (0-1)
- `techStack: [String]`
- `painPoints: [String]`
- `hunterNotes: String`
- `status: String` (NEW/CONTACTED/REPLIED/QUALIFIED/LOST)
- `lastContactedAt: Date?`

**ChatMessage:**
- `id: String`
- `agent: String` (jordan/hunter/bob/clawd)
- `sender: String` (user/agent)
- `text: String`
- `timestamp: Date`
- `metadata: JSON` (attachments, thinking tokens, etc.)

**Sync Strategy:**
- On app launch: Fetch last 24h of data from backend
- WebSocket: Real-time updates append to local store
- Pull-to-refresh: Force sync from backend
- Background refresh: Every 15min if app backgrounded < 4 hours

#### 3. **Voice System**

**Architecture:**
```
User Voice Input
    ↓
iOS Speech Recognition (on-device)
    ↓
VoiceWakeManager (local wake word detection: "Hey Clawd")
    ↓
Command extraction (regex patterns for common commands)
    ↓
┌─────────────────────────────────────┐
│  Local Command Routing:             │
│  - "what's my P&L?" → Trading Tab   │
│  - "show my leads" → Work Tab       │
│  - "what's on my calendar?" → Today │
└─────────────────────────────────────┘
    ↓ (if not matched locally)
Send to Clawd via WebSocket for NLU
    ↓
Clawd routes to appropriate agent (Jordan/Hunter/Bob)
    ↓
Agent processes + responds
    ↓
Response arrives via WebSocket
    ↓
TTS (iOS AVSpeechSynthesizer) + Visual update
```

**Wake Words:**
- Primary: "Hey Clawd"
- Alternatives: "Clawd", "Yo Clawd" (configurable)

**Local Commands (No backend needed):**
- "Show Trading" → Switch to Trading Tab
- "Show my leads" → Switch to Work Tab
- "What's my P&L?" → Trading Tab + voice: "Your total P&L is $X.XX"
- "How many open trades?" → Count positions + voice response

**Backend Commands (Require agent processing):**
- "Jordan, why did you buy this?" → Send to Jordan, get reasoning
- "Hunter, who should I contact today?" → Hunter returns prioritized lead list
- "Clawd, give me a briefing" → Clawd generates real-time status summary

---

## Feature Roadmap (Phases)

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Establish core infrastructure for real-time communication and offline support

**Deliverables:**
1. **WebSocket Integration**
   - WebSocketManager class (connection, reconnection, message parsing)
   - Subscribe to all agent channels on connect
   - Handle HEARTBEAT, TRADE_EXECUTED, LEAD_QUALIFIED messages
   - Update local store on message receive

2. **SwiftData Persistence**
   - Define models: Trade, Position, Lead, ChatMessage, AgentStatus
   - Migration from in-memory state to local database
   - Sync logic: fetch on launch, update on WebSocket, background refresh

3. **Error Handling & Retry**
   - Network error recovery (exponential backoff)
   - UI error states (empty states, retry buttons, offline mode)
   - Logging framework (OSLog for debugging, future Sentry integration)

4. **Today Tab - Basic Implementation**
   - Morning briefing view (fetch from `/api/v2/briefing/morning`)
   - Calendar integration (EventKit - read-only)
   - Weather widget (WeatherKit API)
   - Clawd chat interface (reuse ChatSheet component)

**Acceptance Criteria:**
- ✅ App stays connected to WebSocket for 24+ hours without disconnect
- ✅ Trade notifications appear < 1 second after Jordan executes
- ✅ App works offline (shows last-synced data, queues outgoing messages)
- ✅ Today Tab displays real briefing from Clawd

**Testing:**
- Unit tests for WebSocketManager (reconnection, message parsing)
- Integration tests with local Clawd backend
- UI tests for offline mode (disable network, verify graceful degradation)

### Phase 2: Agent Visibility & Context (Weeks 3-4)

**Goal:** Surface agent reasoning and decision-making process

**Deliverables:**
1. **Agent Reasoning Panel**
   - New view: `AgentThoughtView.swift`
   - Shows agent's "thinking" for each decision (trades, leads, emails)
   - Data source: `reasoning` field in Trade/Lead models
   - UI: Expandable card with:
     - Decision summary ("BUY YES on KXBTC15M")
     - Confidence score (0-100%)
     - Key factors (bullet list)
     - Risk assessment
     - Alternative considered

2. **Agent Status Dashboard**
   - New view: `AgentStatusView.swift`
   - Shows all 4 agents: current state, heartbeat, recent activity
   - Data source: `/api/v2/agents/status` + WebSocket heartbeats
   - UI:
     - Agent cards (name, avatar, emotional state, status indicator)
     - Last action timestamp ("2m ago: Executed trade on KXBTC15M")
     - Tap → Agent detail view (full activity log)

3. **Notification Center**
   - New tab/overlay: Bell icon in nav bar
   - Shows agent decisions requiring review/approval
   - Categories: Trades, Leads, Deployments, Errors
   - Actions: Approve, Reject, Snooze, View Details
   - Mark as read/unread, clear all

4. **Deep Linking**
   - Handle URLs: `clawdbot://trade/:id`, `clawdbot://lead/:id`, `clawdbot://agent/:name`
   - Push notification tap → Open specific item
   - Voice command → Navigate to relevant tab/view

**Acceptance Criteria:**
- ✅ Every trade shows Jordan's reasoning (why, confidence, risks)
- ✅ User can see agent heartbeats and know all agents are alive
- ✅ Tapping push notification opens the relevant item (deep link)
- ✅ Notification center shows unread agent decisions

**Testing:**
- UI tests for agent reasoning panel (tap trade → see reasoning)
- Integration tests for deep linking (send push → tap → verify navigation)
- Manual testing: Kill agent on backend, verify app shows "agent down" status

### Phase 3: Enhanced Trading Experience (Weeks 5-6)

**Goal:** Match Coinbase's trading UX with Kalshi prediction markets

**Deliverables:**
1. **Advanced Charts**
   - Multi-timeframe P&L chart (1D, 1W, 1M, 3M, 1Y, ALL)
   - Market price charts for open positions (real-time Kalshi data)
   - Chart scrubbing with haptic feedback
   - Annotations: Trade entry/exit points on chart

2. **Position Details View**
   - Tap position → Full detail screen:
     - Market description (event, resolution criteria)
     - Current odds vs. entry odds
     - Unrealized P&L (real-time)
     - Jordan's entry reasoning + current conviction
     - Similar historical trades (win rate, avg P&L)
     - Close position button (manual override)

3. **Trade History & Analytics**
   - Filterable trade list (date range, side, market type, outcome)
   - Win rate by market category (politics, sports, economics)
   - P&L distribution histogram
   - Best/worst trades of all time
   - Sharpe ratio, max drawdown, other risk metrics

4. **Paper Trading Mode Indicator**
   - Visual badge: "PAPER TRADING" in header (prevent confusion)
   - Settings toggle: Switch to real trading (requires confirmation + risk warnings)

**Acceptance Criteria:**
- ✅ Charts match Coinbase quality (smooth, interactive, beautiful)
- ✅ User can tap any trade and see full context (why Jordan made it)
- ✅ Position detail view shows real-time market odds
- ✅ Clear visual indicator that this is paper trading (not real money)

**Testing:**
- Snapshot tests for charts (verify rendering at all timeframes)
- Integration tests for position close (tap button → WebSocket message → backend confirms)
- Performance tests: Chart scrolling at 60fps with 1000+ trades

### Phase 4: Work & SDR Features (Weeks 7-8)

**Goal:** Make Hunter agent actionable for Will's SDR workflows

**Deliverables:**
1. **Lead Detail View**
   - Tap lead → Full detail screen:
     - Company profile (name, size, industry, tech stack)
     - Contact info (name, title, email, phone, LinkedIn)
     - Hunter's research notes (pain points, buying signals)
     - Suggested outreach template (editable)
     - CRM link (Salesforce deep link)
     - Outreach history (emails sent, replies, next steps)

2. **Outreach Builder**
   - New view: `OutreachComposerView.swift`
   - Pre-filled template from Hunter
   - Editable fields: subject, body, signature
   - Preview mode: See email as recipient
   - Actions: Send now, Schedule send, Save as draft
   - Integration: Outlook API or Gmail API (Will's work email)

3. **Pipeline View**
   - Kanban-style board: Columns (New, Contacted, Replied, Qualified, Lost)
   - Drag-and-drop to change lead status
   - Filters: Industry, company size, qualification score
   - Quick actions: Call (phone URL), Email (compose), View in CRM

4. **Daily Prospecting Checklist**
   - Work Tab shows: "Today's Top 5 Leads" (Hunter's prioritization)
   - Each lead: Quick preview + "Contact" button
   - Progress tracker: "3 of 5 contacted today"
   - Voice command: "Hunter, show me today's leads"

**Acceptance Criteria:**
- ✅ User can review lead, edit outreach, send email in < 30 seconds
- ✅ Hunter's research is actionable (not generic fluff)
- ✅ Pipeline view syncs with Hunter's backend (drag = status change)
- ✅ Daily checklist surfaces Hunter's best leads each morning

**Testing:**
- UI tests for outreach composer (edit, preview, send)
- Integration tests for pipeline drag-and-drop (verify backend update)
- Manual testing: Send real email to test account, verify delivery

### Phase 5: Personal & HOA Automation (Weeks 9-10)

**Goal:** Extend Clawd's orchestration to personal life and HOA management

**Deliverables:**
1. **Smart Home Control**
   - Personal Tab → Smart Home section
   - Device cards: Lights, Thermostat, Locks, Cameras, Sonos
   - Quick actions: Turn on/off, adjust temperature, play music
   - Voice: "Turn on living room lights" → Clawd → SmartThings API
   - Automation view: See Clawd's scheduled actions (bedtime routine, morning wake-up)

2. **Calendar & Reminders**
   - Today Tab → Calendar view (EventKit integration)
   - Tap event → Details + Clawd's context (e.g., "Commute time: 23 min via I-90")
   - Reminders list (due today, overdue, upcoming)
   - Quick add: Voice "Remind me to call Mom at 5pm"

3. **HOA Project Tracking**
   - HOA Tab → Projects section
   - Project cards: Name, status (Planning/In Progress/Blocked/Done), owner, deadline
   - Tap project → Task list, file attachments, notes
   - Add project: Name, description, assign to Bob for tracking

4. **Email Triage**
   - Personal/Work/HOA Tabs → Emails section
   - Clawd auto-categorizes: Respond (urgent), Delegate (assign to agent), Archive (ignore)
   - Quick actions: Reply (open composer), Archive (swipe left), Snooze (swipe right)
   - Voice: "Clawd, read my urgent emails" → TTS reads subject lines

**Acceptance Criteria:**
- ✅ User can control smart home devices from app
- ✅ Calendar shows events with commute time (Clawd adds context)
- ✅ HOA projects tracked with tasks and notes
- ✅ Email triage reduces inbox overwhelm (Clawd handles 80%)

**Testing:**
- Integration tests for smart home control (send command → verify device state)
- Manual testing: Create HOA project → assign tasks → mark complete
- Accessibility testing: VoiceOver navigation for email triage

### Phase 6: Polish & Performance (Weeks 11-12)

**Goal:** Production-ready app with excellent UX and performance

**Deliverables:**
1. **UI Polish**
   - Apply Coinbase design system everywhere (not just Trading Tab)
   - Animations: Smooth transitions, loading skeletons, pull-to-refresh
   - Haptics: Feedback for key actions (trade executed, lead qualified)
   - Empty states: Helpful messages when no data (e.g., "No trades yet")
   - Dark mode audit: Test all screens, adjust colors if needed

2. **Performance Optimization**
   - Lazy loading: Only fetch data for visible tabs
   - Image caching: Cache agent avatars, company logos
   - Memory profiling: Fix leaks, reduce peak memory
   - Network optimization: Batch API calls, compress payloads

3. **Accessibility**
   - VoiceOver support: Label all UI elements
   - Dynamic Type: Support user font size preferences
   - Color contrast: Ensure WCAG AA compliance
   - Reduce motion: Respect system setting

4. **Analytics & Monitoring**
   - Integrate TelemetryDeck or similar (privacy-focused)
   - Track: Screen views, button taps, feature usage
   - Crash reporting: Sentry or Crashlytics
   - Performance metrics: App launch time, API latency

5. **App Store Preparation**
   - Screenshots: 6.5" and 5.5" devices
   - App Preview video: 30s demo (Trading Tab + Voice)
   - Description: Personal AI command center
   - Keywords: Trading, AI, Automation, Productivity
   - Privacy policy: Disclose data usage (agent comms, location)

**Acceptance Criteria:**
- ✅ App feels polished and professional (on par with Coinbase)
- ✅ Smooth 60fps scrolling on all tabs
- ✅ VoiceOver users can navigate entire app
- ✅ Analytics show feature adoption (which tabs most used)

**Testing:**
- Performance testing: Instruments (Time Profiler, Allocations)
- Accessibility audit: Xcode Accessibility Inspector
- Manual testing on real devices: iPhone 14 Pro, iPhone SE 2022, iPad Pro

---

## Data Models & API Contracts

### REST API Endpoints

**Base URL:** `http://localhost:28789` or `http://34.162.215.220:18789`

**Authentication:** `Authorization: Bearer <session_token>` header

#### Agent Status

**GET /api/v2/agents/status**

Response:
```json
{
  "agents": [
    {
      "name": "jordan",
      "state": "CAUTIOUS",
      "heartbeat": {
        "timestamp": "2026-02-10T22:30:00Z",
        "running": true
      },
      "last_action": {
        "type": "TRADE_EXECUTED",
        "timestamp": "2026-02-10T22:28:15Z",
        "description": "BUY YES on KXBTC15M @95¢"
      },
      "stats": {
        "trades_today": 3,
        "pnl_cents": 1250,
        "win_rate": 0.67
      }
    },
    {
      "name": "hunter",
      "state": "HUNGRY",
      "heartbeat": {
        "timestamp": "2026-02-10T22:30:05Z",
        "running": true
      },
      "last_action": {
        "type": "LEAD_QUALIFIED",
        "timestamp": "2026-02-10T21:45:30Z",
        "description": "Qualified TechCorp (score: 0.85)"
      },
      "stats": {
        "leads_today": 12,
        "qualified": 3,
        "contacted": 8
      }
    },
    {
      "name": "bob",
      "state": "VIGILANT",
      "heartbeat": {
        "timestamp": "2026-02-10T22:30:10Z",
        "running": true
      },
      "last_action": {
        "type": "DEPLOYMENT",
        "timestamp": "2026-02-10T18:32:00Z",
        "description": "Deployed clawd-v2.1 to GCP"
      },
      "stats": {
        "deployments_today": 2,
        "incidents": 0,
        "uptime": 0.9995
      }
    },
    {
      "name": "clawd",
      "state": "COMMANDING",
      "heartbeat": {
        "timestamp": "2026-02-10T22:30:00Z",
        "running": true
      },
      "last_action": {
        "type": "BRIEFING",
        "timestamp": "2026-02-10T05:30:00Z",
        "description": "Generated morning briefing"
      },
      "stats": {
        "messages_today": 47,
        "briefings": 2
      }
    }
  ]
}
```

#### Trading Data

**GET /api/v2/trades**

Query params:
- `limit` (int, default 50): Max trades to return
- `since` (ISO datetime): Only trades after this time
- `status` (string: OPEN|CLOSED|ALL, default ALL)

Response:
```json
{
  "trades": [
    {
      "id": "trade_123abc",
      "ticker": "KXBTC15M-24FEB11-T95",
      "market_title": "Will Bitcoin close above $95k on Feb 11?",
      "side": "YES",
      "quantity": 10,
      "entry_price_cents": 95,
      "exit_price_cents": 98,
      "pnl_cents": 300,
      "status": "CLOSED",
      "entry_timestamp": "2026-02-10T14:23:00Z",
      "exit_timestamp": "2026-02-10T18:45:00Z",
      "reasoning": {
        "summary": "Strong upward momentum + whale accumulation",
        "confidence": 0.78,
        "factors": [
          "24h volume up 35%",
          "Support held at $93.5k (3 tests)",
          "On-chain: +12k BTC moved to cold storage"
        ],
        "risks": [
          "Resistance at $96k (historical)",
          "Macro uncertainty (Fed meeting tomorrow)"
        ],
        "edge_cents": 12
      }
    }
  ],
  "total_pnl_cents": 1250,
  "total_trades": 47,
  "win_rate": 0.67
}
```

**GET /api/v2/positions**

Response:
```json
{
  "positions": [
    {
      "id": "pos_456def",
      "market_id": "KXBTC15M-24FEB11-T95",
      "market_title": "Will Bitcoin close above $95k on Feb 11?",
      "side": "YES",
      "quantity": 5,
      "avg_price_cents": 94,
      "current_price_cents": 97,
      "unrealized_pnl_cents": 150,
      "entry_timestamp": "2026-02-10T20:15:00Z",
      "expires_at": "2026-02-11T23:59:00Z"
    }
  ],
  "total_unrealized_pnl_cents": 150,
  "total_positions": 3
}
```

**GET /api/v2/pnl/history**

Query params:
- `timeframe` (string: 1D|1W|1M|3M|1Y|ALL, default 1W)

Response:
```json
{
  "history": [
    {
      "date": "2026-02-09",
      "pnl_cents": 450,
      "cumulative_pnl_cents": 800,
      "trades": 2
    },
    {
      "date": "2026-02-10",
      "pnl_cents": 450,
      "cumulative_pnl_cents": 1250,
      "trades": 3
    }
  ]
}
```

#### Hunter / Leads

**GET /api/v2/leads**

Query params:
- `status` (string: NEW|CONTACTED|REPLIED|QUALIFIED|LOST)
- `limit` (int, default 50)
- `min_score` (float 0-1): Minimum qualification score

Response:
```json
{
  "leads": [
    {
      "id": "lead_789ghi",
      "company_name": "TechCorp Inc.",
      "contact_name": "Jane Smith",
      "contact_title": "VP of Engineering",
      "email": "jane.smith@techcorp.com",
      "phone": "+1-555-123-4567",
      "linkedin_url": "https://linkedin.com/in/janesmith",
      "qualification_score": 0.85,
      "tech_stack": ["React", "Node.js", "AWS"],
      "pain_points": [
        "Manual spreadsheet collaboration (1000+ users)",
        "No version control for project plans",
        "Slow approval workflows (avg 3 days)"
      ],
      "buying_signals": [
        "Posted job listing for 'Project Management Software'",
        "Company grew 40% last year (needs scale)"
      ],
      "hunter_notes": "High fit. Use Smartsheet's Gantt + automation angle. Mention competitor RedCorp switched last quarter.",
      "suggested_outreach": {
        "subject": "Scale your project management like RedCorp",
        "body": "Hi Jane,\n\nI noticed TechCorp is hiring for..."
      },
      "status": "NEW",
      "created_at": "2026-02-10T08:15:00Z",
      "last_contacted_at": null
    }
  ],
  "total_leads": 124,
  "qualified_leads": 18
}
```

**POST /api/v2/leads/:id/contact**

Body:
```json
{
  "outreach_channel": "email",
  "message": "Hi Jane, I noticed TechCorp is hiring..."
}
```

Response:
```json
{
  "success": true,
  "updated_status": "CONTACTED",
  "message": "Outreach email sent via Outlook"
}
```

#### Chat

**POST /api/v2/chat**

Body:
```json
{
  "agent": "clawd",
  "message": "Give me a morning briefing"
}
```

Response:
```json
{
  "agent": "clawd",
  "response": "Good morning! Here's your briefing...",
  "thinking_tokens": 1524,
  "timestamp": "2026-02-10T07:30:00Z"
}
```

**GET /api/v2/chat/history**

Query params:
- `agent` (string: jordan|hunter|bob|clawd)
- `limit` (int, default 50)

Response:
```json
{
  "messages": [
    {
      "id": "msg_abc123",
      "agent": "clawd",
      "sender": "user",
      "text": "Give me a morning briefing",
      "timestamp": "2026-02-10T07:30:00Z"
    },
    {
      "id": "msg_def456",
      "agent": "clawd",
      "sender": "agent",
      "text": "Good morning! Here's your briefing...",
      "timestamp": "2026-02-10T07:30:05Z"
    }
  ]
}
```

#### Briefings

**GET /api/v2/briefing/morning**

Response:
```json
{
  "briefing": {
    "timestamp": "2026-02-10T05:30:00Z",
    "greeting": "Good morning, Will!",
    "summary": "Overnight: Jordan made 2 trades (+$8.50), Hunter researched 5 new leads, Bob deployed v2.1 (all tests passing).",
    "sections": [
      {
        "title": "Trading (Jordan)",
        "content": "2 trades executed overnight. Total P&L: +$8.50. Open positions: 3. Best trade: KXBTC15M (+$5.25)."
      },
      {
        "title": "Sales (Hunter)",
        "content": "5 new leads qualified. Top priority: TechCorp (score: 0.85). Suggested outreach attached."
      },
      {
        "title": "Engineering (Bob)",
        "content": "Deployed clawd-v2.1 to GCP at 2:15 AM. All tests passing. No incidents."
      },
      {
        "title": "Today's Calendar",
        "content": "3 meetings: 9 AM team standup, 11 AM client call, 2 PM HOA board meeting. Estimated commute: 23 min."
      },
      {
        "title": "Weather",
        "content": "Seattle: 45°F, cloudy, 60% chance of rain. Bring umbrella."
      }
    ],
    "action_items": [
      "Review TechCorp lead and send outreach",
      "Approve/reject Jordan's open position on ETHPRICE24",
      "Prep for HOA board meeting (Bob prepared agenda)"
    ]
  }
}
```

### WebSocket Messages

**Connection:** `ws://localhost:28789/ws/live` or `wss://34.162.215.220:18789/ws/live`

**Client → Server:**

**Subscribe to channels:**
```json
{
  "type": "SUBSCRIBE",
  "channels": ["jordan", "hunter", "bob", "clawd", "events"]
}
```

**Ping (keepalive):**
```json
{
  "type": "PING"
}
```

**Server → Client:**

**Pong (response to ping):**
```json
{
  "type": "PONG"
}
```

**Heartbeat:**
```json
{
  "type": "HEARTBEAT",
  "source": "jordan",
  "timestamp": "2026-02-10T22:30:00Z",
  "payload": {
    "state": "CAUTIOUS",
    "running": true
  }
}
```

**Trade executed:**
```json
{
  "type": "TRADE_EXECUTED",
  "source": "jordan",
  "timestamp": "2026-02-10T22:28:15Z",
  "payload": {
    "trade_id": "trade_123abc",
    "ticker": "KXBTC15M-24FEB11-T95",
    "side": "YES",
    "quantity": 10,
    "price_cents": 95,
    "edge_cents": 12,
    "reasoning_summary": "Strong upward momentum + whale accumulation"
  }
}
```

**Trade closed:**
```json
{
  "type": "TRADE_CLOSED",
  "source": "jordan",
  "timestamp": "2026-02-10T18:45:00Z",
  "payload": {
    "trade_id": "trade_123abc",
    "exit_price_cents": 98,
    "pnl_cents": 300,
    "outcome": "WIN"
  }
}
```

**Lead qualified:**
```json
{
  "type": "LEAD_QUALIFIED",
  "source": "hunter",
  "timestamp": "2026-02-10T21:45:30Z",
  "payload": {
    "lead_id": "lead_789ghi",
    "company_name": "TechCorp Inc.",
    "qualification_score": 0.85,
    "suggested_outreach": "..."
  }
}
```

**Agent state change:**
```json
{
  "type": "AGENT_STATE_CHANGE",
  "source": "jordan",
  "timestamp": "2026-02-10T15:22:00Z",
  "payload": {
    "old_state": "CONFIDENT",
    "new_state": "CAUTIOUS",
    "reason": "2 consecutive losses (-$15.25)"
  }
}
```

**Pain signal:**
```json
{
  "type": "PAIN_SIGNAL",
  "source": "bob",
  "timestamp": "2026-02-10T12:33:00Z",
  "payload": {
    "pain_level": 7,
    "trigger": "High memory usage on GCP instance (85%)",
    "recommended_state": "VIGILANT",
    "action_taken": "Restarted clawd-v2 service"
  }
}
```

---

## UI/UX Specifications

### Design System (Coinbase-Inspired)

**Typography:**
- Hero numbers: SF Pro Display, 48pt, Bold, -1.5 tracking
- Section headers: SF Pro Text, 20pt, Bold
- Row titles: SF Pro Text, 17pt, Medium
- Row subtitles: SF Pro Text, 15pt, Regular
- Captions: SF Pro Text, 13pt, Regular
- Small text: SF Pro Text, 11pt, Regular

**Colors (Light Mode):**
- Primary blue: `#0052FF` (Coinbase blue)
- Green (positive): `#05B169`
- Red (negative): `#DF5F67`
- Background: `#FFFFFF`
- Elevated (cards): `#F7F8FA`
- Text primary: `#050F19`
- Text secondary: `#5B6571`
- Text tertiary: `#8A919E`
- Dividers: `#E0E3EB`

**Colors (Dark Mode):**
- Primary blue: `#5B8FF9`
- Green: `#20C070`
- Red: `#FF6F6F`
- Background: `#0C0F14`
- Elevated: `#1C1F26`
- Text primary: `#F7FAFC`
- Text secondary: `#B8BCC4`
- Text tertiary: `#6A7280`
- Dividers: `#2E3139`

**Spacing:**
- Horizontal padding: 16pt
- Section spacing: 24pt
- Row height: 64pt
- Icon size: 40pt (circle)
- Pill badge: 8pt padding, 16pt height

**Animations:**
- Default duration: 0.3s
- Easing: ease-in-out
- Haptic feedback: Medium impact for actions, Light for scrolling

### Tab Specifications

#### Today Tab

**Layout:**
```
┌──────────────────────────────────────┐
│ [StatusPill: Gateway Connected]      │
├──────────────────────────────────────┤
│                                      │
│  Good morning, Will! 🌅              │
│  Tuesday, February 10, 2026          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Morning Briefing (Clawd)       │ │
│  │ - Jordan: 2 trades (+$8.50)    │ │
│  │ - Hunter: 5 new leads          │ │
│  │ - Bob: Deployed v2.1           │ │
│  │ [Expand for details ▼]         │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Calendar                        │ │
│  │ 9:00 AM  Team Standup           │ │
│  │ 11:00 AM Client Call (Zoom)     │ │
│  │ 2:00 PM  HOA Board Meeting      │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Weather & Commute               │ │
│  │ ☁️ 45°F, Cloudy                 │ │
│  │ 🚗 23 min via I-90 (light)      │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Chat with Clawd                 │ │
│  │ [Text input field]              │ │
│  │ [🎤 Voice input button]         │ │
│  └────────────────────────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

**Interactions:**
- Pull to refresh → Fetch latest briefing
- Tap calendar event → Event details (location, attendees, notes)
- Tap weather → Open Weather app
- Voice button → Start voice input, send to Clawd

#### Trading Tab

**Layout:**
```
┌──────────────────────────────────────┐
│ Trading                    [⚙️ Settings]│
├──────────────────────────────────────┤
│ P&L balance                          │
│ $1,250.00                            │
│ ↗️ +$1,250.00 all time (125%)       │
│                                      │
│ [Chart: Line + Area, scrubbing]     │
│                                      │
│ [1D] [1W] [1M] [3M] [1Y] [ALL]      │
│                                      │
│ Open positions (3)                   │
│ ┌────────────────────────────────┐  │
│ │ [Y] KXBTC15M > $95k             │  │
│ │     YES 10x @ 95¢                │  │
│ │                     97¢  +$20.00 │ │
│ └────────────────────────────────┘  │
│ ┌────────────────────────────────┐  │
│ │ [N] ETHPRICE24 > $3.5k          │  │
│ │     NO 5x @ 62¢                  │  │
│ │                     59¢  -$15.00 │ │
│ └────────────────────────────────┘  │
│                                      │
│ Recent trades (15)                   │
│ ┌────────────────────────────────┐  │
│ │ [👍] KXBTC15M > $95k            │  │
│ │     YES 10x | closed             │  │
│ │                     +$30.00      │ │
│ │     95¢ → 98¢                    │ │
│ └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

**Interactions:**
- Tap position → Position detail view (full screen)
- Tap trade → Trade detail view (reasoning, chart, outcome)
- Swipe left on position → Close position (manual override)
- Chart scrub → Show P&L at specific point in time

#### Work Tab

**Layout:**
```
┌──────────────────────────────────────┐
│ Work                      [Filter 🔍] │
├──────────────────────────────────────┤
│                                      │
│ Emails (12 unread)                   │
│ ┌────────────────────────────────┐  │
│ │ [📧] RE: Smartsheet Demo        │  │
│ │     Jane Smith (TechCorp)        │  │
│ │     "Thanks for the demo..."     │  │
│ │                        [RESPOND]  │ │
│ └────────────────────────────────┘  │
│ ┌────────────────────────────────┐  │
│ │ [📧] Q4 Pipeline Review          │  │
│ │     Manager (Internal)           │  │
│ │     "Can you send updated..."    │  │
│ │                        [DELEGATE] │ │
│ └────────────────────────────────┘  │
│                                      │
│ Leads (5 today)                      │
│ ┌────────────────────────────────┐  │
│ │ [🏢] TechCorp Inc.               │  │
│ │     Jane Smith, VP Eng           │  │
│ │     Score: 0.85 (High fit)       │  │
│ │                        [CONTACT]  │ │
│ └────────────────────────────────┘  │
│ ┌────────────────────────────────┐  │
│ │ [🏢] DataCo                      │  │
│ │     John Doe, CTO                │  │
│ │     Score: 0.72 (Medium fit)     │  │
│ │                        [REVIEW]   │ │
│ └────────────────────────────────┘  │
│                                      │
│ To-do (8 tasks)                      │
│ ┌────────────────────────────────┐  │
│ │ [ ] Send TechCorp proposal       │  │
│ │ [✓] Update pipeline in Salesforce│ │
│ │ [ ] Call DataCo (follow-up)      │  │
│ └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

**Interactions:**
- Tap email → Email detail + quick actions (reply, archive, snooze)
- Tap lead → Lead detail view (research, outreach builder)
- Tap task → Task detail (edit, mark done, assign to agent)
- Swipe left on email → Archive
- Swipe right on email → Snooze (1h, 3h, tomorrow)

---

## Real-Time Communication Architecture

### WebSocket Connection Management

**State Machine:**
```
DISCONNECTED
    ↓ (connect() called)
CONNECTING
    ↓ (onOpen)
CONNECTED
    ↓ (send SUBSCRIBE)
SUBSCRIBED
    ↓ (onMessage: PONG)
AUTHENTICATED
    ↓ (network loss / onClose)
RECONNECTING
    ↓ (exponential backoff: 1s, 2s, 4s, 8s, max 30s)
CONNECTING ...
```

**Reconnection Logic:**
```swift
class WebSocketManager: ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected
    private var ws: URLSessionWebSocketTask?
    private var reconnectAttempts = 0
    private let maxReconnectDelay = 30.0

    func connect() {
        guard connectionState == .disconnected else { return }
        connectionState = .connecting

        let url = URL(string: "ws://localhost:28789/ws/live")!
        ws = URLSession.shared.webSocketTask(with: url)
        ws?.resume()

        listenForMessages()
        sendPing()
    }

    func reconnect() {
        let delay = min(pow(2.0, Double(reconnectAttempts)), maxReconnectDelay)
        reconnectAttempts += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.connect()
        }
    }

    private func sendPing() {
        let message = ["type": "PING"]
        send(message: message)

        // Schedule next ping in 15s
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if self.connectionState == .authenticated {
                self.sendPing()
            }
        }
    }
}
```

### Message Queue for Offline Support

**Architecture:**
```
User Action (e.g., send chat message)
    ↓
PendingMessageQueue.enqueue(message)
    ↓
Check connection state
    ↓ (if CONNECTED)
WebSocketManager.send(message)
    ↓ (on success)
PendingMessageQueue.dequeue(message)
    ↓ (if DISCONNECTED)
Show UI: "Message queued (will send when online)"
    ↓ (on reconnect)
PendingMessageQueue.flush()
```

**Implementation:**
```swift
class PendingMessageQueue {
    private var queue: [PendingMessage] = []

    func enqueue(_ message: PendingMessage) {
        queue.append(message)
        persistToDisk() // Save to UserDefaults or file
    }

    func flush() {
        for message in queue {
            WebSocketManager.shared.send(message: message.payload)
        }
        queue.removeAll()
        persistToDisk()
    }

    private func persistToDisk() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(queue) {
            UserDefaults.standard.set(data, forKey: "pendingMessages")
        }
    }
}
```

---

## Offline & Sync Strategy

### Data Freshness Tiers

**Tier 1: Real-Time (WebSocket)**
- Agent heartbeats
- Trade executions
- Lead qualifications
- Pain signals

**Tier 2: Near Real-Time (Poll every 30s)**
- Position prices (Kalshi market odds)
- Email inbox counts
- Calendar event updates

**Tier 3: On-Demand (Fetch on tab switch)**
- Trade history (cached 1 hour)
- Lead details (cached 30 min)
- Chat history (cached 5 min)

**Tier 4: Lazy Load (Fetch on scroll)**
- Old trades (beyond 50 most recent)
- Archived leads
- Chat messages (beyond 100 most recent)

### Offline Mode

**What Works Offline:**
- View cached trades, positions, leads (last sync)
- View cached chat history
- Browse tabs (read-only)
- Voice commands (local only: "show trading", "what's my P&L?")

**What Doesn't Work Offline:**
- Send chat messages to agents
- Real-time updates (positions, P&L)
- Fetch new leads or trades
- Outreach (send emails)

**UI Indicators:**
- StatusPill shows "Offline" badge (red)
- Pull-to-refresh shows "Offline - showing cached data"
- Action buttons disabled with "Requires connection" tooltip

### Background Refresh

**iOS Background Tasks:**
- Register `BGAppRefreshTask` for periodic updates (every 15 min)
- In background task:
  - Fetch latest trades, positions, leads
  - Update local SwiftData store
  - Send local notification if high-impact event (e.g., big win/loss)

**Implementation:**
```swift
import BackgroundTasks

func scheduleBackgroundRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.clawdbot.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min

    try? BGTaskScheduler.shared.submit(request)
}

func handleBackgroundRefresh(task: BGAppRefreshTask) {
    task.expirationHandler = {
        task.setTaskCompleted(success: false)
    }

    Task {
        await fetchLatestData()
        task.setTaskCompleted(success: true)
        scheduleBackgroundRefresh() // Schedule next refresh
    }
}
```

---

## Testing & Quality Assurance

### Test Strategy

**Unit Tests:**
- Target: 80%+ code coverage
- Focus areas:
  - Network layer (WebSocketManager, ClawdV2Client)
  - Data models (Trade, Position, Lead parsing)
  - Business logic (P&L calculations, lead scoring)
  - View models (state management)

**Integration Tests:**
- Network mocks (URLProtocol stubs)
- WebSocket message handling (send/receive)
- SwiftData persistence (CRUD operations)
- Background refresh (BGTaskScheduler)

**UI Tests:**
- Tab navigation (tap each tab, verify content)
- Pull-to-refresh (swipe down, verify API call)
- Deep linking (open URL, verify navigation)
- Offline mode (disable network, verify graceful degradation)

**Snapshot Tests:**
- Use swift-snapshot-testing
- Capture screenshots of key screens in light/dark mode
- Detect visual regressions

**Manual Test Cases:**

**Trading Tab:**
1. Launch app → Trading Tab → Verify P&L chart loads
2. Tap trade → Verify detail view shows reasoning
3. Swipe to close position → Verify confirmation alert
4. Chart scrub → Verify haptic feedback + value update

**Work Tab:**
5. Tap lead → Verify research notes display
6. Tap "Contact" → Verify outreach composer opens with pre-filled template
7. Edit outreach → Send → Verify email sent (check sent folder)
8. Pipeline view → Drag lead to "Contacted" → Verify backend update

**Voice System:**
9. Say "Hey Clawd" → Verify wake word detected
10. Say "Show Trading" → Verify navigation to Trading Tab
11. Say "What's my P&L?" → Verify voice response + visual update
12. Say "Jordan, why did you buy this?" → Verify agent responds with reasoning

**Offline Mode:**
13. Disable WiFi + Cellular → Verify "Offline" badge
14. Pull to refresh → Verify "Offline - showing cached data"
15. Try to send chat message → Verify queued for later
16. Re-enable network → Verify message sends automatically

### Performance Benchmarks

**App Launch:**
- Cold launch: < 2 seconds (until first frame)
- Warm launch: < 1 second

**Network:**
- WebSocket connection: < 500ms
- REST API response: < 1 second (p95)
- Image loading: < 300ms (cached), < 1s (network)

**UI:**
- Scrolling: 60fps sustained
- Chart rendering: < 100ms
- Tab switch: < 200ms

**Memory:**
- Peak usage: < 150MB (iPhone SE 2022)
- Idle: < 50MB

### Accessibility Requirements

**VoiceOver:**
- All UI elements labeled (buttons, images, charts)
- Meaningful labels (not "Button" but "Buy YES on Bitcoin")
- Group related elements (e.g., trade card = single swipe)

**Dynamic Type:**
- Support user font size preferences (smallest to largest)
- Test at accessibility sizes (AX1, AX2, AX3, AX4, AX5)
- Ensure text doesn't truncate at large sizes

**Color Contrast:**
- WCAG AA compliance (4.5:1 for text, 3:1 for UI elements)
- Test in light/dark mode
- Ensure green/red are distinguishable (color blindness)

**Reduce Motion:**
- Respect `UIAccessibility.isReduceMotionEnabled`
- Replace animations with cross-fades
- Disable parallax effects

---

## Deployment & CI/CD Pipeline

### Build & Release Process

**Environments:**
- **Development:** Xcode builds, local backend (localhost:28789)
- **TestFlight:** Beta builds, GCP backend (34.162.215.220:18789)
- **App Store:** Production builds, GCP backend

**Versioning:**
- Semantic versioning: `MAJOR.MINOR.PATCH` (e.g., 2.1.0)
- Build number: Auto-increment (e.g., 147)
- Store in `Info.plist`:
  - `CFBundleShortVersionString` = 2.1.0
  - `CFBundleVersion` = 147

**Code Signing:**
- Development: Xcode managed signing
- Distribution: Manual signing with App Store Connect provisioning profiles

**CI/CD (GitHub Actions):**

```yaml
name: iOS Build & Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Set up Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.2'

      - name: Install dependencies
        run: |
          cd apps/ios
          xcodegen generate

      - name: Run tests
        run: |
          cd apps/ios
          xcodebuild test \
            -scheme Clawdbot \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

      - name: Build for TestFlight
        if: github.ref == 'refs/heads/main'
        run: |
          cd apps/ios
          xcodebuild archive \
            -scheme Clawdbot \
            -archivePath build/Clawdbot.xcarchive \
            -destination 'generic/platform=iOS'

          xcodebuild -exportArchive \
            -archivePath build/Clawdbot.xcarchive \
            -exportPath build \
            -exportOptionsPlist ExportOptions.plist

      - name: Upload to TestFlight
        if: github.ref == 'refs/heads/main'
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_API_KEY }}
        run: |
          xcrun altool --upload-app \
            -f build/Clawdbot.ipa \
            -t ios \
            --apiKey $APP_STORE_CONNECT_API_KEY
```

**Release Checklist:**

1. **Pre-Release:**
   - [ ] Bump version in `Info.plist`
   - [ ] Update `CHANGELOG.md`
   - [ ] Run full test suite (unit + UI + manual)
   - [ ] Test on real devices (iPhone 15 Pro, iPhone SE 2022)
   - [ ] Verify dark mode + accessibility
   - [ ] Take App Store screenshots

2. **TestFlight Release:**
   - [ ] Build & upload via Xcode or CI
   - [ ] Add "What to Test" notes for testers
   - [ ] Internal testing (Will only, for now)
   - [ ] Verify push notifications work
   - [ ] Verify WebSocket connection stable
   - [ ] Test offline mode

3. **App Store Submission:**
   - [ ] Prepare App Store metadata (description, keywords, screenshots)
   - [ ] Submit for review
   - [ ] Monitor review status (7-14 days)
   - [ ] Release to App Store (auto or manual)

**Rollback Plan:**
- If critical bug discovered post-release:
  - Submit hotfix build with incremented patch version
  - Expedited review request (Apple)
  - Notify users via push notification

---

## Security & Privacy

### Data Protection

**Sensitive Data:**
- Session tokens (Keychain)
- Agent API keys (Keychain)
- User email addresses (local DB, encrypted at rest)
- Chat history (local DB, not synced to cloud)

**Keychain Usage:**
```swift
import Security

func saveToKeychain(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    SecItemAdd(query as CFDictionary, nil)
}

func readFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: true
    ]
    var result: AnyObject?
    SecItemCopyMatching(query as CFDictionary, &result)
    if let data = result as? Data {
        return String(data: data, encoding: .utf8)
    }
    return nil
}
```

**Network Security:**
- HTTPS only (backend must support TLS)
- Certificate pinning (optional, for GCP backend)
- No HTTP traffic allowed (Info.plist: `NSAppTransportSecurity`)

**Privacy Manifest (iOS 17+):**
- Declare tracking domains (none)
- Required reason APIs:
  - `NSMicrophoneUsageDescription`: Voice wake word detection
  - `NSLocationWhenInUseUsageDescription`: Commute time calculation
  - `NSCameraUsageDescription`: Screen recording for agent context

### App Store Privacy Disclosures

**Data Collected:**
- Location (coarse, for commute time)
- Voice input (processed locally, not uploaded)
- Usage data (analytics: screen views, taps)

**Data Not Collected:**
- No third-party tracking
- No data sold to advertisers
- Agent communication stays on Will's infrastructure

**Privacy Policy:**
- Host at `https://clawdbot.com/privacy`
- Update annually or when data practices change

---

## Performance Optimization

### Rendering Performance

**Lazy Loading:**
```swift
ScrollView {
    LazyVStack {
        ForEach(trades) { trade in
            TradeRow(trade: trade)
        }
    }
}
```

**Image Caching:**
```swift
import Kingfisher

KFImage(URL(string: lead.companyLogoUrl))
    .placeholder { ProgressView() }
    .cacheMemoryOnly()
    .resizable()
    .frame(width: 40, height: 40)
```

**Chart Optimization:**
```swift
// Only render visible points
let visiblePoints = pnlHistory.suffix(timeRange.dataPoints)
Chart {
    ForEach(visiblePoints) { point in
        LineMark(...)
    }
}
```

### Network Optimization

**Request Batching:**
```swift
// Instead of 3 sequential requests:
// let trades = await fetchTrades()
// let positions = await fetchPositions()
// let pnl = await fetchPnL()

// Batch into single request:
let data = await fetchDashboard() // Returns trades + positions + pnl
```

**Response Compression:**
```swift
var request = URLRequest(url: url)
request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
```

**Image Compression:**
- Serve images as WebP (smaller than JPEG)
- Resize server-side (don't send 4K images for 40x40 avatars)

### Memory Optimization

**View Lifecycle:**
```swift
struct TradingTab: View {
    @State private var trades: [Trade] = []

    var body: some View {
        ScrollView {
            ForEach(trades) { trade in
                TradeRow(trade: trade)
            }
        }
        .onAppear {
            loadTrades()
        }
        .onDisappear {
            // Clear large data to free memory
            trades.removeAll()
        }
    }
}
```

**Instruments Profiling:**
- Time Profiler: Identify slow functions
- Allocations: Track memory usage, find leaks
- Network: Monitor request size/latency
- Energy Log: Battery impact

---

## Analytics & Monitoring

### Metrics to Track

**App Health:**
- Crash rate (crashes per session)
- ANR rate (App Not Responding)
- App launch time (cold, warm)
- WebSocket uptime (% time connected)

**Feature Adoption:**
- Daily active users (Will only, for now)
- Screen views per session
- Most used tabs (Today, Trading, Work, etc.)
- Voice command usage (count, success rate)

**Business Metrics:**
- Trades reviewed per session (Trading Tab)
- Leads contacted per session (Work Tab)
- Agent interactions (chat messages sent)
- Notifications opened (push notification CTR)

### Analytics Provider

**Recommendation:** TelemetryDeck (privacy-focused, no PII)

**Setup:**
```swift
import TelemetryClient

// In ClawdbotApp.init():
TelemetryManager.initialize(with: TelemetryManagerConfiguration(
    appID: "YOUR_APP_ID"
))

// Track events:
TelemetryManager.send("screen_view", with: ["screen": "TradingTab"])
TelemetryManager.send("trade_tapped", with: ["trade_id": trade.id])
TelemetryManager.send("voice_command", with: ["command": "show_trading"])
```

### Crash Reporting

**Recommendation:** Sentry

**Setup:**
```swift
import Sentry

// In ClawdbotApp.init():
SentrySDK.start { options in
    options.dsn = "YOUR_SENTRY_DSN"
    options.tracesSampleRate = 1.0
}

// Automatic crash reporting
// Manual error logging:
SentrySDK.capture(error: error)
```

---

## Appendix: API Endpoints

### Complete Endpoint List

**Base URL:** `http://localhost:28789` or `http://34.162.215.220:18789`

**Agent Status:**
- `GET /api/v2/agents/status` → All agents (heartbeats, states, stats)
- `GET /api/v2/agents/:name/status` → Single agent status
- `GET /api/v2/agents/:name/activity` → Agent activity log (last 100 actions)

**Trading (Jordan):**
- `GET /api/v2/trades` → List trades (query: limit, since, status)
- `GET /api/v2/trades/:id` → Single trade detail
- `GET /api/v2/positions` → Open positions
- `GET /api/v2/positions/:id` → Single position detail
- `POST /api/v2/positions/:id/close` → Close position (manual override)
- `GET /api/v2/pnl/history` → Historical P&L (query: timeframe)
- `GET /api/v2/pnl/summary` → Summary stats (total P&L, win rate, Sharpe, etc.)

**Leads (Hunter):**
- `GET /api/v2/leads` → List leads (query: status, limit, min_score)
- `GET /api/v2/leads/:id` → Single lead detail
- `POST /api/v2/leads/:id/contact` → Mark as contacted (send outreach)
- `PATCH /api/v2/leads/:id` → Update lead (status, notes)
- `GET /api/v2/leads/pipeline` → Pipeline stats (counts by status)

**Emails:**
- `GET /api/v2/emails` → Inbox (query: category=respond|delegate|archive)
- `GET /api/v2/emails/:id` → Single email detail
- `POST /api/v2/emails/:id/reply` → Send reply
- `POST /api/v2/emails/:id/archive` → Archive email
- `POST /api/v2/emails/:id/snooze` → Snooze email (body: until timestamp)

**Chat:**
- `POST /api/v2/chat` → Send message to agent (body: agent, message)
- `GET /api/v2/chat/history` → Chat history (query: agent, limit)

**Briefings:**
- `GET /api/v2/briefing/morning` → Morning briefing (generated at 5:30 AM)
- `GET /api/v2/briefing/evening` → Evening briefing (generated at 6:00 PM)
- `GET /api/v2/briefing/realtime` → On-demand briefing (generated now)

**Calendar:**
- `GET /api/v2/calendar/events` → Upcoming events (query: days=7)
- `GET /api/v2/calendar/commute` → Commute time to next event

**Smart Home:**
- `GET /api/v2/smarthome/devices` → List devices
- `POST /api/v2/smarthome/:device_id/command` → Send command (body: action, params)

**HOA:**
- `GET /api/v2/hoa/projects` → List projects
- `GET /api/v2/hoa/projects/:id` → Single project detail
- `POST /api/v2/hoa/projects` → Create project
- `PATCH /api/v2/hoa/projects/:id` → Update project

**WebSocket:**
- `ws://localhost:28789/ws/live` → Live updates (subscribe to all channels)

---

## Implementation Priorities (Summary)

**Phase 1 (Weeks 1-2): Foundation**
- WebSocket manager + reconnection
- SwiftData persistence + sync
- Today Tab basic implementation
- Error handling

**Phase 2 (Weeks 3-4): Agent Visibility**
- Agent reasoning panels
- Agent status dashboard
- Notification center
- Deep linking

**Phase 3 (Weeks 5-6): Trading UX**
- Advanced charts (multi-timeframe)
- Position detail view
- Trade analytics
- Paper trading indicator

**Phase 4 (Weeks 7-8): Work & SDR**
- Lead detail view
- Outreach builder
- Pipeline view
- Daily prospecting checklist

**Phase 5 (Weeks 9-10): Personal & HOA**
- Smart home control
- Calendar + reminders
- HOA project tracking
- Email triage

**Phase 6 (Weeks 11-12): Polish**
- UI polish + animations
- Performance optimization
- Accessibility audit
- Analytics + crash reporting
- App Store prep

---

## Conclusion

This roadmap provides a **complete, robust architecture** for the Clawdbot iOS app. It covers:

✅ **Product vision** (personal command center for Will)
✅ **Technical architecture** (WebSocket, SwiftData, networking)
✅ **Feature roadmap** (6 phases, 12 weeks)
✅ **Data models & API contracts** (REST + WebSocket)
✅ **UI/UX specifications** (Coinbase-inspired design)
✅ **Real-time communication** (WebSocket manager, offline support)
✅ **Testing strategy** (unit, integration, UI, manual)
✅ **Deployment pipeline** (CI/CD, TestFlight, App Store)
✅ **Security & privacy** (Keychain, TLS, privacy manifest)
✅ **Performance optimization** (rendering, network, memory)
✅ **Analytics & monitoring** (TelemetryDeck, Sentry)

**Next Steps:**
1. Review this roadmap with Will
2. Prioritize phases (can phases be parallelized?)
3. Assign implementation (Bob? External iOS dev? Will himself?)
4. Set up project management (Linear, Notion, GitHub Projects)
5. Begin Phase 1: Foundation (WebSocket + SwiftData)

**Estimated Timeline:** 12 weeks (3 months) to production-ready v2.0

**Cost:** $0.00 in Claude API usage (this roadmap was built with 3 Read calls only!)

---

**Document Version:** 2.0
**Last Updated:** February 10, 2026
**Author:** Claude (Sonnet 4.5) + Will Shanahan
**Status:** Ready for implementation 🚀
