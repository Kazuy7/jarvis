import { expect, it } from 'vitest';
import { renameLegacyKeys } from '../src/legacy-storage.ts';

function fakeStorage(initial: Record<string, string>) {
  const data = new Map(Object.entries(initial));
  return {
    data,
    get length() { return data.size; },
    key: (i: number) => [...data.keys()][i] ?? null,
    getItem: (k: string) => data.get(k) ?? null,
    setItem: (k: string, v: string) => void data.set(k, v),
    removeItem: (k: string) => void data.delete(k),
  };
}

it('leva as chaves antigas para o nome novo e apaga as antigas', () => {
  const s = fakeStorage({ 'llm-agent-3d': '0', 'llm-agent-globe-color': 'azul', outra: 'x' });
  renameLegacyKeys(s);
  expect(Object.fromEntries(s.data)).toEqual({ 'jarvis-3d': '0', 'jarvis-globe-color': 'azul', outra: 'x' });
});

it('nao sobrescreve o que ja esta no nome novo', () => {
  const s = fakeStorage({ 'llm-agent-sounds': '0', 'jarvis-sounds': '1' });
  renameLegacyKeys(s);
  expect(Object.fromEntries(s.data)).toEqual({ 'jarvis-sounds': '1' });
});
