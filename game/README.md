# Black Cat Journey - Godot M1 Prototype

这是《黑猫旅程》的 Godot 4.x M1 原型目录。当前目标是验证第三人称黑猫移动、普通猫结伴、白猫短对白和多区域混合氛围，不代表最终美术。

## 运行

```bash
godot --path /Users/tianyi/Documents/Codex_project/black-cat-journey/game
```

如果 `godot` 不在 PATH，可从 `/Applications/Godot.app` 打开项目。

## 控制

- `W/A/S/D`：移动
- `Shift`：奔跑
- `Space`：跳跃
- 鼠标：转动视角
- `E`：叫声事件占位
- `Esc`：释放鼠标

## 当前实现

- 黑色短毛中华田园猫占位角色，黄眼睛。
- 三段混合区域占位：草地区、废墟区、月光浅雪区。
- 3 只普通 AI 猫：靠近玩家后短暂结伴，之后自然离队。
- 1 只白色长毛猫：靠近后循环触发温柔治愈台词和轻冷笑话。
- 可替换材料、对白 JSON、场景和脚本分离。

## 资产替换约定

- 正式模型优先替换 `scenes/player_cat.tscn` 和 `scenes/cats/*.tscn` 的视觉子节点。
- 角色控制、AI 状态和对白逻辑保留在 `scripts/`，不要写进模型节点。
- 白猫台词维护在 `data/white_cat_dialogue.json`。
- 占位材质在 `materials/`，后续可替换为手绘或生成材质。

