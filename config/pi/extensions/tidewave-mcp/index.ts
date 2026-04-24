import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { SSEClientTransport } from "@modelcontextprotocol/sdk/client/sse.js";

type TidewaveConnection = {
  name: string;
  url: string;
  client: Client;
  transport: StreamableHTTPClientTransport | SSEClientTransport;
  transportKind: "streamable-http" | "sse";
  connectedAt: string;
};

const DEFAULT_URLS = [
  "rails=http://localhost:3000/tidewave/mcp",
  "phoenix=http://localhost:4000/tidewave/mcp",
];

function configuredEndpoints(): Array<{ name: string; url: string }> {
  const raw = process.env.TIDEWAVE_MCP_URLS || process.env.TIDEWAVE_MCP_URL || DEFAULT_URLS.join(",");
  return raw
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part, index) => {
      const eq = part.indexOf("=");
      if (eq > 0) return { name: part.slice(0, eq).trim(), url: part.slice(eq + 1).trim() };
      return { name: index === 0 ? "default" : `app${index + 1}`, url: part };
    });
}

function asText(value: unknown): string {
  if (typeof value === "string") return value;
  return JSON.stringify(value, null, 2);
}

function formatMcpContent(result: any): string {
  const parts: string[] = [];
  if (Array.isArray(result?.content)) {
    for (const item of result.content) {
      if (item?.type === "text") parts.push(item.text ?? "");
      else if (item?.type === "resource") parts.push(asText(item.resource));
      else parts.push(asText(item));
    }
  }
  if (result?.structuredContent !== undefined) parts.push(asText(result.structuredContent));
  if (result?.toolResult !== undefined) parts.push(asText(result.toolResult));
  if (parts.length === 0) parts.push(asText(result));
  return parts.join("\n\n");
}

