/**
 * Contract every AI-callable tool implements. This is the "AI должен иметь
 * инструменты: create_task; update_task; create_reminder; ..." piece of the
 * architecture in section 16 of the product plan — new tools (create_reminder,
 * create_purchase, save_document, add_expense, ...) plug in by implementing
 * this interface and registering with AiToolRegistry, without touching
 * AiService's orchestration loop.
 */
export interface AiTool<TInput = unknown, TResult = unknown> {
  /** Name the model uses to call the tool; must match the Anthropic tool schema name. */
  readonly name: string;
  /** Shown to the model so it knows when/how to call the tool. */
  readonly description: string;
  /** JSON Schema for the tool's input, passed to Anthropic as `input_schema`. */
  readonly inputSchema: Record<string, unknown>;
  /** Executes the tool for a given authenticated user. */
  execute(userId: string, input: TInput): Promise<TResult>;
}
