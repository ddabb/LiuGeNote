---
title: hdc 常用命令速查：安装、日志与调试一条龙
tags: [hdc, 调试, 命令行, HarmonyOS, 工具链]
description: 整理 HarmonyOS 设备连接工具 hdc 的高频命令：设备管理、应用安装卸载、hilog 日志过滤、aa 启动与调试、文件推拉，配合开发日常的查错场景逐条说明。
---

# hdc 常用命令速查：安装、日志与调试一条龙

`hdc`（HarmonyOS Device Connector）是鸿蒙版的 adb。命令行装包、抓日志、拉文件，比反复点 IDE 快得多。

## 设备管理

```bash
hdc list targets            # 列出已连接设备
hdc tconn 127.0.0.1:5555   # 连接模拟器/无线设备
hdc -t <serial> shell      # 多设备时用 -t 指定目标
```

## 应用安装与卸载

```bash
hdc install entry-default-signed.hap          # 安装
hdc install -r entry-default-signed.hap       # 覆盖安装（保留数据）
hdc uninstall com.example.xingzhi             # 卸载
hdc shell bm dump -n com.example.xingzhi      # 查看已装应用信息
```

签名不对会报 `Failure[ERR_INSTALL_FAILED_SIGNATURE]`——先确认签名证书再折腾命令参数。

## 日志

```bash
hdc shell hilog                              # 全量日志流
hdc shell hilog | grep xingzhi               # 按应用名过滤
hdc shell hilog -x                           # 历史日志（含崩溃前的）
hdc shell hilog -r                           # 清空日志缓冲
hdc shell hilog -D 0x0001                    # 按 domain 过滤
hdc file recv /data/log/hilog/ ./logs/       # 把日志目录拉到本地
```

崩溃排障组合拳：`hilog -x` 看崩溃前最后几百行 + `findstr/grep` 应用包名，比 IDE 日志窗稳。

## 启动与调试

```bash
hdc shell aa start -a EntryAbility -b com.example.xingzhi   # 启动应用
hdc shell aa force-stop com.example.xingzhi                 # 强制停止
hdc shell ps -ef | grep xingzhi                             # 确认进程存活
```

## 文件推拉

```bash
hdc file send ./local.txt /data/local/tmp/    # 推到设备
hdc file recv /data/local/tmp/remote.txt ./   # 拉到本地
```

沙箱目录（`/data/app/el2/100/base/<bundle>/`）需要应用有权限，临时文件放 `/data/local/tmp/` 最省事。

## 屏幕截图

```bash
hdc shell snapshot_display -f /data/local/tmp/screen.jpeg
hdc file recv /data/local/tmp/screen.jpeg ./
```

截图验收、提审素材、问题复现，一条龙。

## 实用习惯

1. 把 `hdc` 所在 `toolchains` 目录加进 PATH，别每次找 SDK 目录；
2. 日志过滤优先用 hilog 的 `-D`/tag 参数，`grep` 是兜底；
3. 「应用装不上」先 `bm dump` 看旧版本签名是否一致，再谈别的。

## 一句话总结

日常开发三板斧：**list targets 看连接、install -r 秒装包、hilog -x 查崩溃**。练熟这三条，命令行就是最快的 IDE。
