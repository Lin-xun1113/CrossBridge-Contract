# MAG跨链桥前端接口文档

本文档详细说明了MAG跨链桥智能合约的前端接口，包括合约事件、函数的参数、返回值及其作用，供前端开发人员集成使用。

## 目录
1. [MAGBridge合约](#magbridge合约)
   - [事件](#bridge-events)
   - [读取方法](#bridge-read)
   - [写入方法](#bridge-write)
2. [MAGToken合约](#magtoken合约)
   - [事件](#token-events)
   - [读取方法](#token-read)
   - [写入方法](#token-write)

<a id="magbridge合约"></a>
## MAGBridge合约

MAGBridge合约是BSC链和Magnet POW链之间的桥接合约，用于处理代币的跨链转移。

<a id="bridge-events"></a>
### 事件

#### CrossChainTransfer
**说明**: 当用户从Magnet POW链转入BSC链时触发的事件
**参数**:
- `address indexed from`: 源地址（对于从POW链转入，通常为address(0)）
- `address indexed to`: 接收地址
- `uint256 amount`: 转账金额（扣除费用后）
- `uint256 fee`: 收取的费用
- `uint256 timestamp`: 交易时间戳
- `bytes32 txHash`: 原始链上的交易哈希
- `uint256 confirmations`: 确认数
- `string status`: 交易状态（success/failed）

#### CrossChainWithdraw
**说明**: 当用户从BSC链转出到Magnet POW链时触发的事件
**参数**:
- `address indexed from`: 发送地址
- `string destinationAddress`: 目标链上的接收地址
- `uint256 amount`: 转账金额（扣除费用后）
- `uint256 fee`: 收取的费用
- `uint256 timestamp`: 交易时间戳
- `string status`: 交易状态（pending/success/failed）

#### FeeCollected
**说明**: 收取跨链交易费用时触发的事件
**参数**:
- `address indexed from`: 费用来源地址
- `uint256 amount`: 原始交易金额
- `uint256 fee`: 收取的费用
- `bytes32 indexed txHash`: 相关交易哈希
- `string operationType`: 操作类型（deposit/withdraw）

#### FeeSettingsUpdated
**说明**: 费用设置更新时触发的事件
**参数**:
- `uint256 oldFeePercentage`: 旧的费用百分比
- `uint256 newFeePercentage`: 新的费用百分比
- `address oldFeeCollector`: 旧的费用接收地址
- `address newFeeCollector`: 新的费用接收地址

#### FeesWithdrawn
**说明**: 累计费用被提取时触发的事件
**参数**:
- `address indexed to`: 接收费用的地址
- `uint256 amount`: 提取的费用金额

<a id="bridge-read"></a>
### 读取方法

#### magToken()
**说明**: 获取关联的MAG代币合约地址
**参数**: 无
**返回值**: `address` - MAG代币合约地址

#### processedTransactions(bytes32 txHash)
**说明**: 检查交易是否已经处理
**参数**: 
- `bytes32 txHash`: 交易哈希
**返回值**: `bool` - 是否已处理

#### validators(address validator)
**说明**: 检查地址是否为验证者
**参数**: 
- `address validator`: 要检查的地址
**返回值**: `bool` - 是否为验证者

#### minConfirmations()
**说明**: 获取最小所需确认数
**参数**: 无
**返回值**: `uint256` - 最小确认数

#### confirmations(bytes32 txHash)
**说明**: 获取某笔交易的当前确认数
**参数**:
- `bytes32 txHash`: 交易哈希
**返回值**: `uint256` - 当前确认数

#### hasConfirmed(bytes32 txHash, address validator)
**说明**: 检查验证者是否已确认某笔交易
**参数**:
- `bytes32 txHash`: 交易哈希
- `address validator`: 验证者地址
**返回值**: `bool` - 是否已确认

#### maxTransactionAmount()
**说明**: 获取单笔交易最高限额
**参数**: 无
**返回值**: `uint256` - 单笔交易最高限额

#### minTransactionAmount()
**说明**: 获取单笔交易最低限额
**参数**: 无
**返回值**: `uint256` - 单笔交易最低限额

#### dailyTransactionLimit()
**说明**: 获取每日交易总限额
**参数**: 无
**返回值**: `uint256` - 每日交易总限额

#### dailyTransactionTotal()
**说明**: 获取当日已处理的交易总额
**参数**: 无
**返回值**: `uint256` - 当日交易总额

#### lastResetTimestamp()
**说明**: 获取上次重置每日限额的时间
**参数**: 无
**返回值**: `uint256` - 时间戳

#### feePercentage()
**说明**: 获取当前费用百分比
**参数**: 无
**返回值**: `uint256` - 费用百分比（50表示0.5%）

#### feeCollector()
**说明**: 获取费用接收地址
**参数**: 无
**返回值**: `address` - 费用接收地址

#### collectedFees()
**说明**: 获取累计收取的费用
**参数**: 无
**返回值**: `uint256` - 累计费用

#### paused()
**说明**: 检查合约是否处于暂停状态
**参数**: 无
**返回值**: `bool` - 是否暂停

<a id="bridge-write"></a>
### 写入方法

#### addValidator(address validator)
**说明**: 添加验证者
**权限**: 仅合约所有者可调用
**参数**:
- `address validator`: 要添加的验证者地址
**返回值**: 无

#### removeValidator(address validator)
**说明**: 移除验证者
**权限**: 仅合约所有者可调用
**参数**:
- `address validator`: 要移除的验证者地址
**返回值**: 无

#### setMinConfirmations(uint256 _minConfirmations)
**说明**: 设置最小所需确认数
**权限**: 仅合约所有者可调用
**参数**:
- `uint256 _minConfirmations`: 新的最小确认数
**返回值**: 无

#### pause()
**说明**: 暂停合约功能
**权限**: 仅合约所有者可调用
**参数**: 无
**返回值**: 无

#### unpause()
**说明**: 恢复合约功能
**权限**: 仅合约所有者可调用
**参数**: 无
**返回值**: 无

#### setMaxTransactionAmount(uint256 _maxAmount)
**说明**: 设置单笔交易限额
**权限**: 仅合约所有者可调用
**参数**:
- `uint256 _maxAmount`: 新的单笔交易限额
**返回值**: 无

#### setDailyTransactionLimit(uint256 _dailyLimit)
**说明**: 设置每日交易总限额
**权限**: 仅合约所有者可调用
**参数**:
- `uint256 _dailyLimit`: 新的每日交易总限额
**返回值**: 无

#### setFeePercentage(uint256 _feePercentage)
**说明**: 设置费用百分比
**权限**: 仅合约所有者可调用
**参数**:
- `uint256 _feePercentage`: 新的费用百分比（50表示0.5%）
**返回值**: 无

#### setFeeCollector(address _feeCollector)
**说明**: 设置费用接收地址
**权限**: 仅合约所有者可调用
**参数**:
- `address _feeCollector`: 新的费用接收地址
**返回值**: 无

#### withdrawFees(address recipient)
**说明**: 提取累计的费用
**权限**: 仅合约所有者可调用
**参数**:
- `address recipient`: 费用接收地址
**返回值**: 无

#### confirmTransaction(bytes32 txHash, address recipient, uint256 amount)
**说明**: 验证并处理跨链转账
**权限**: 仅验证者可调用，合约未暂停时
**参数**:
- `bytes32 txHash`: 原始链上的交易哈希
- `address recipient`: 接收地址
- `uint256 amount`: 转账金额
**返回值**: 无

#### withdraw(string memory destinationAddress, uint256 amount)
**说明**: 将MAG代币从BSC转出到Magnet POW链
**权限**: 任何用户，合约未暂停时
**参数**:
- `string memory destinationAddress`: 目标链上的接收地址
- `uint256 amount`: 转账金额
**返回值**: 无

<a id="magtoken合约"></a>
## MAGToken合约

MAGToken合约是BSC测试网上代表Magnet POW原生代币的ERC20代币。

<a id="token-events"></a>
### 事件

#### BridgeContractChanged
**说明**: 当桥接合约地址被更改时触发
**参数**:
- `address indexed oldBridge`: 旧的桥接合约地址
- `address indexed newBridge`: 新的桥接合约地址

#### Transfer（ERC20标准事件）
**说明**: 代币转账时触发
**参数**:
- `address indexed from`: 发送地址
- `address indexed to`: 接收地址
- `uint256 value`: 转账金额

#### Approval（ERC20标准事件）
**说明**: 授权代币使用时触发
**参数**:
- `address indexed owner`: 代币所有者
- `address indexed spender`: 被授权的地址
- `uint256 value`: 授权金额

<a id="token-read"></a>
### 读取方法

#### name()
**说明**: 获取代币名称
**参数**: 无
**返回值**: `string` - 代币名称

#### symbol()
**说明**: 获取代币符号
**参数**: 无
**返回值**: `string` - 代币符号

#### decimals()
**说明**: 获取代币小数位数
**参数**: 无
**返回值**: `uint8` - 小数位数

#### totalSupply()
**说明**: 获取代币总供应量
**参数**: 无
**返回值**: `uint256` - 总供应量

#### balanceOf(address account)
**说明**: 查询账户余额
**参数**:
- `address account`: 要查询的账户地址
**返回值**: `uint256` - 账户余额

#### allowance(address owner, address spender)
**说明**: 查询授权额度
**参数**:
- `address owner`: 代币所有者
- `address spender`: 被授权的地址
**返回值**: `uint256` - 授权额度

#### bridgeContract()
**说明**: 获取当前桥接合约地址
**参数**: 无
**返回值**: `address` - 桥接合约地址

#### owner()
**说明**: 获取合约所有者地址
**参数**: 无
**返回值**: `address` - 所有者地址

<a id="token-write"></a>
### 写入方法

#### setBridgeContract(address _bridgeContract)
**说明**: 设置桥接合约地址
**权限**: 仅合约所有者可调用
**参数**:
- `address _bridgeContract`: 新的桥接合约地址
**返回值**: 无

#### mint(address to, uint256 amount)
**说明**: 铸造代币
**权限**: 仅桥接合约可调用
**参数**:
- `address to`: 接收者地址
- `uint256 amount`: 代币数量
**返回值**: 无

#### burn(address from, uint256 amount)
**说明**: 销毁代币
**权限**: 仅桥接合约可调用
**参数**:
- `address from`: 销毁来源地址
- `uint256 amount`: 代币数量
**返回值**: 无

#### transfer(address to, uint256 amount)
**说明**: 转账代币
**权限**: 任何持币者
**参数**:
- `address to`: 接收者地址
- `uint256 amount`: 代币数量
**返回值**: `bool` - 是否成功

#### approve(address spender, uint256 amount)
**说明**: 批准他人使用代币
**权限**: 任何持币者
**参数**:
- `address spender`: 被授权的地址
- `uint256 amount`: 授权金额
**返回值**: `bool` - 是否成功

#### transferFrom(address from, address to, uint256 amount)
**说明**: 从授权账户转账
**权限**: 被授权的地址
**参数**:
- `address from`: 发送地址
- `address to`: 接收地址
- `uint256 amount`: 转账金额
**返回值**: `bool` - 是否成功

## 前端集成示例

### 监听跨链转账事件

```javascript
const bridge = new ethers.Contract(bridgeAddress, bridgeABI, provider);

// 监听跨链转入事件
bridge.on("CrossChainTransfer", (from, to, amount, fee, timestamp, txHash, confirmations, status) => {
  console.log(`跨链转入: ${amount} MAG 到 ${to}, 费用: ${fee} MAG, 状态: ${status}`);
  // 更新UI显示等操作
});

// 监听跨链转出事件
bridge.on("CrossChainWithdraw", (from, destinationAddress, amount, fee, timestamp, status) => {
  console.log(`跨链转出: ${amount} MAG 到 ${destinationAddress}, 费用: ${fee} MAG, 状态: ${status}`);
  // 更新UI显示等操作
});
```

### 发起跨链转出

```javascript
async function withdrawToPOW(destinationAddress, amount) {
  const bridge = new ethers.Contract(bridgeAddress, bridgeABI, signer);
  
  // 先授权桥接合约使用代币
  const token = new ethers.Contract(tokenAddress, tokenABI, signer);
  await token.approve(bridgeAddress, amount);
  
  // 调用跨链转出方法
  const tx = await bridge.withdraw(destinationAddress, amount);
  const receipt = await tx.wait();
  
  console.log("跨链转出交易已提交:", receipt.transactionHash);
}
```

### 查询跨链状态和费率

```javascript
async function getBridgeStatus() {
  const bridge = new ethers.Contract(bridgeAddress, bridgeABI, provider);
  
  const feePercentage = await bridge.feePercentage();
  const maxAmount = await bridge.maxTransactionAmount();
  const dailyLimit = await bridge.dailyTransactionLimit();
  const dailyUsed = await bridge.dailyTransactionTotal();
  const isPaused = await bridge.paused();
  
  return {
    feeRate: `${feePercentage / 100}%`,
    maxSingleTransaction: ethers.utils.formatEther(maxAmount),
    dailyLimit: ethers.utils.formatEther(dailyLimit),
    dailyUsed: ethers.utils.formatEther(dailyUsed),
    bridgeStatus: isPaused ? "暂停中" : "运行中"
  };
}
```

请根据实际项目需求调整以上接口文档和示例代码。
