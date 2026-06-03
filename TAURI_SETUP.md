# 🎨 Claude Auto-Renew - Tauri App Setup

Um app menubar moderno para gerenciar seu daemon de renovação do Claude Code com interface visual.

## 📦 Pré-requisitos

### 1. Node.js e npm
```bash
# Verificar se já tem instalado
node --version
npm --version
```

Se não tiver:
- Instale do [nodejs.org](https://nodejs.org/)

### 2. Rust (para compilar o app)
```bash
# Instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Ativar no shell atual
source "$HOME/.cargo/env"

# Verificar instalação
rustc --version
cargo --version
```

### 3. Tauri CLI (opcional, mas recomendado)
```bash
npm install -g @tauri-apps/cli
```

## 🚀 Instalação

### 1. Instale as dependências do Node.js
```bash
cd ~/Desktop/Projetos/AI/CCAutoRenew
npm install
```

Isso vai instalar:
- React
- Vite (build tool)
- Tauri API
- Tauri CLI

### 2. Execute em modo desenvolvimento
```bash
npm run tauri:dev
```

Isso vai:
- Compilar o backend Rust
- Iniciar o servidor Vite (frontend)
- Abrir a janela do app
- Permitir hot-reload enquanto você trabalha

### 3. Crie o executável do app (opcional)
```bash
npm run tauri:build
```

Isso vai gerar:
- `src-tauri/target/release/claude-auto-renew.dmg` (instalador)
- `src-tauri/target/release/bundle/macos/Claude Auto-Renew.app` (app compilada)

## 🎯 Funcionalidades

### Dashboard
- ✅ Status do daemon (ativo/inativo)
- ✅ Tempo até próxima renovação
- ✅ Barra de progresso visual
- ✅ Últimas atividades

### Controles
- ▶️ Iniciar daemon
- ⏸️ Parar daemon
- 🔄 Reiniciar daemon
- 🔄 Atualizar status

### Configurações
- ⏰ Horário de início
- ⏰ Horário de parada
- 💬 Mensagem customizada
- ⚙️ Opções avançadas

### Logs
- 📝 Visualizar logs em tempo real
- 🔄 Auto-scroll automático
- 🗑️ Limpar logs

## 🔗 Integração com LaunchAgent

O app funciona com o sistema LaunchAgent que você já instalou. Ele:
1. Lê o status do daemon
2. Controla o daemon via scripts shell
3. Mostra logs em tempo real
4. Permite editar configurações

## 📁 Estrutura do Projeto

```
src/
├── main.jsx              # Entry point React
├── App.jsx              # Componente principal
├── index.css            # Estilos globais
└── components/
    ├── Dashboard.jsx    # Tab: Dashboard
    ├── Settings.jsx     # Tab: Configurações
    └── Logs.jsx         # Tab: Logs

src-tauri/
├── src/
│   └── main.rs         # Backend Rust/Tauri
├── build.rs            # Build script
└── Cargo.toml          # Dependências Rust

tauri.conf.json         # Configuração do Tauri
vite.config.js          # Configuração do Vite
```

## 🔧 Troubleshooting

### "Tauri CLI not found"
```bash
npm install -g @tauri-apps/cli
```

### "Rust not found"
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

### "npm install falha"
```bash
rm -rf node_modules package-lock.json
npm install
```

### Compile erros no Rust
```bash
cd src-tauri
cargo clean
cd ..
npm run tauri:dev
```

## 📱 Usar o App

### Em Desenvolvimento
```bash
npm run tauri:dev
```

### Como App Instalada
1. Compile: `npm run tauri:build`
2. Abra `src-tauri/target/release/bundle/macos/Claude Auto-Renew.app`
3. Arraste para `/Applications`
4. Abra pelo Launchpad ou Spotlight

## 🎨 Próximos Passos (Opcional)

Você pode expandir o app com:
- [ ] Tray icon no menubar
- [ ] Notificações push
- [ ] Atalhos teclado
- [ ] Tema escuro/claro
- [ ] Gráficos de uso
- [ ] Exportar logs

## 📚 Recursos Úteis

- [Tauri Docs](https://tauri.app/v1/guides/)
- [React Docs](https://react.dev/)
- [Vite Docs](https://vitejs.dev/)

## 💡 Dicas

1. **Hot reload**: O frontend recarrega automaticamente quando você edita
2. **DevTools**: Press `Ctrl+Shift+I` (ou `Cmd+Option+I` no Mac) para abrir
3. **Console logs**: Use `console.log()` no React, veja no DevTools
4. **Backend changes**: Reinicie `npm run tauri:dev` para recompilar Rust

---

Pronto! O app está configurado. Execute `npm run tauri:dev` para começar! 🚀
