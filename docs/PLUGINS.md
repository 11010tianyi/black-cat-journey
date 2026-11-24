# 插件与第三方库清单

最后更新：2026-11-24（commit `3396047` 之后）

## 1. 当前启用的插件

| 插件 | 版本 | 类型 | 用途 | 是否进仓库 |
| --- | --- | --- | --- | --- |
| `dialogue_manager` | 2.x | GDScript | 白猫对话的解析与气泡 UI，`white_cat.gd` 通过 `DialogueManager.show_dialogue_balloon()` 调用 | 是 |
| `terrain_3d` | 1.0.2 | **C++ GDExtension** | 可雕刻、可刷纹理、带 LOD 的地形系统，用于后续替换程序化高度场 | 是（含各平台二进制） |

`game/project.godot` 的 `[editor_plugins]` 只启用这两个。

## 2. 本地完整副本（含全部插件的源目录）

```
~/Documents/Codex_project/black-cat-journey/
├── game/addons/            # 6 个插件全在：beehave / dialogue_manager / jeheno_third_person_controller
│                           #                  phantom_camera / proton_scatter / terrain_3d
└── game/addons/terrain_3d/bin/   # 全平台二进制（android/ios/linux/macos/web/windows，debug+release）
```

- 该副本 101MB，git 停在 `e68028d`（「插件集成完成、还没做可玩切片」的状态）。
- **所有插件的原生库都在这份副本里**，需要恢复时直接从那里 `cp -R`，不必再去 GitHub Release 下载。

## 3. 已移除的插件（仍在 git 历史里）

删除于 `b5a4d93`，可随时 `git checkout b5a4d93^ -- game/addons/<名字>` 取回。

| 插件 | 体积 | 类型 | 当时为什么移除 |
| --- | --- | --- | --- |
| `beehave` | 656K | GDScript（45 个 .gd） | AI 用的是 `cat_ai_controller.gd` 手写状态机，行为树叶子脚本（`scripts/ai/*.gd`）全部孤儿 |
| `phantom_camera` | 1.2M | GDScript | 自带跟随相机足够；且它的 `PhantomCameraManager` autoload 没配，编辑器启动必报错 |
| `proton_scatter` | 13M | GDScript（82 个 .gd） | 碎石/草改为运行时 MultiMesh 手写，不需要编辑器撒点工具 |
| `jeheno_third_person_controller` | 4M | GDScript | 玩家控制器是手写的，插件没被引用 |
| `terrain_3d` | 18M 源码 + 39M 二进制 | GDExtension | 当时未使用（现在已恢复） |

合计移除约 37MB（源码部分）；**git 历史里仍然存在，clone 体积不会因此变小**。

## 4. 二进制与线上打包（重要）

GDExtension 的规则：**导出到哪个平台，就必须在仓库里有那个平台的库文件**，否则包能出但一运行就崩。云端 CI 是 Linux runner，加载扩展本身还需要 Linux 的 `.so`。

| 目标平台 | 需要的文件 | 仓库中 |
| --- | --- | --- |
| Linux x86_64 | `libterrain.linux.{debug,release}.x86_64.so` | ✅ |
| Windows x86_64 | `libterrain.windows.{debug,release}.x86_64.dll` | ✅ |
| macOS（universal） | `libterrain.macos.{debug,release}.framework/` | ✅ |
| Android arm64-v8a | `libterrain.android.{debug,release}.arm64.so` | ✅ |
| Android armeabi-v7a | `libterrain.android.{debug,release}.arm32.so` | ✅ |
| iOS | `libterrain.ios.*.universal.dylib` | ✅（暂未使用） |
| Web | `libterrain.web.*.wasm32.wasm` | ✅（**无效**，见下） |

> `.gitignore` 里原本忽略 `game/addons/terrain_3d/bin/libterrain.*`，已删除这些规则，否则云端打包拿不到库。

**实测补充**：当前场景还没有任何节点使用 Terrain3D，所以导出时 Godot 没有把
`libterrain.*` 打进 APK（构建日志里只有 `libgodot_android.so` 等）。这是正常行为——
GDExtension 的原生库只在扩展被加载/使用时才进入包。**一旦场景里出现 Terrain3D 节点，
对应平台的库会被自动加进去**，前提就是仓库里有那个文件。

## 5. Web 为什么不行

