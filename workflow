{
  "name": "Ballpark Workflow",
  "nodes": [
    {
      "parameters": {
        "model": {
          "__rl": true,
          "mode": "list",
          "value": "gpt-4.1-mini"
        },
        "builtInTools": {},
        "options": {
          "temperature": 0.3
        }
      },
      "type": "@n8n/n8n-nodes-langchain.lmChatOpenAi",
      "typeVersion": 1.3,
      "position": [
        832,
        368
      ],
      "id": "595ec316-a53b-4ba1-9d14-c0f85344ab54",
      "name": "OpenAI Chat Model1",
      "credentials": {
        "openAiApi": {
          "id": "AzHWpNZSLshF3RO0",
          "name": "OpenAi account 21"
        }
      }
    },
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "estimate",
        "responseMode": "responseNode",
        "options": {}
      },
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2.1,
      "position": [
        592,
        144
      ],
      "id": "eef6b9e0-a6d0-4d8c-9693-66888cea10fa",
      "name": "Receive Project Request",
      "webhookId": "1be9eb84-a3cd-40fd-b755-519574bf81ce"
    },
    {
      "parameters": {
        "promptType": "define",
        "text": "=You are a senior project estimator. Analyze this project and create a detailed estimate.\n\nPROJECT DESCRIPTION:\n{{ $json.body.project }}\n\nYour task: Generate a complete project estimate with realistic phases, user stories, story points, and costs.\n\nRULES:\n1. Create 3-7 phases (logical project stages)\n2. Create 3-8 user stories per phase (specific deliverables)\n3. Use Fibonacci story points: 1, 2, 3, 5, 8, 13, or 21\n4. Calculate costs using: 1 point = 4 hours, rate = $150/hour\n5. Be realistic - match complexity to the project scope\n\nRETURN FORMAT:\nYou must return ONLY a valid JSON object with this exact structure. No markdown, no code fences, no additional text:\n\n{\n  \"phases\": [\n    {\n      \"phase_id\": \"P1\",\n      \"phase_name\": \"Phase Name\",\n      \"description\": \"What happens in this phase\"\n    }\n  ],\n  \"stories\": [\n    {\n      \"story_id\": \"S1\",\n      \"phase_id\": \"P1\",\n      \"title\": \"Short story title\",\n      \"description\": \"As a [user], I want [feature] so that [benefit]\"\n    }\n  ],\n  \"points\": [\n    {\n      \"story_id\": \"S1\",\n      \"points\": 5,\n      \"complexity\": \"low|medium|high\",\n      \"rationale\": \"Why this point value\"\n    }\n  ],\n  \"costs\": [\n    {\n      \"story_id\": \"S1\",\n      \"points\": 5,\n      \"hours\": 20,\n      \"cost\": 3000\n    }\n  ]\n}\n\nIMPORTANT:\n- Every story must have matching entries in points and costs arrays\n- Story IDs must be unique and sequential (S1, S2, S3...)\n- Phase IDs must be unique and sequential (P1, P2, P3...)\n- All story_id references must match exactly\n- Return ONLY the JSON object, nothing else",
        "messages": {
          "messageValues": [
            {
              "message": "You are a project estimation expert. You must return ONLY valid JSON. No markdown code fences (```), no explanatory text, no preamble. Just the raw JSON object starting with { and ending with }."
            }
          ]
        },
        "batching": {}
      },
      "type": "@n8n/n8n-nodes-langchain.chainLlm",
      "typeVersion": 1.9,
      "position": [
        832,
        144
      ],
      "id": "32a357be-ab2e-4cb7-8d0c-815edd80b3fe",
      "name": "Generate Estimate Data"
    },
    {
      "parameters": {
        "jsCode": "// Get the LLM response\nconst input = $input.first().json;\n\n// Extract content from various possible locations\nlet content = '';\n\nif (input.message && input.message.content) {\n  content = input.message.content;\n} else if (input.output) {\n  content = input.output;\n} else if (input.content) {\n  content = input.content;\n} else if (input.text) {\n  content = input.text;\n} else if (typeof input === 'string') {\n  content = input;\n} else {\n  // Log the actual structure for debugging\n  console.log('Unexpected input structure:', JSON.stringify(input, null, 2));\n  throw new Error('Could not find LLM response content');\n}\n\n// Clean the response\ncontent = content.trim();\n\n// Remove markdown code fences if present\ncontent = content.replace(/```json\\s*/g, '').replace(/```\\s*/g, '');\n\n// Remove any leading/trailing text that's not part of the JSON\nconst jsonStart = content.indexOf('{');\nconst jsonEnd = content.lastIndexOf('}');\n\nif (jsonStart === -1 || jsonEnd === -1) {\n  throw new Error('No valid JSON object found in LLM response');\n}\n\ncontent = content.substring(jsonStart, jsonEnd + 1);\n\n// Parse the JSON\nlet data;\ntry {\n  data = JSON.parse(content);\n} catch (error) {\n  console.error('Failed to parse JSON:', content);\n  throw new Error('JSON parsing failed: ' + error.message);\n}\n\n// Validate required fields\nconst requiredFields = ['phases', 'stories', 'points', 'costs'];\nfor (const field of requiredFields) {\n  if (!data[field] || !Array.isArray(data[field])) {\n    throw new Error('Missing or invalid required field: ' + field);\n  }\n}\n\n// Validate data consistency\nif (data.stories.length === 0) {\n  throw new Error('No stories generated');\n}\n\nif (data.stories.length !== data.points.length || data.stories.length !== data.costs.length) {\n  throw new Error('Mismatch between stories, points, and costs arrays');\n}\n\nreturn [{ json: data }];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        1184,
        144
      ],
      "id": "e73011f1-c399-480e-9ec6-a4d84309ffed",
      "name": "Parse LLM Response"
    },
    {
      "parameters": {
        "jsCode": "const data = $input.first().json;\n\n// Verify all story IDs match across arrays\nconst storyIds = new Set(data.stories.map(s => s.story_id));\nconst pointIds = new Set(data.points.map(p => p.story_id));\nconst costIds = new Set(data.costs.map(c => c.story_id));\n\n// Calculate totals\nconst totalPoints = data.points.reduce((sum, item) => sum + (item.points || 0), 0);\nconst totalHours = data.costs.reduce((sum, item) => sum + (item.hours || 0), 0);\nconst totalCost = data.costs.reduce((sum, item) => sum + (item.cost || 0), 0);\n\n// Calculate phase-level summaries\nconst phaseSummaries = data.phases.map(phase => {\n  const phaseStories = data.stories.filter(s => s.phase_id === phase.phase_id);\n  const phaseStoryIds = phaseStories.map(s => s.story_id);\n  const phasePoints = data.points.filter(p => phaseStoryIds.includes(p.story_id));\n  const phaseCosts = data.costs.filter(c => phaseStoryIds.includes(c.story_id));\n  \n  return {\n    phase_id: phase.phase_id,\n    phase_name: phase.phase_name,\n    story_count: phaseStories.length,\n    total_points: phasePoints.reduce((sum, p) => sum + p.points, 0),\n    total_hours: phaseCosts.reduce((sum, c) => sum + c.hours, 0),\n    total_cost: phaseCosts.reduce((sum, c) => sum + c.cost, 0)\n  };\n});\n\n// Add comprehensive estimation summary\ndata.estimation = {\n  total_points: totalPoints,\n  total_hours: totalHours,\n  total_cost: totalCost,\n  total_cost_formatted: '$' + totalCost.toLocaleString(),\n  average_hours_per_story: Math.round(totalHours / data.stories.length),\n  average_cost_per_story: Math.round(totalCost / data.stories.length),\n  story_count: data.stories.length,\n  phase_count: data.phases.length,\n  phase_summaries: phaseSummaries,\n  estimated_duration_weeks: Math.ceil(totalHours / 40),\n  complexity_breakdown: {\n    low: data.points.filter(p => p.complexity === 'low').length,\n    medium: data.points.filter(p => p.complexity === 'medium').length,\n    high: data.points.filter(p => p.complexity === 'high').length\n  }\n};\n\nreturn [{ json: data }];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        1520,
        144
      ],
      "id": "1ff31c12-f5f4-4117-b195-1438b9023bc8",
      "name": "Calculate Totals"
    },
    {
      "parameters": {
        "jsCode": "const data = $input.first().json;\n\nreturn [{\n  json: {\n    success: true,\n    data: data,\n    metadata: {\n      generated_at: new Date().toISOString(),\n      version: '1.0',\n      rate_per_hour: 150,\n      hours_per_point: 4\n    }\n  }\n}];"
      },
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        1824,
        144
      ],
      "id": "c4e4898e-57bd-4768-9e1b-7499a85e075f",
      "name": "Format Final Output"
    },
    {
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{ $json }}",
        "options": {}
      },
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1.5,
      "position": [
        2112,
        144
      ],
      "id": "e82b6cb5-de28-4b49-8674-d16f85816e84",
      "name": "Send Estimate Back"
    },
    {
      "parameters": {
        "content": "Webhook endpoint that receives \nPOST requests with project \ndescriptions from users",
        "height": 224
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        528,
        48
      ],
      "id": "7bd7ad56-ec3d-4de2-8186-da4214ecdf10",
      "name": "Sticky Note"
    },
    {
      "parameters": {
        "content": "Sends project description to LLM\nwith detailed prompt asking for\nphases, stories, points & costs\nin JSON format",
        "height": 224,
        "width": 256
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        816,
        48
      ],
      "id": "7f7581d1-b575-4766-a0db-6e36dbc0fb41",
      "name": "Sticky Note1"
    },
    {
      "parameters": {
        "content": "Extracts JSON from LLM output,\nremoves markdown code fences,\nvalidates required fields exist",
        "height": 224,
        "width": 256
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        1104,
        64
      ],
      "id": "bb8204ec-d403-4b99-9cf8-e8a21054462a",
      "name": "Sticky Note2"
    },
    {
      "parameters": {
        "content": "Sums up story points, hours, costs\nCreates phase summaries and\ncomplexity breakdown metrics",
        "height": 224,
        "width": 256
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        1440,
        64
      ],
      "id": "3f3c4677-5bf1-45de-b4ba-2454433ae3ee",
      "name": "Sticky Note3"
    },
    {
      "parameters": {
        "content": "Wraps everything in success\nresponse with metadata\n(timestamp, version, rates)",
        "height": 224,
        "width": 256
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        1744,
        64
      ],
      "id": "d822a759-9d29-46ae-b60a-8033de1dfc3d",
      "name": "Sticky Note4"
    },
    {
      "parameters": {
        "content": "Returns the complete estimate\nas JSON response back to\nthe webhook caller",
        "height": 224,
        "width": 256
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        2048,
        64
      ],
      "id": "c61222a1-edc8-4e59-9b8a-300e399ec642",
      "name": "Sticky Note5"
    },
    {
      "parameters": {
        "content": "We use story points to estimate complexity. Think of them like t-shirt sizes - small tasks get fewer points, big tasks get more points. Each point equals about 4 hours of work at $150/hour.\n\nSo a 5-point story = 20 hours = $3,000\nThe system breaks your project into phases, then into specific user stories, scores each one, and adds it all up to give you the total.",
        "height": 192,
        "width": 416
      },
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [
        1312,
        432
      ],
      "id": "8dc21a9e-0bbc-453c-a061-5bf28bcbfafd",
      "name": "Sticky Note6"
    }
  ],
  "pinData": {},
  "connections": {
    "OpenAI Chat Model1": {
      "ai_languageModel": [
        [
          {
            "node": "Generate Estimate Data",
            "type": "ai_languageModel",
            "index": 0
          }
        ]
      ]
    },
    "Receive Project Request": {
      "main": [
        [
          {
            "node": "Generate Estimate Data",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Generate Estimate Data": {
      "main": [
        [
          {
            "node": "Parse LLM Response",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Parse LLM Response": {
      "main": [
        [
          {
            "node": "Calculate Totals",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Calculate Totals": {
      "main": [
        [
          {
            "node": "Format Final Output",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Format Final Output": {
      "main": [
        [
          {
            "node": "Send Estimate Back",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1",
    "availableInMCP": false
  },
  "versionId": "c896e6f9-de50-4f73-a74a-1c899780cee7",
  "meta": {
    "templateCredsSetupCompleted": true,
    "instanceId": "430ee6fd30b49b2f1b0c45b73715ac19deaab77bbbd9a9dc04b6b81436ef5492"
  },
  "id": "wf8lqGqXqBhPkQosyExok",
  "tags": []
}
