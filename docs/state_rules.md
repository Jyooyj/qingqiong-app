# 清穹机器人状态规则


## 状态

idle:
待机


cleaning:
清扫中


paused:
暂停


charging:
返回充电


emergency:
紧急停止


offline:
离线


error:
故障



## 状态转换


idle -> cleaning

cleaning -> paused

paused -> cleaning

cleaning -> idle

paused -> idle

任意状态 -> emergency

emergency -> idle