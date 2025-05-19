// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MagnetMultiSig
 * @dev Magnet POW链上的多签钱包合约，用于管理跨链桥的提款操作
 */
contract MagnetMultiSig {
    // 多签所有者列表
    address[] public owners;
    // 所需确认数
    uint256 public requiredConfirmations;
    // 交易ID计数器
    uint256 public transactionCount;

    // 初始创建者，有特殊权限管理多签钱包
    address public immutable INITER;
    
    // 交易结构体
    struct Transaction {
        address destination; // 目标地址
        uint256 value;      // 转账金额
        bool executed;      // 是否已执行
        bytes data;         // 调用数据（如果需要）
    }
    
    // 交易ID => 交易详情
    mapping(uint256 => Transaction) public transactions;
    // 交易ID => 所有者地址 => 是否已确认
    mapping(uint256 => mapping(address => bool)) public confirmations;
    // 地址 => 是否为所有者
    mapping(address => bool) public isOwner;
    
    // 事件
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event EmergencyWithdrawal(address indexed initiator, address indexed recipient, uint256 amount);
    
    // 修饰符
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }
    
    modifier onlyIniter() {
        require(msg.sender == INITER, "Only INITER can call this function");
        _;
    }
    
    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0), "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }
    
    modifier notConfirmed(uint256 transactionId) {
        require(!confirmations[transactionId][msg.sender], "Transaction already confirmed");
        _;
    }
    
    /**
     * @dev 构造函数 - 创建多签钱包并设置初始所有者和确认数
     * @param _owners 初始所有者地址列表
     * @param _required 所需确认数
     */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0, "Required confirmations must be greater than 0");
        require(_required <= _owners.length, "Required confirmations exceeds owner count");
        
        // 设置所有者
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");
            
            isOwner[owner] = true;
            owners.push(owner);
        }

        INITER = msg.sender;
        
        requiredConfirmations = _required;
    }
    
    /**
     * @dev 接收原生代币
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * @dev 提交新交易
     * @param destination 目标地址
     * @param value 转账金额
     * @param data 调用数据
     * @return 交易ID
     */
    function submitTransaction(address destination, uint256 value, bytes memory data) 
        public
        onlyOwner
        returns (uint256)
    {
        uint256 transactionId = transactionCount;
        
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            executed: false,
            data: data
        });
        
        transactionCount += 1;
        emit Submission(transactionId);
        
        // 自动确认
        confirmTransaction(transactionId);
        
        return transactionId;
    }
    
    /**
     * @dev 确认交易
     * @param transactionId 交易ID
     */
    function confirmTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
        notConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        
        // 如果确认数已达到要求，执行交易
        executeTransaction(transactionId);
    }
    
    /**
     * @dev 执行交易
     * @param transactionId 交易ID
     */
    function executeTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txItem = transactions[transactionId];
            txItem.executed = true;
            
            (bool success, ) = txItem.destination.call{value: txItem.value}(txItem.data);
            if (success) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                txItem.executed = false;
            }
        }
    }
    
    /**
     * @dev 撤销确认
     * @param transactionId 交易ID
     */
    function revokeConfirmation(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        require(confirmations[transactionId][msg.sender], "Transaction not confirmed");
        
        confirmations[transactionId][msg.sender] = false;
        emit Confirmation(msg.sender, transactionId);
    }
    
    /**
     * @dev 检查交易是否已确认（确认数已达到要求）
     * @param transactionId 交易ID
     * @return 是否已确认
     */
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        return getConfirmationCount(transactionId) >= requiredConfirmations;
    }
    
    /**
     * @dev 获取交易的确认数
     * @param transactionId 交易ID
     * @return 确认数
     */
    function getConfirmationCount(uint256 transactionId) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }
    
    /**
     * @dev 获取交易的确认地址列表
     * @param transactionId 交易ID
     * @return 确认该交易的地址列表
     */
    function getConfirmations(uint256 transactionId) public view returns (address[] memory) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        
        address[] memory confirmedAddresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            confirmedAddresses[i] = confirmationsTemp[i];
        }
        
        return confirmedAddresses;
    }
    
    /**
     * @dev 获取所有所有者地址
     * @return 所有者地址列表
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }
    
    /**
     * @dev 获取所有待处理交易ID
     * @return 交易ID列表
     */
    function getPendingTransactions() public view returns (uint256[] memory) {
        uint256[] memory pendingTemp = new uint256[](transactionCount);
        uint256 count = 0;
        
        for (uint256 i = 0; i < transactionCount; i++) {
            if (!transactions[i].executed) {
                pendingTemp[count] = i;
                count += 1;
            }
        }
        
        uint256[] memory pendingTransactions = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            pendingTransactions[i] = pendingTemp[i];
        }
        
        return pendingTransactions;
    }
    
    /**
     * @dev INITER添加新的所有者
     * @param owner 新所有者地址
     */
    function addOwner(address owner) public onlyIniter {
        require(owner != address(0), "Invalid owner address");
        require(!isOwner[owner], "Owner already exists");
        require(owners.length < 50, "Max owners reached");
        
        isOwner[owner] = true;
        owners.push(owner);
        
        emit OwnerAddition(owner);
    }
    
    /**
     * @dev INITER移除现有所有者
     * @param owner 要移除的所有者地址
     */
    function removeOwner(address owner) public onlyIniter {
        require(isOwner[owner], "Not an owner");
        require(owners.length > requiredConfirmations, "Cannot remove owner below required confirmations");
        
        isOwner[owner] = false;
        
        // 找到并移除所有者数组中的地址
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                // 用最后一个元素替换当前位置，然后缩减数组长度
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        
        // 如果确认数超过所有者数量，则调整确认数
        if (requiredConfirmations > owners.length) {
            changeRequirement(owners.length);
        }
        
        emit OwnerRemoval(owner);
    }
    
    /**
     * @dev INITER修改所需确认数
     * @param required 新的所需确认数
     */
    function changeRequirement(uint256 required) public onlyIniter {
        require(required > 0, "Required confirmations must be greater than 0");
        require(required <= owners.length, "Required confirmations exceeds owner count");
        
        requiredConfirmations = required;
        
        emit RequirementChange(required);
    }

    /**
     * @dev 紧急情况下提取合约中的资金 - 仅INITER可调用
     * @param amount 提取金额
     * @param recipient 接收者地址
     */
    function emergencyWithdraw(uint256 amount, address payable recipient) public onlyIniter {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        require(recipient != address(0), "Recipient cannot be zero address");
        
        // Send ETH
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Withdrawal failed");        
        emit EmergencyWithdrawal(msg.sender, recipient, amount);
    }
}
