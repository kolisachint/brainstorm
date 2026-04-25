# Plan: Tune OpenCode Agent Configurations (3 Modes)

## Context

Three OpenCode agent configs need tuning based on agent role analysis:

- **Normal mode**: Architecture work. GLM-5 only for oracle + ultrabrain. Strategic token usage.
- **Frugal mode**: Daily driver. No GLM-5. kimi-k2.5 for quality, minimax/deepseek for speed.
- **Dirt-cheap mode**: Logic changes. qwen3.5-plus for reasoning/coding, deepseek-v4-flash everything else.

## Changes

### 1. Normal Mode (~/.config/opencode/oh-my-openagent.json)

| Agent | Current | New | Why |
|-------|---------|-----|-----|
| sisyphus | minimax-m2.7 | **kimi-k2.5** | Orchestration needs context understanding |
| oracle | kimi-k2.5 | **glm-5** | The brain — only agent that truly needs max reasoning |
| prometheus | kimi-k2.5 | kimi-k2.5 | No change |
| momus | kimi-k2.5 | kimi-k2.5 | No change |
| metis | kimi-k2.5 | kimi-k2.5 | No change |
| atlas | kimi-k2.5 | kimi-k2.5 | No change |
| sisyphus-junior | minimax-m2.7 | **kimi-k2.5** | Task execution needs decent quality |
| multimodal-looker | kimi-k2.5 | kimi-k2.5 | No change |

| Category | Current | New | Why |
|----------|---------|-----|-----|
| ultrabrain | kimi-k2.5 | **glm-5** | Hard logic needs best reasoning |
| deep | kimi-k2.5 | kimi-k2.5 | No change |
| quick | deepseek-v4-flash | **minimax-m2.7** | Quick doesn't need cheapest, just fast |
| writing | minimax-m2.7 | **kimi-k2.5** | Writing needs language quality |

Full JSON content for Normal mode:

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "oracle": {
      "model": "opencode-go/glm-5"
    },
    "librarian": {
      "model": "opencode-go/minimax-m2.7",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "explore": {
      "model": "opencode-go/minimax-m2.7",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "multimodal-looker": {
      "model": "opencode-go/kimi-k2.5"
    },
    "prometheus": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "metis": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "momus": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "atlas": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "sisyphus-junior": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    }
  },
  "categories": {
    "visual-engineering": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "ultrabrain": {
      "model": "opencode-go/glm-5"
    },
    "deep": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "quick": {
      "model": "opencode-go/minimax-m2.7",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "unspecified-low": {
      "model": "opencode-go/minimax-m2.7",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "unspecified-high": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "writing": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    }
  }
}
```

### 2. Frugal Mode (~/.config/opencode/oh-my-openagent-frugal.json)

| Agent | Current | New | Why |
|-------|---------|-----|-----|
| sisyphus | minimax-m2.7 | minimax-m2.7 | No change — daily orchestration can be cheaper |
| oracle | kimi-k2.5 | kimi-k2.5 | No change |
| prometheus | kimi-k2.5 | kimi-k2.5 | No change |
| metis | kimi-k2.5 | kimi-k2.5 | No change |
| momus | kimi-k2.5 | kimi-k2.5 | No change |
| atlas | kimi-k2.5 | kimi-k2.5 | No change |
| sisyphus-junior | minimax-m2.7 | minimax-m2.7 | No change |
| multimodal-looker | kimi-k2.5 | kimi-k2.5 | No change |
| librarian | minimax-m2.7 | **deepseek-v4-flash** | Search = cheapest fastest |
| explore | minimax-m2.7 | **deepseek-v4-flash** | Grep = cheapest fastest |

| Category | Current | New | Why |
|----------|---------|-----|-----|
| quick | deepseek-v4-flash | deepseek-v4-flash | No change |
| unspecified-low | minimax-m2.7 | **deepseek-v4-flash** | Cheaper for daily |
| writing | minimax-m2.7 | **deepseek-v4-flash** | Daily writing doesn't need minimax |

Full JSON content for Frugal mode:

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "opencode-go/minimax-m2.7",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "oracle": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "librarian": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "explore": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "multimodal-looker": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "prometheus": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "metis": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "momus": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "atlas": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "sisyphus-junior": {
      "model": "opencode-go/minimax-m2.7",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    }
  },
  "categories": {
    "visual-engineering": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "ultrabrain": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "deep": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "quick": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "unspecified-low": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "unspecified-high": {
      "model": "opencode-go/kimi-k2.5",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7"}]
    },
    "writing": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    }
  }
}
```

