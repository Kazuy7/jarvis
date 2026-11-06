import { createRoot } from 'react-dom/client';
import '@xterm/xterm/css/xterm.css';
import './styles.css';
import './three.css';
import { App } from './App.tsx';
import { renameLegacyKeys } from './legacy-storage.ts';

// Preferencias e token guardados com o nome antigo; sem storage, o app so comeca do zero.
try {
  renameLegacyKeys(window.localStorage);
  renameLegacyKeys(window.sessionStorage);
} catch {}

// Sem StrictMode: ele monta os terminais duas vezes e descartaria a saida
// que chega entre as montagens.
createRoot(document.getElementById('root')!).render(<App />);
