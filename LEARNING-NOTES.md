# n8n Learning Notes — E-Commerce Automation Portfolio

> Personal reference notes for describing these workflows confidently to clients and in interviews.

---

## How to Talk About n8n to Clients

**Elevator pitch:**
> "n8n is a visual workflow automation tool — think of it like Zapier but self-hosted, more powerful, and without per-task pricing. You connect apps by dragging and dropping nodes on a canvas, and each node does one thing: receive data, transform it, make a decision, or take an action. I build these workflows for businesses to replace manual, repetitive tasks."

**Key selling points:**
- Visual, auditable — clients can see exactly what happens at each step
- Self-hosted = data never leaves their servers (important for B2B)
- No per-execution pricing (unlike Zapier) = cost-effective at scale
- Handles complex logic: AI, conditional routing, loops, error handling
- Connects to 400+ apps out of the box

---

## Core n8n Concepts (Explain These to Clients)

### Triggers
> "Every workflow starts with a trigger — something that wakes it up. It could be a webhook (something external sends data), a schedule (runs every hour), or an event like a new email."

- **Webhook Trigger** — Receives POST requests; used for real-time events (orders, tickets, reviews)
- **Schedule Trigger** — Runs on a cron schedule; used for batch jobs (inventory checks)
- **Error Trigger** — Fires when another node in the workflow fails

### Nodes
> "Each node does one job. Data flows left to right through nodes like water through pipes. Each node receives the previous node's output and passes its own output forward."

Key nodes I use:
| Node | What It Does | When I Use It |
|---|---|---|
| **Set** | Extract/rename/transform fields | Always right after a trigger to normalize data |
| **IF** | Split flow based on condition (true/false) | Filtering, flags (negative review?, low stock?) |
| **Switch** | Route to multiple branches | Category-based routing (complaint vs refund vs shipping) |
| **Aggregate** | Merge N items into 1 with arrays | Before sending a summary email with multiple items |
| **Code** | Run JavaScript | Complex transformations that visual nodes can't do |
| **HTTP Request** | Call any REST API | Connecting to platforms with no native n8n node |

### Expressions
> "Inside any field in n8n, you can write `{{ }}` expressions to pull in dynamic data. It's like a mini-template language."

Key expressions I use:
```
{{ $json.fieldName }}          — current node's data
{{ $json.body.fieldName }}     — webhook body field
{{ $('Node Name').item.json.field }}  — data from any upstream node
{{ $now.toISO() }}             — current timestamp
{{ JSON.parse($json.message.content) }}  — parse AI response
{{ $json.items.join(', ') }}   — array to string
```

### Credentials
> "Credentials are stored securely in n8n and referenced by name in nodes — the actual API keys/passwords are never exposed in the workflow JSON."

---

## Workflow 1 — Order Notification: What I Learned

**The parallel branch pattern:**
The Set node connects to 3 nodes simultaneously (Email + Discord + Sheets). n8n runs them all in parallel. This is more efficient than running them sequentially and means if one fails, the others still complete.

**Respond to Webhook:**
When `responseMode` is set to `responseNode`, the webhook hangs open until the "Respond to Webhook" node fires. This lets me return meaningful data (like the order ID) to the caller.

**Client pitch:**
> "When a customer places an order, this workflow fires in under 2 seconds: they get a branded confirmation email, your fulfillment team gets a Discord ping, and the order is logged to your master Google Sheet — all automatically, with no manual work."

---

## Workflow 2 — Support Ticket Router: What I Learned

**AI classification pattern:**
I send the customer message to GPT-4o-mini with a strict JSON schema prompt. The AI always responds with the same structure: category, sentiment, urgency, summary, suggestedResponse. Then I parse that JSON in the next node.

**Why structured prompts matter:**
If I just asked the AI "what category is this?" it might respond "This appears to be a refund request." — unparseable. By telling the AI "respond ONLY with a JSON object," I get machine-readable output every time.

**Switch vs IF:**
- IF = 2 outputs (true/false)
- Switch = N outputs, one per rule
- Use Switch when you have 3+ categories to route

**Client pitch:**
> "This workflow reads every support ticket your customers send, uses AI to understand what they actually need, and automatically routes it — sending refund policy info, shipping escalation notices, or flagging complaints for your team. Most tickets get resolved without anyone touching them."

---

## Workflow 3 — Inventory Alert: What I Learned

