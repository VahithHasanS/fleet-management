import { createHash, randomUUID } from 'crypto';

export function newId(prefix: string): string {
  return `${prefix}_${randomUUID().replace(/-/g, '').slice(0, 12)}`;
}

export function shortHash(input: string): string {
  return createHash('sha256').update(input).digest('hex').slice(0, 12);
}

export function monotonicNow(): number {
  return Date.now();
}