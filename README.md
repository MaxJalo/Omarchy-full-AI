# Omarchy-full-AI

Полная переносимая конфигурация **Arch Linux + Omarchy + Hyprland + Quickshell + Ghostty + OpenCode V2 + SDDM Liquid Glass** (by **MaxJalo**).

## Что входит
* **Единый экран входа и блокировки (`macOS Liquid Glass`):**
  * `sddm/maxjalo-glass/` (SDDM Qt6) + `config/omarchy/plugins/maxjalo.lock/` (Quickshell lock)
  * Живой Qt6 `.qsb`-шейдер преломления и спекулярного блика (`liquidglass.frag`)
  * Прогрессивный радиальный блюр от краёв к чёткому центру, часы macOS, кольцевой спиннер 0.5 с и плавный переход в систему
* **Верхняя панель (`Floating Glass Islands`):**
  * `config/omarchy/plugins/maxjalo.bar/` + `maxjalo.workspaces/` + кастомные виджеты (`cpu-load`, `cpu-temp`, `ram`, `gpu-load`, `gpu-memory`, `disk`, `btop`, `weather`)
  * Три парящих стеклянных островка с динамической адаптацией иконок при двойном клике, круглыми индикаторами рабочих столов и запуском `btop` по клику
* **Анимированные обои с дождём и каплями на экране:**
  * `config/omarchy/plugins/maxjalo.background/` с GPU-шейдером `rain.frag` (капли воды с преломлением на стекле + косые струи пасмурного дождя) и поддержкой `.mp4`/`.webm`/`.gif`
  * Набор 4K аниме/арт-обоев в `config/omarchy/backgrounds/blasphemous/`
* **Ghostty + Fish:**
  * Единственный системный терминал (`Ghostty`) с вкладками сверху, полупрозрачностью и без приветствия `fish`
* **OpenCode V2 (`Cursor`-уровень):**
  * `LSP`, локальный плагин уведомлений `omarchy-notify`, агенты (`architect`, `reviewer`, `ui-designer`), 4 глобальных скилла (`qml-quickshell`, `git-workflow`, `code-review`, `linux-sysadmin`) и хоткеи `Ctrl+K`, `Ctrl+B`, `<leader>d`
  * **4 MCP-сервера:** `context7` (актуальная документация), `sequential-thinking` (глубокое рассуждение), `memory` (граф памяти между сессиями), `playwright` (автоматизация браузера)
* **VPN клиент:** нативный **Happ** (`4.7.2`) с `happd` демоном и поддержкой VLESS/Reality/VMess/подписок

## Основные горячие клавиши
| Сочетание | Действие |
|---|---|
| `Super + Enter` | Терминал **Ghostty** |
| `Super + Shift + A` | **OpenCode** (`--auto`) в Ghostty |
| `Super + Alt + A` | Быстрый плавающий AI-чат (`opencode mini`) |
| `Super + Shift + M` | **Gmail** |
| `Super + E` | Файловый менеджер (`Nautilus`, как `Win + E`) |
| `Super + L` | Блокировка экрана (как `Win + L`) |
| `Super + R` | Лаунчер приложений (как `Win + R`) |
| `Super + I` | Системное меню / настройки (как `Win + I`) |
| `Super + Shift + S` / `Ctrl + Shift + S` | Скриншот области |
| `Super + Alt + S` | Запись экрана |
| `Super + Ctrl + Space` | Переключатель обоев |

## Установка на новую систему
```bash
git clone https://github.com/MaxJalo/Omarchy-full-AI.git
cd Omarchy-full-AI
chmod +x install.sh
./install.sh
```
Для работы провайдера Polza.ai задайте переменную `POLZA_API_KEY` (например, в `~/.config/fish/config.fish`) или впишите ключ в `~/.config/opencode/opencode.json`.