Godot 官方 Web 导出模板的构建配置是 `single-threaded, no GDExtension support`（在导出包里实测到的日志）。Terrain3D 是 GDExtension，因此 Web 端无法加载，`terrain.gdextension` 里那两个 `.wasm` 条目不会被用到。

Web 目标已冻结，代码存档在分支 `archive/web-build` 和 Release `web-archive-0.2`。

## 6. 后续开发推荐

**适合这个项目、且与现有代码不冲突：**

- `terrain_3d`（已恢复）— 地图雕刻、纹理绘制、植被 LOD。适合把现在 `world_builder.gd` 的程序化地形换成手绘地形。
- `proton_scatter` — 与 Terrain3D 同一作者生态，用来在雕刻好的地形上撒植被/碎石。需要时可从本地副本恢复。
- `beehave` — 如果 AI 从「跟随/离队」扩展到更多状态（警戒、追逐、休息），行为树比手写状态机好维护。
- `phantom_camera` — 需要过场镜头、镜头震动、多机位切换时再引入；引入时记得补 `PhantomCameraManager` autoload。

**外部推荐（尚未下载）：**

- [Godot Jolt](https://github.com/godot-jolt/godot-jolt) — 更快更稳的 3D 物理（角色移动、斜坡手感）。
- [Orchestrator](https://github.com/Crater-Software/Orchestrator) — 可视化脚本，适合策划改事件流程。
- [Godot Terrain3D 官方示例](https://github.com/TokisanGames/Terrain3D) — 恢复 Terrain3D 后对照它的小地图示例，比从零摸 API 快。

## 7. 踩坑日志（按时间）

| 问题 | 现象 | 结论 |
| --- | --- | --- |
| Terrain3D 不在 Web | 导出包日志 `no GDExtension support` | Web 只能用纯脚本/程序化方案 |
| `PhantomCameraManager` | 编辑器启动报 `non-existent singleton` | 插件启用但 autoload 未注册；删除插件后消失 |
| 原生库缺失 | 导出成功但运行时崩 | `.gitignore` 忽略了 `libterrain.*`，云端打包拿不到 |
| ETC2/ASTC | macOS/Android 导出失败，错误列表为空 | 开 `rendering/textures/vram_compression/import_etc2_astc=true` |
| NavMesh 烘焙 0 面 | `bake_navigation_mesh()` 无几何 | 只解析 region 自己的子树，地形要挂在 region 下 |
| 触屏控件无响应 | 摇杆拖不动 | 根节点 `MOUSE_FILTER_IGNORE` 会连子节点一起屏蔽（已改，但 Web 端仍未验证通过） |

## 8. Terrain3D 接入记录（2026-11-24）

主场景地形已从程序化网格换成 Terrain3D。落地时踩到的坑：

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `Cannot assign a new value to a read-only property` | `data` / `material` / `assets` / `collision` 都是只读 | `add_child()` 后 Terrain3D 会自动建好，直接改现成对象 |
| `No active region found` | region `(0,0)` 只覆盖 z ≥ 0 | 负 z 用 `(0,-1)`，且边界值归属相邻 region，循环要从 1 开始 |
| 地形显示棋盘格 | Terrain3D 的调试视图默认开着 | 同时关 `terrain.show_checkered` 和 `material.show_checkered` |
| `Parameter "material" is null` | 用 `Terrain3DMaterial.new()` 覆盖会丢内部 RID | 取 `terrain.material` 原地改 `shader_override` |
| 碰撞缺失、角色掉落 | `collision_mode = 0` 时没有碰撞；开启后又是异步生成 | 用同一份 `height_at()` 单独生成 2 米精度碰撞网格（`create_trimesh_collision`），保证第一帧就有地面 |

配色：`game/shaders/terrain_palette.gdshader` 基于 addon 的 `minimum.gdshader`，用
Poly Haven 的 CC0 纹理做三平面混合（草 / 岩 / 雪），按高度和坡度过渡。
纹理：`game/assets/textures/terrain/*.jpg`（各 1k，来自 polyhaven.com，CC0）。

**已知未完成**：`use_nature_models = true` 时用 Quaternius 自然包（CC0）的
草丛/石头/树做 MultiMesh 撒点，实例创建成功但渲染不出来——连纯 `BoxMesh`
的 MultiMesh 都不显示，判断是我的 MultiMesh 装配方式问题而非模型资源。
默认 `use_nature_models = false`，退回程序化圆锥/球体，保证画面不空。
