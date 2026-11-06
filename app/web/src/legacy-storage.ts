const LEGACY_PREFIX = 'llm-agent-';
const PREFIX = 'jarvis-';

type KeyedStorage = Pick<Storage, 'length' | 'key' | 'getItem' | 'setItem' | 'removeItem'>;

/** Leva as preferencias do nome antigo (llm-agent-*) para jarvis-*, sem sobrescrever as novas. */
export function renameLegacyKeys(storage: KeyedStorage): void {
  const legacy: string[] = [];
  for (let i = 0; i < storage.length; i++) {
    const key = storage.key(i);
    if (key?.startsWith(LEGACY_PREFIX)) legacy.push(key);
  }
  for (const key of legacy) {
    const renamed = PREFIX + key.slice(LEGACY_PREFIX.length);
    const value = storage.getItem(key);
    if (value !== null && storage.getItem(renamed) === null) storage.setItem(renamed, value);
    storage.removeItem(key);
  }
}