**The Aggregate node — most important pattern in batch workflows:**
When Google Sheets returns 15 inventory rows, n8n processes them as 15 separate items. After the IF filter, I might have 4 low-stock items — still 4 separate items. The Aggregate node collapses them into 1 item where each field becomes an array:
```
Before Aggregate: item1.productName = "Widget A", item2.productName = "Widget B"
After Aggregate:  $json.productName = ["Widget A", "Widget B"]
```
Then I use `.map()` in email templates to loop over the arrays.

**Double IF pattern:**
First IF: filter for low-stock items (might produce 0-N items)
Second IF: check the array is non-empty before sending the email
Without the second IF, you'd send an empty "low stock alert" email every hour even when everything is fine.

**Client pitch:**
> "This runs quietly in the background every hour, scanning your inventory sheet. The moment any product drops below its reorder point, your ops team gets an email with a formatted table showing exactly which products need reordering, how many you have left, and which supplier to call — before you ever run out of stock."

---

## Workflow 4 — Review Analyzer: What I Learned

**Structured AI extraction — the most powerful AI pattern:**
By giving the AI a precise JSON schema to fill out, I turn unstructured review text into structured data that goes directly into Google Sheets. Each field is intentional: product managers care about `themeQuality`, marketers care about `keyPhrases`, operations cares about `themeShipping`.

**weekNumber field:**
`$now.format('YYYY-[W]WW')` produces "2024-W47" — this lets you group all reviews by week in a Google Sheets pivot table to spot trends without any extra workflow.

**Cost calculation for clients:**
GPT-4o-mini costs ~$0.15/1M input tokens. A 200-word review ≈ 300 tokens. At 10,000 reviews/month = 3M tokens = ~$0.45/month. Effectively free at scale.

**Client pitch:**
> "Every review that comes in gets analyzed by AI to extract sentiment, identify themes around quality, shipping, and value, and flag anything negative for immediate team response. You get a Google Sheet that builds up over time as a product intelligence database — you can see at a glance if shipping complaints spiked this week or if quality scores are trending down."

---

## Common Client Questions & Answers

**Q: What happens if a step fails?**
> "Every workflow has an Error Trigger node. If any step fails — say the email server is down — the Error Trigger fires and sends your team a Discord alert with what failed and when. Nothing silently breaks."

**Q: How do you connect it to our existing platform?**
> "Most platforms have webhooks — Shopify, WooCommerce, Stripe, Zendesk all support them. I configure your platform to send a POST request to the workflow's webhook URL when something happens. No code changes needed on your side."

**Q: Can it handle high volume?**
> "n8n processes executions in queues. For high-volume needs I'd set up n8n with a queue mode using Redis and PostgreSQL, which can handle thousands of executions per minute."

**Q: Is our data safe?**
> "Because we self-host n8n on your own server (or cloud VPS), your data never passes through a third-party automation platform. Credentials are encrypted at rest. The only data that leaves your infrastructure is what you explicitly send to external APIs like OpenAI."

---

## Pricing These Services on Upwork

**Simple webhook → notification workflows:** $150–$400
(Workflow 1 equivalent — 3-6 hours of work)

**AI routing/classification workflows:** $500–$1,200
(Workflow 2 equivalent — complex prompt engineering, routing logic)

**Scheduled batch processing:** $300–$700
(Workflow 3 equivalent — data reading, filtering, aggregation)

**AI analysis + data extraction pipelines:** $600–$1,500
(Workflow 4 equivalent — prompt design, structured extraction, reporting)

**Full e-commerce automation suite (all 4):** $1,800–$4,000
(Position as a package — recurring maintenance retainer possible)

**Monthly maintenance retainer:** $200–$500/month
(Monitoring, updates, adding new triggers/actions as business grows)

---

## Portfolio Presentation Tips

1. **Lead with business outcome, not tech:** "Reduced support ticket response time from 4 hours to 30 seconds" beats "Built n8n workflow with OpenAI integration"

2. **Show the Google Sheet:** A populated sheet with AI-analyzed data is the most tangible proof of value

3. **Record a Loom video:** 3-minute demo showing the workflow canvas + triggering it live + showing the results in Discord/email/Sheets = highest conversion on Upwork proposals

4. **Screenshot the canvas:** The visual workflow map with color-coded nodes and parallel branches looks impressive to non-technical clients

5. **Niche down:** "E-commerce automation specialist" is more compelling than "I build workflows"
