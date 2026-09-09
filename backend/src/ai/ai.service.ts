import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Anthropic from '@anthropic-ai/sdk';
import { AiConversation } from './entities/ai-conversation.entity.js';
import { AiMessage, AiMessageRole } from './entities/ai-message.entity.js';
import { CreateTaskTool } from './tools/create-task.tool.js';
import type { AiTool } from './tools/ai-tool.interface.js';

const SYSTEM_PROMPT = `Ты — Yordam, цифровой помощник реальной жизни. Твоя задача — не просто
отвечать пользователю, а доводить его проблему до результата: понять запрос,
при необходимости уточнить детали, и когда пользователь просит что-то сделать
(задача, поручение, напоминание о деле) — вызвать соответствующий инструмент,
а не просто описать план словами. Отвечай на языке пользователя (русский,
узбекский или английский). Будь кратким и по делу.`;

const MAX_TOOL_ROUNDS = 4;

export interface ChatResult {
  conversationId: string;
  reply: string;
  toolCalls: Array<{ tool: string; input: unknown; result: unknown }>;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly client: Anthropic | null;
  private readonly model: string;
  private readonly tools: Map<string, AiTool>;

  constructor(
    private readonly configService: ConfigService,
    @InjectRepository(AiConversation)
    private readonly conversationsRepository: Repository<AiConversation>,
    @InjectRepository(AiMessage)
    private readonly messagesRepository: Repository<AiMessage>,
    createTaskTool: CreateTaskTool,
  ) {
    const apiKey = this.configService.get<string>('ANTHROPIC_API_KEY');
    this.client = apiKey ? new Anthropic({ apiKey }) : null;
    this.model = this.configService.get<string>('AI_MODEL', 'claude-sonnet-5');

    // Sprint 1 registers a single tool. Future tools (create_reminder,
    // create_purchase, save_document, add_expense, search_products, ...)
    // just get added to this list — AiService itself doesn't change.
    const toolList: AiTool[] = [createTaskTool];
    this.tools = new Map(toolList.map((tool) => [tool.name, tool]));
  }

  async chat(userId: string, message: string, conversationId?: string): Promise<ChatResult> {
    const conversation = await this.getOrCreateConversation(userId, conversationId, message);

    await this.saveMessage(conversation.id, AiMessageRole.USER, message);

    if (!this.client) {
      // No API key configured (e.g. local dev without secrets) — fail loudly
      // in a way the client can render, instead of silently pretending to work.
      const reply =
        'AI пока не настроен: не задан ANTHROPIC_API_KEY на сервере. ' +
        'Задача не создана автоматически — добавьте её вручную в разделе «Задачи».';
      await this.saveMessage(conversation.id, AiMessageRole.ASSISTANT, reply);
      return { conversationId: conversation.id, reply, toolCalls: [] };
    }

    const history = await this.messagesRepository.find({
      where: { conversationId: conversation.id },
      order: { createdAt: 'ASC' },
      take: 20,
    });

    const messages: Anthropic.MessageParam[] = history.map((m) => ({
      role: m.role === AiMessageRole.ASSISTANT ? 'assistant' : 'user',
      content: m.content,
    }));

    const toolCalls: ChatResult['toolCalls'] = [];
    let finalText = '';

    for (let round = 0; round < MAX_TOOL_ROUNDS; round += 1) {
      const response = await this.client.messages.create({
        model: this.model,
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages,
        tools: Array.from(this.tools.values()).map((tool) => ({
          name: tool.name,
          description: tool.description,
          input_schema: tool.inputSchema as Anthropic.Tool.InputSchema,
        })),
      });

      const textBlocks = response.content.filter((b) => b.type === 'text');
      finalText = textBlocks.map((b) => (b as { text: string }).text).join('\n').trim();

      const toolUseBlocks = response.content.filter((b) => b.type === 'tool_use');
      if (toolUseBlocks.length === 0) {
        break;
      }

      messages.push({ role: 'assistant', content: response.content });

      const toolResults: Anthropic.MessageParam['content'] = [];
      for (const block of toolUseBlocks) {
        const toolUse = block as Anthropic.ToolUseBlock;
        const tool = this.tools.get(toolUse.name);
        let result: unknown;
        let isError = false;
        try {
          if (!tool) {
            throw new Error(`Unknown tool: ${toolUse.name}`);
          }
          result = await tool.execute(userId, toolUse.input);
          toolCalls.push({ tool: toolUse.name, input: toolUse.input, result });
        } catch (error) {
          isError = true;
          result = { error: error instanceof Error ? error.message : 'Tool execution failed' };
          this.logger.error(`Tool ${toolUse.name} failed`, error as Error);
        }
        toolResults.push({
          type: 'tool_result',
          tool_use_id: toolUse.id,
          content: JSON.stringify(result),
          is_error: isError,
        });
      }
      messages.push({ role: 'user', content: toolResults });
    }

    const reply = finalText || 'Готово.';
    await this.saveMessage(conversation.id, AiMessageRole.ASSISTANT, reply);

    return { conversationId: conversation.id, reply, toolCalls };
  }

  private async getOrCreateConversation(
    userId: string,
    conversationId: string | undefined,
    firstMessage: string,
  ): Promise<AiConversation> {
    if (conversationId) {
      const existing = await this.conversationsRepository.findOne({
        where: { id: conversationId, userId },
      });
      if (existing) {
        return existing;
      }
    }
    const conversation = this.conversationsRepository.create({
      userId,
      title: firstMessage.slice(0, 80),
    });
    return this.conversationsRepository.save(conversation);
  }

  private saveMessage(conversationId: string, role: AiMessageRole, content: string) {
    const message = this.messagesRepository.create({ conversationId, role, content });
    return this.messagesRepository.save(message);
  }
}