export default function (pi: ExtensionAPI) {
  const connections = new Map<string, TidewaveConnection>();

  async function connectEndpoint(endpoint: { name: string; url: string }, signal?: AbortSignal): Promise<TidewaveConnection> {
    const existing = connections.get(endpoint.name);
    if (existing) return existing;

    let lastError: unknown;
    for (const kind of ["streamable-http", "sse"] as const) {
      const client = new Client({ name: "pi-tidewave", version: "1.0.0" });
      const transport = kind === "streamable-http"
        ? new StreamableHTTPClientTransport(new URL(endpoint.url))
        : new SSEClientTransport(new URL(endpoint.url));
      try {
        await client.connect(transport, { signal, timeout: 5000 });
        const connection: TidewaveConnection = {
          name: endpoint.name,
          url: endpoint.url,
          client,
          transport,
          transportKind: kind,
          connectedAt: new Date().toISOString(),
        };
        connections.set(endpoint.name, connection);
        return connection;
      } catch (error) {
        lastError = error;
        try { await transport.close(); } catch {}
      }
    }

    throw new Error(`Could not connect to Tidewave endpoint ${endpoint.name} (${endpoint.url}): ${lastError instanceof Error ? lastError.message : String(lastError)}`);
  }

  function getEndpoint(nameOrUrl?: string) {
    const endpoints = configuredEndpoints();
    if (!nameOrUrl) return endpoints[0];
    const byName = endpoints.find((endpoint) => endpoint.name === nameOrUrl);
    if (byName) return byName;
    if (/^https?:\/\//.test(nameOrUrl)) return { name: nameOrUrl, url: nameOrUrl };
    throw new Error(`Unknown Tidewave app '${nameOrUrl}'. Configured apps: ${endpoints.map((e) => e.name).join(", ")}`);
  }

  pi.registerTool({
    name: "tidewave_status",
    label: "Tidewave Status",
    description: "Show configured Tidewave MCP endpoints and active connections for Rails/Phoenix projects.",
    promptSnippet: "Show Tidewave MCP endpoint status for local Rails and Phoenix apps.",
    parameters: Type.Object({}),
    async execute() {
      const endpoints = configuredEndpoints();
      const status = endpoints.map((endpoint) => ({
        ...endpoint,
        connected: connections.has(endpoint.name),
        transport: connections.get(endpoint.name)?.transportKind,
        connectedAt: connections.get(endpoint.name)?.connectedAt,
      }));
      return { content: [{ type: "text", text: JSON.stringify(status, null, 2) }], details: { endpoints: status } };
    },
  });

  pi.registerTool({
    name: "tidewave_list_tools",
    label: "Tidewave List Tools",
    description: "List tools exposed by a local Tidewave MCP server. Use this before calling Tidewave tools for Rails or Phoenix app introspection.",
    promptSnippet: "List available Tidewave MCP tools for a Rails or Phoenix app.",
    promptGuidelines: [
      "Use tidewave_list_tools when working on a Rails or Phoenix project and you need runtime/application introspection from Tidewave.",
      "Use tidewave_call_tool to invoke a Tidewave MCP tool after selecting the appropriate tool name from tidewave_list_tools.",
    ],
    parameters: Type.Object({
      app: Type.Optional(Type.String({ description: "Configured app name, usually 'rails' or 'phoenix'. Defaults to the first configured endpoint." })),
    }),
    async execute(_toolCallId, params: { app?: string }, signal) {
      const endpoint = getEndpoint(params.app);
      const connection = await connectEndpoint(endpoint, signal);
      const tools = await connection.client.listTools({}, { signal, timeout: 10000 });
      return { content: [{ type: "text", text: JSON.stringify(tools.tools, null, 2) }], details: { endpoint, tools: tools.tools } };
    },
  });

  pi.registerTool({
    name: "tidewave_call_tool",
    label: "Tidewave Call Tool",
    description: "Call a tool exposed by a local Tidewave MCP server for Rails/Phoenix runtime introspection and development assistance.",
    promptSnippet: "Call a Tidewave MCP tool on a local Rails or Phoenix app.",
    promptGuidelines: [
      "Use tidewave_call_tool for Rails/Phoenix application questions that benefit from Tidewave runtime context, after listing tools if you do not know the exact tool name.",
      "For Tidewave, pass app as 'rails' for localhost:3000 or 'phoenix' for localhost:4000 unless the user configured different TIDEWAVE_MCP_URLS.",
    ],
    parameters: Type.Object({
      app: Type.Optional(Type.String({ description: "Configured app name, usually 'rails' or 'phoenix'. Defaults to the first configured endpoint." })),
      toolName: Type.String({ description: "The Tidewave MCP tool name to call." }),
      arguments: Type.Optional(Type.Record(Type.String(), Type.Any(), { description: "Arguments for the Tidewave MCP tool." })),
    }),
    async execute(_toolCallId, params: { app?: string; toolName: string; arguments?: Record<string, unknown> }, signal) {
      const endpoint = getEndpoint(params.app);
      const connection = await connectEndpoint(endpoint, signal);
      const result = await connection.client.callTool({ name: params.toolName, arguments: params.arguments ?? {} }, undefined, { signal, timeout: 30000 });
      const text = formatMcpContent(result);
      return { content: [{ type: "text", text }], details: { endpoint, toolName: params.toolName, result }, isError: Boolean((result as any)?.isError) };
    },
  });

  pi.registerCommand("tidewave", {
    description: "Show configured Tidewave MCP endpoints",
    handler: async (_args: string, ctx: ExtensionContext) => {
      const endpoints = configuredEndpoints();
      ctx.ui.notify(`Tidewave endpoints: ${endpoints.map((e) => `${e.name}=${e.url}`).join(", ")}`, "info");
    },
  });

  pi.on("session_shutdown", async () => {
    for (const connection of connections.values()) {
      try { await connection.transport.close(); } catch {}
    }
    connections.clear();
  });
}
