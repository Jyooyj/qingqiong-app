# 清穹 App 故障与安全提示规则

## 1. 文档目的

本文档定义清穹无人清扫车 App 的故障识别、数据校验、主提示优先级、活动故障保留、操作权限和安全任务动作。故障提示服务只能读取输入状态并返回判断结果，不得修改机器人状态、调用 `RobotController`、控制 UI 或访问网络。

## 2. 标准故障与数据异常

| 编号 | 标准名称 | 触发条件 | 标准提示 | 严重程度 | 安全动作 |
| --- | --- | --- | --- | --- | --- |
| `WARN-001` | 普通低电量 | 电量在 10%～19% | 电量不足，建议返回充电 | `medium` | `none` |
| `WARN-002` | 严重低电量 | 有效电量在 0%～9% | 电量过低，禁止开始任务 | `high` | `none` |
| `WARN-003` | 设备离线 | App 无法连接机器人，或机器人状态为离线 | 机器人离线，请检查设备连接 | `high` | `none`；离线时不能提交控制命令 |
| `WARN-004` | 紧急停止 | 收到紧急停止状态或急停事件 | 紧急停止已触发，请确认环境安全后复位 | `high` | `stop` |
| `WARN-005` | 设备故障 | 机器人报告硬件、传感器或其他设备故障 | 设备故障，请检查机器人 | `high` | `stop` |
| `WARN-006` | 定位失败 | 无法获得有效位置，或定位模块报告失败 | 定位失败，请检查定位模块 | `medium` | `stop` |
| `WARN-007` | 路径受阻 | 当前路径被障碍物阻挡且无法继续 | 前方路径受阻，请重新规划任务 | `medium` | `pause` |
| `WARN-008` | 任务执行失败 | 当前任务返回失败结果 | 任务执行失败，请重新尝试 | `low` | `none` |
| `DATA-001` | 电量数据异常 | `battery < 0`、`battery > 100`，或上游明确报告电量传感器数据异常 | 电量数据异常，请检查传感器 | `high` | `none`；禁止开始和继续任务 |

`customWarning` 是无标准编号的最低优先级普通提示：

- `primaryWarningCode=null`
- 不加入 `activeWarningCodes`
- `severity=low`
- 仅在没有任何活动标准故障或数据异常时作为主提示
- 不得与 `WARN-008`“任务执行失败”混淆

严重程度只允许使用 `high`、`medium`、`low`。

## 3. 电量数据校验

电量正常范围为闭区间 `0..100`。服务不得对非法电量进行截断、取绝对值或默认替换。

- `battery=0`：有效数据，命中 `WARN-002`。
- `battery=9`：命中 `WARN-002`。
- `battery=10`、`battery=19`：命中 `WARN-001`。
- `battery=20`、`battery=100`：不产生低电量警告。
- `battery=-1`、`101`、`-999`、`999`：命中 `DATA-001`，`batteryValid=false`。
- 数值越界时不得再根据该数值生成 `WARN-001` 或 `WARN-002`。
- 上游可使用 `batterySensorError=true` 表示数值虽在范围内但传感器数据无效。此时生成 `DATA-001`；若数值本身仍落在低电量范围，可同时保留对应低电量编号，但 `DATA-001` 必须作为更高优先级主提示。

任何 `DATA-001` 状态都必须禁止开始和继续任务，并允许在线状态下提交紧急停止。

## 4. 主提示优先级

完整优先级为：

`紧急停止 WARN-004 > 设备离线 WARN-003 > 设备故障 WARN-005 > 电量数据异常 DATA-001 > 严重低电量 WARN-002 > 定位失败 WARN-006 > 路径受阻 WARN-007 > 普通低电量 WARN-001 > 任务执行失败 WARN-008 > customWarning`

规则如下：

1. `primaryWarningCode` 只返回最高优先级活动标准故障的编号。
2. `activeWarningCodes` 按上述优先级保存全部活动标准故障和数据异常编号。
3. `customWarning` 没有标准编号，不加入 `activeWarningCodes`。
4. 存在任意标准故障时，`customWarning` 不得覆盖主提示。
5. 主提示只取一项，但所有活动故障的控制限制必须合并生效。

示例：

