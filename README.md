# MAG跨链桥智能合约

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

MAG跨链桥是为BSC链和Magnet POW链之间搭建的资产传输通道，实现这两条链上MAG代币的无缝流转。该项目基于Foundry框架开发。

## 相关项目

MAG跨链桥生态系统由多个组件组成，您可以访问以下相关项目：

- **[跨链桥验证者节点](https://github.com/Lin-xun1113/Validator-service)** - 负责监控、验证和处理跨链交易
- **[跨链桥前端界面](https://github.com/Lin-xun1113/CrossBridge-frontEnd/)** - 为用户和管理员提供的Web界面

## 项目概述

MAG跨链桥由三个核心合约组成：

1. **MAGBridge合约** - 部署在BSC链上，负责处理跨链转账、验证交易和收取手续费
2. **MAGToken合约** - 部署在BSC链上，为MAG代币的ERC20包装器
3. **MagnetMultiSig合约** - 部署在Magnet POW链上，负责跨链资产的管理和提款操作

## 合约功能

### MAGBridge合约

主要功能：
- 从POW链到BSC的存款处理
- 从BSC到POW链的提款操作
- 交易验证和安全控制
- 费率管理和收取
- 交易限额设置

### MAGToken合约

主要功能：
- 标准ERC20功能
- 与桥接合约集成的铸造和销毁接口
- 权限控制系统

### MagnetMultiSig合约

主要功能：
- 多签名交易提交与确认
- 安全的资金管理机制
- 紧急提款功能
- 所有者和权限管理
- 动态确认数调整

## 技术架构

跨链桥采用了验证者多签模式，确保资产跨链安全。

## 安装与部署

### 前置要求

- [Foundry](https://getfoundry.sh/)
- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/) (可选，用于前端测试)

### 安装

```bash
# 克隆仓库
git clone https://github.com/your-username/MAG-Cross-Bridge.git
cd MAG-Cross-Bridge/Contract

# 安装依赖
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
forge test
```

### 部署

```bash
# BSC测试网部署示例
forge script script/Deploy.s.sol:DeployScript --rpc-url <BSC测试网URL> --private-key <你的私钥> --broadcast

# Magnet POW链部署
# 请参考特定文档，Magnet POW链有不同的部署方法
```

## API接口

完整的API接口文档请参考 [API.md](./API.md)，该文档详细介绍了各合约的事件、读取和写入方法。

### 前端集成示例

#### 监听跨链转账事件
```javascript
const bridge = new ethers.Contract(bridgeAddress, bridgeABI, provider);

// 监听跨链转入事件
bridge.on("CrossChainTransfer", (from, to, amount, fee, timestamp, txHash, confirmations, status) => {
  console.log(`跨链转入: ${amount} MAG 到 ${to}, 费用: ${fee} MAG, 状态: ${status}`);
});
```

#### 发起跨链转出
```javascript
async function withdrawToPOW(destinationAddress, amount) {
  const bridge = new ethers.Contract(bridgeAddress, bridgeABI, signer);
  
  // 先授权桥接合约使用代币
  const token = new ethers.Contract(tokenAddress, tokenABI, signer);
  await token.approve(bridgeAddress, amount);
  
  // 调用跨链转出方法
  const tx = await bridge.withdraw(destinationAddress, amount);
  await tx.wait();
}
```

## 安全性

- 多重验证机制确保交易安全
- 多签名钱包管理资金
- 交易限额和日限额保护
- 紧急暂停功能
- 费用保障机制

## 开发团队

MAG跨链桥由MAG团队开发维护。

## 许可证

本项目采用MIT许可证 - 详细信息请查看[LICENSE](./LICENSE)文件。
