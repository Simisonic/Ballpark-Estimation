# Ballpark – AI Project Estimator

An n8n workflow that takes a plain-text software project description and returns a structured cost and effort estimate, broken down by phase, user story, and story points.

## What It Does

You send a POST request describing a project. The workflow uses GPT-4.1 Mini to break it into logical phases, generate user stories, assign Fibonacci story points, and calculate estimated hours and cost. The result comes back as structured JSON.

**Example input:**
```
Build a client portal for a law firm where clients can log in, view case updates, and upload documents.
```

**Example output:**
```json
{
  "phases": [...],
  "stories": [...],
  "estimation": {
    "total_points": 87,
    "total_hours": 348,
    "total_cost": "$52,200",
    "estimated_duration_weeks": 9,
    "complexity_breakdown": { "low": 4, "medium": 8, "high": 3 }
  }
}
```

## How It Works

1. **Webhook** — receives a POST request with a `project` field in the body
2. **LLM Prompt** — sends the description to GPT-4.1 Mini with a structured prompt asking for phases, stories, points, and costs in JSON
3. **Parse** — extracts and validates the JSON from the LLM response
4. **Calculate** — computes totals, phase summaries, complexity breakdown, and estimated timeline
5. **Respond** — returns the complete estimate as a JSON response

**Estimation logic:**
- Story points follow the Fibonacci scale: 1, 2, 3, 5, 8, 13, 21
- 1 story point = 4 hours of work
- Rate: $150/hour
- So a 5-point story = 20 hours = $3,000

## Setup

1. Import `Ballpark_Workflow.json` into your n8n instance
2. Add your OpenAI API credentials to the **OpenAI Chat Model** node
3. Activate the workflow
4. Send a POST request to your webhook URL:

```bash
curl -X POST https://your-n8n-instance/webhook/estimate \
  -H "Content-Type: application/json" \
  -d '{"project": "Build a booking system for a small dental practice"}'
```

## Built With

- [n8n](https://n8n.io) — workflow automation
- [OpenAI GPT-4.1 Mini](https://openai.com) — project analysis and estimation
- JavaScript (n8n Code nodes) — parsing, validation, and aggregation
