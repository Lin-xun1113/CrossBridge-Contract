// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface IMAGToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title MAGBridge
 * @dev Magnet POW和BSC之间的跨链桥接合约
 * @notice 包含紧急暂停功能，可在危险情况下暂停跨链操作
 */
contract MAGBridge is Ownable, Pausable {
    // BSC测试链上的MAG代币合约
    IMAGToken public immutable magToken;
    
    // 跨链转账事件
    event CrossChainTransfer(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 fee,
        uint256 timestamp,
        bytes32 txHash,
        uint256 confirmations,
        string status
    );
    
    // 跨链转出事件
    event CrossChainWithdraw(
        address indexed from,
        string destinationAddress,
        uint256 amount,
        uint256 fee,
        uint256 timestamp,
        string status
    );
    
    // 费用相关事件
    event FeeCollected(
        address indexed from,
        uint256 amount,
        uint256 fee,
        bytes32 indexed txHash,
        string operationType
    );
    
    // 费用设置更改事件
    event FeeSettingsUpdated(
        uint256 oldFeePercentage,
        uint256 newFeePercentage,
        address oldFeeCollector,
        address newFeeCollector
    );
    
    // 费用提取事件
    event FeesWithdrawn(
        address indexed to,
        uint256 indexed amount
    );
    
    // 已处理的跨链交易哈希
    mapping(bytes32 => bool) public processedTransactions;
    
    // 验证者地址
    mapping(address => bool) public validators;
    
    // 桥接设置
    uint256 public minConfirmations = 1;  // 最小确认数
    mapping(bytes32 => uint256) public confirmations;  // 交易确认计数
    mapping(bytes32 => mapping(address => bool)) public hasConfirmed;  // 验证者确认记录
    
    // 交易限制设置
    uint256 public maxTransactionAmount;     // 单笔跨链交易限额
    uint256 public minTransactionAmount;     // 单币跨链交易最小限额（避免gas费被刷爆）
    uint256 public dailyTransactionLimit;    // 每日跨链交易总限额
    uint256 public dailyTransactionTotal;    // 当日已处理跨链交易总额
    uint256 public lastResetTimestamp;       // 上次重置每日限额的时间
    
    // 费用设置
    uint256 public feePercentage;           // 费用百分比，以100的倍数表示，如 50 表示 0.5%
    address public feeCollector;            // 费用接收地址
    uint256 public collectedFees;            // 累计收取的费用
    
    /**
     * @dev 构造函数
     * @param _magToken MAG代币合约地址
     */
    constructor(address _magToken) Ownable(msg.sender){
        magToken = IMAGToken(_magToken);
        validators[msg.sender] = true; // 默认将部署者设为验证者
        
        // 初始化交易限额设置
        maxTransactionAmount = type(uint256).max;   // 默认单笔不限额
        dailyTransactionLimit = type(uint256).max; // 默认每日不限额
        minTransactionAmount = 10000 * 10**18; // 默认最小跨链金额1W MAG
        lastResetTimestamp = block.timestamp;
        
        // 初始化费用设置
        feePercentage = 50;                        // 默认费用 0.5%
        feeCollector = msg.sender;                  // 默认费用接收者为合约部署者
    }
    
    /**
     * @dev 添加验证者
     * @param validator 验证者地址
     */
    function addValidator(address validator) external onlyOwner {
        validators[validator] = true;
    }
    
    /**
     * @dev 移除验证者
     * @param validator 验证者地址
     */
    function removeValidator(address validator) external onlyOwner {
        validators[validator] = false;
    }
    
    /**
     * @dev 设置最小所需确认数
     * @param _minConfirmations 最小确认数
     */
    function setMinConfirmations(uint256 _minConfirmations) external onlyOwner {
        minConfirmations = _minConfirmations;
    }
    
    /**
     * @dev 暂停桥接操作 - 只能由所有者调用
     * @notice 在发现异常或安全问题时调用，暂停所有跨链操作
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev 恢复桥接操作 - 只能由所有者调用
     * @notice 在解决问题后调用，恢复跨链操作
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev 设置单笔交易最高限额 - 只能由所有者调用
     * @param _maxAmount 新的单笔交易限额
     */
    function setMaxTransactionAmount(uint256 _maxAmount) external onlyOwner {
        maxTransactionAmount = _maxAmount;
    }

    /**
     * @dev 设置单笔交易最低限额 - 只能由所有者调用
     * @param _minAmount 新的单笔交易最低限额
     */
    function setMinTransactionAmount(uint256 _minAmount) external onlyOwner {
        minTransactionAmount = _minAmount;
    }
    
    /**
     * @dev 设置每日交易总限额 - 只能由所有者调用
     * @param _dailyLimit 新的每日交易总限额
     */
    function setDailyTransactionLimit(uint256 _dailyLimit) external onlyOwner {
        dailyTransactionLimit = _dailyLimit;
    }
    
    /**
     * @dev 设置费用百分比 - 只能由所有者调用
     * @param _feePercentage 新的费用百分比，以100的倍数表示，如 50 表示 0.5%
     */
    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 1000, "Fee percentage too high"); // 最高费用不能超过 10%
        uint256 oldFeePercentage = feePercentage;
        feePercentage = _feePercentage;
        
        emit FeeSettingsUpdated(
            oldFeePercentage,
            _feePercentage,
            feeCollector,
            feeCollector
        );
    }
    
    /**
     * @dev 设置费用接收地址 - 只能由所有者调用
     * @param _feeCollector 新的费用接收地址
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Invalid address");
        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        
        emit FeeSettingsUpdated(
            feePercentage,
            feePercentage,
            oldFeeCollector,
            _feeCollector
        );
    }
    
    /**
     * @dev 提取累计的费用 - 只能由所有者调用
     * @notice 将收取的费用转给指定地址
     * @param recipient 费用接收地址
     */
    function withdrawFees(address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(collectedFees > 0, "No fees to withdraw");
        
        uint256 feesToWithdraw = collectedFees;
        collectedFees = 0;
        
        // 铸造费用到接收地址
        magToken.mint(recipient, feesToWithdraw);
        
        emit FeesWithdrawn(recipient, feesToWithdraw);
    }
    
    /**
     * @dev 计算费用 - 内部函数
     * @param amount 交易金额
     * @return fee 计算的费用
     */
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        return amount * feePercentage / 10000; // 计算费用，例如 0.5% = 0.005 = 50/10000
    }
    
    /**
     * @dev 重置每日交易统计 - 内部函数
     * @notice 每天自动重置每日交易额度计数
     */
    function _resetDailyLimitIfNeeded() internal {
        // 检查是否需要重置每日限额 (24小时 = 86400秒)
        if (block.timestamp >= lastResetTimestamp + 1 days) {
            dailyTransactionTotal = 0;
            lastResetTimestamp = block.timestamp;
        }
    }
    
    /**
     * @dev 验证并处理跨链转账，只能由验证者调用
     * @param txHash 原始MAGNET链上的交易哈希
     * @param recipient BSC上的接收者地址
     * @param amount 转账金额
     */
    function confirmTransaction(
        bytes32 txHash,
        address recipient,
        uint256 amount
    ) external whenNotPaused {
        require(validators[msg.sender], "Not a validator");
        require(!processedTransactions[txHash], "Transaction already processed");
        require(!hasConfirmed[txHash][msg.sender], "Validator already confirmed");
        
        // 记录验证者确认
        hasConfirmed[txHash][msg.sender] = true;
        confirmations[txHash]++;

        // @这里可以加一个event
        
        // 如果确认数达到阈值，则处理交易
        if (confirmations[txHash] >= minConfirmations) {
            // 检查交易金额是否超过单笔限额
            require(amount <= maxTransactionAmount, "Exceeds max transaction amount");

            // 检查交易金额是否低于单笔最低限额
            require(amount >= minTransactionAmount, "Below min transaction amount");
            
            // 检查并重置每日限额（如果必要）
            _resetDailyLimitIfNeeded();
            
            // 检查是否超过每日限额
            require(dailyTransactionTotal + amount <= dailyTransactionLimit, "Exceeds daily transaction limit");
            
            // 计算费用
            uint256 fee = _calculateFee(amount);
            uint256 amountAfterFee = amount - fee;
            
            // 更新当日交易总额
            dailyTransactionTotal += amount;
            
            // 更新累计收取的费用
            collectedFees += fee;
            
            processedTransactions[txHash] = true;
            
            // 在BSC上铸造对应的MAG代币 (扣除费用后的金额)
            magToken.mint(recipient, amountAfterFee);
            
            // 记录费用收取事件
            // @也许要改一下第一个参数
            emit FeeCollected(
                address(0),
                amount,
                fee,
                txHash,
                "deposit"
            );
            
            // 记录跨链转账事件
            emit CrossChainTransfer(
                address(0), // 从其他链转入，源地址不在BSC上
                recipient,
                amountAfterFee,
                fee,
                block.timestamp,
                txHash,
                confirmations[txHash],
                "success"
            );
        }
    }
    
    /**
     * @dev 将MAG代币从当前链转出到Magnet POW链
     * @param destinationAddress Magnet POW链上的目标地址
     * @param amount 转账金额
     */
    function withdraw(string memory destinationAddress, uint256 amount) external whenNotPaused {
        // 检查交易金额是否超过单笔限额
        require(amount <= maxTransactionAmount, "Exceeds max transaction amount");
        
        // 检查并重置每日限额（如果必要）
        _resetDailyLimitIfNeeded();
        
        // 检查是否超过每日限额
        require(dailyTransactionTotal + amount <= dailyTransactionLimit, "Exceeds daily transaction limit");
        
        // 计算费用
        uint256 fee = _calculateFee(amount);
        uint256 amountAfterFee = amount - fee;
        
        // 更新当日交易总额
        dailyTransactionTotal += amount;
        
        // 更新累计收取的费用
        collectedFees += fee;
        
        // 检查用户余额是否足够
        require(magToken.balanceOf(msg.sender) >= amount, "Insufficient MAG balance");
        
        // 销毁BSC上的MAG代币
        magToken.burn(msg.sender, amount);
        
        // 记录费用收取事件
        emit FeeCollected(
            msg.sender,
            amount,
            fee,
            bytes32(0), // 转出没有txHash
            "withdraw"
        );
        
        // 发送跨链转出事件，由链下验证者监听并执行转账
        emit CrossChainWithdraw(
            msg.sender,
            destinationAddress,
            amountAfterFee,
            fee,
            block.timestamp,
            "pending"
        );
    }
}