### 3. Dirt-Cheap Mode (~/.config/opencode/oh-my-openagent-dirt-cheap.json)

| Agent | Current | New | Why |
|-------|---------|-----|-----|
| sisyphus | deepseek-v4-flash | **qwen3.5-plus** | Orchestrator needs instruction following, deepseek struggles |
| oracle | deepseek-v4-flash | **qwen3.5-plus** | Even cheap mode needs reasoning for oracle |
| prometheus | qwen3.5-plus | qwen3.5-plus | No change |
| metis | qwen3.5-plus | **deepseek-v4-flash** | Lighter analysis task, deepseek works |
| momus | qwen3.5-plus | qwen3.5-plus | No change |
| atlas | qwen3.5-plus | qwen3.5-plus | No change |
| multimodal-looker | qwen3.5-plus | qwen3.5-plus | No change |
| sisyphus-junior | deepseek-v4-flash | deepseek-v4-flash | No change |
| librarian | deepseek-v4-flash | deepseek-v4-flash | No change |
| explore | deepseek-v4-flash | deepseek-v4-flash | No change |

| Category | Current | New | Why |
|----------|---------|-----|-----|
| writing | deepseek-v4-flash | deepseek-v4-flash | No change |

Full JSON content for Dirt-cheap mode:

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json",
  "agents": {
    "sisyphus": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "oracle": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "librarian": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "explore": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "multimodal-looker": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "prometheus": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "metis": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "momus": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "atlas": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "sisyphus-junior": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    }
  },
  "categories": {
    "visual-engineering": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "ultrabrain": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "deep": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "quick": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "unspecified-low": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    },
    "unspecified-high": {
      "model": "opencode-go/qwen3.5-plus",
      "fallback_models": [{"model": "opencode-go/deepseek-v4-flash"}]
    },
    "writing": {
      "model": "opencode-go/deepseek-v4-flash",
      "fallback_models": [{"model": "opencode-go/minimax-m2.7-highspeed"}]
    }
  }
}
```

### 4. Update Mode Switcher Comparison Table

Update `~/.config/opencode/opencode-mode` compare function with new model assignments.

## Key Design Decisions

1. **Normal mode is conservative with GLM-5**: Only oracle + ultrabrain get GLM-5. Everything else uses kimi-k2.5 or minimax-m2.7. This preserves the 4,300/month GLM-5 quota.

2. **Frugal mode is the daily driver**: Uses deepseek-v4-flash for search/explore/writing/quick tasks instead of minimax-m2.7. This is actually cheaper while still effective.

3. **Dirt-cheap promotes sisyphus + oracle to qwen3.5-plus**: Deepseek-v4-flash was too weak for orchestration and deep reasoning. Qwen3.5-plus has 50,500/month quota which is plenty.

4. **Dirt-cheap demotes metis to deepseek-v4-flash**: Pre-planning analysis is lighter work, deepseek can handle it. Saves qwen3.5-plus quota for more critical agents.

## Files to Modify

1. `~/.config/opencode/oh-my-openagent.json` — Full rewrite
2. `~/.config/opencode/oh-my-openagent-frugal.json` — 3 changes (librarian, explore, writing, unspecified-low categories)
3. `~/.config/opencode/oh-my-openagent-dirt-cheap.json` — 2 changes (sisyphus, oracle promoted to qwen3.5-plus; metis demoted to deepseek-v4-flash)
4. `~/.config/opencode/opencode-mode` — Update comparison table