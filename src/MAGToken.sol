// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MAGToken
 * @dev BSC测试网上代表Magnet POW原生代币的ERC20代币
 */
contract MAGToken is ERC20, Ownable {
    address public bridgeContract;
    
    // 事件
    event BridgeContractChanged(address indexed oldBridge, address indexed newBridge);
    
    /**
     * @dev 构造函数 - 创建MAG代币，初始供应量为1000亿
     */
    constructor() ERC20("Magnlet", "MAG") Ownable(msg.sender) {
        // 初始不铸造任何代币
    }
    
    /**
     * @dev 设置桥接合约地址
     * @param _bridgeContract 新的桥接合约地址
     */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        address oldBridge = bridgeContract;
        bridgeContract = _bridgeContract;
        emit BridgeContractChanged(oldBridge, _bridgeContract);
    }
    
    /**
     * @dev 铸造代币 - 只能由桥接合约调用
     * @param to 接收者地址
     * @param amount 代币数量
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == bridgeContract, "Only bridge can mint");
        _mint(to, amount);
    }
    
    /**
     * @dev 销毁代币 - 只能由桥接合约调用
     * @param from 销毁来源地址
     * @param amount 代币数量
     */
    function burn(address from, uint256 amount) external {
        require(msg.sender == bridgeContract, "Only bridge can burn");
        _burn(from, amount);
    }
}