| 同时存在的状态 | `primaryWarningCode` | `activeWarningCodes` |
| --- | --- | --- |
| 离线 + 普通低电量 | `WARN-003` | `WARN-003`, `WARN-001` |
| 离线 + 严重低电量 | `WARN-003` | `WARN-003`, `WARN-002` |
| 急停 + 设备故障 | `WARN-004` | `WARN-004`, `WARN-005` |
| 定位失败 + 路径受阻 | `WARN-006` | `WARN-006`, `WARN-007` |
| 普通低电量 + 任务执行失败 | `WARN-001` | `WARN-001`, `WARN-008` |
| 急停 + 电量数据异常 | `WARN-004` | `WARN-004`, `DATA-001` |

## 5. 任务安全动作

`TaskSafetyAction` 取值：

- `none`：不要求故障服务发出暂停或停止建议。
- `pause`：请求 App 通过统一控制流程暂停任务。
- `stop`：请求 App 通过统一控制流程停止任务。

动作规则：

- 紧急停止、设备故障、定位失败：`stop`
- 路径受阻：`pause`
- 其他状态：`none`
- 多个故障同时存在时：`stop > pause > none`

故障服务只返回 `safetyAction`，实际暂停或停止必须由 App 调用 `RobotController` 完成。

## 6. 控制权限

`true` 表示该按钮在仅存在对应单一状态时可以使用；`false` 表示必须禁用。

| 状态 | canStart | canPause | canResume | canStop | canCharge | canEmergencyStop | canReset |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 正常状态 | true | true | true | true | true | true | false |
| 紧急停止 | false | false | false | false | false | true | true |
| 设备离线 | false | false | false | false | false | false | false |
| 设备故障 | false | false | false | true | false | true | false |
| 电量数据异常 | false | true | false | true | true | true | false |
| 严重低电量 | false | true | true | true | true | true | false |
| 定位失败 | false | false | false | true | true | true | false |
| 路径受阻 | false | true | false | true | true | true | false |
| 普通低电量 | true | true | true | true | true | true | false |
| 任务执行失败 | true | true | true | true | true | true | false |
| customWarning | true | true | true | true | true | true | false |

组合状态下：

- 普通控制权限按所有活动限制取更严格结果。
- 设备离线覆盖全部控制权限，包括紧急停止和复位提交权限。
- `canReset` 仅在急停活动且设备在线时为 `true`。
- `requireReset` 只表示急停状态必须完成复位；它可以在离线时为 `true`，但此时 `canReset=false`，必须等待设备上线后再提交复位。
- 权限字段只描述 App 是否允许提交请求，不代表机器人动作已经执行成功。

## 7. 返回结果

`WarningResult` 至少包含：

| 字段 | 含义 |
| --- | --- |
| `primaryWarningCode` | 当前最高优先级标准故障编号；仅 customWarning 时为 `null` |
| `activeWarningCodes` | 全部活动标准故障编号，按优先级排列 |
| `message` | 主提示标准中文文案或 customWarning 文案 |
| `severity` | `high`、`medium`、`low`；无提示时为 `null` |
| `hasWarning` | 是否存在标准故障、数据异常或有效 customWarning |
| `batteryValid` | 电量是否在范围内且未报告传感器数据异常 |
| `safetyAction` | `none`、`pause`、`stop` |
| `canStart` 等七个权限字段 | 各控制按钮是否允许提交 |
| `requireReset` | 当前是否存在急停并要求完成复位 |

兼容字段 `warningCode`、`allowStart`、`allowControl`、`shouldPauseTask` 可以暂时保留，但新代码必须使用明确的新字段，任务动作必须以 `safetyAction` 为准。

## 8. 重复故障与安全要求

- 同一故障未解除前不得连续弹出相同提示或重复提交控制动作。
- 更高优先级故障出现时可以替换主提示，但不得丢弃其他活动标准故障。
- 故障解除后必须重新读取机器人最新状态，不得自动恢复旧任务。
- 故障提示服务不得直接修改机器人状态，不得调用 `RobotController`、控制 UI、访问网络或安装依赖。
- 所有实际控制操作必须由 App 的统一控制层处理，并检查 `RobotController` 的返回结果。

本文档只定义故障与安全提示规则，不包含 Flutter、插件或机器人控制实现。
