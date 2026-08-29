import { Injectable } from '@nestjs/common';
import { EventEmitter } from 'events';

export interface PubSubEvent {
  tenantId: string;
  [key: string]: unknown;
}

/**
 * In-process pub/sub seam. Swappable behind a Redis pub/sub (or Kafka) when the
 * ingestion layer scales horizontally — the rest of the system only depends on
 * the emit/on contract.
 */
@Injectable()
export class PubSub {
  private readonly hub = new EventEmitter();

  emit(channel: string, event: PubSubEvent): void {
    this.hub.emit(channel, event);
  }

  on<T extends PubSubEvent>(channel: string, handler: (event: T) => void): () => void {
    const listener = (e: T) => handler(e);
    this.hub.on(channel, listener);
    return () => this.hub.off(channel, listener);
  }
}