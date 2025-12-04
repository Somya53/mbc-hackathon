// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract TaskAutomator {
    enum TaskType { Swap, NFTPurchase, Notify }

    struct Task {
        address user;
        TaskType taskType;
        address token;      // ERC20 token for swaps, or NFT contract for NFTPurchase
        uint256 tokenId;    // for NFTPurchase
        uint256 amount;     // for Swap or payments
        string action;      // description
        uint256 nextExecution;
        uint256 interval;
        bool active;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    event TaskCreated(uint256 taskId, address user, TaskType taskType, string action);
    event TaskExecuted(uint256 taskId, TaskType taskType, string action);
    event TaskCancelled(uint256 taskId);

    // Create a task
    function createTask(
        TaskType taskType,
        address token,
        uint256 tokenId,
        uint256 amount,
        string memory action,
        uint256 interval
    ) public returns (uint256) {
        taskCount++;

        tasks[taskCount] = Task({
            user: msg.sender,
            taskType: taskType,
            token: token,
            tokenId: tokenId,
            amount: amount,
            action: action,
            nextExecution: block.timestamp + interval,
            interval: interval,
            active: true
        });

        emit TaskCreated(taskCount, msg.sender, taskType, action);
        return taskCount;
    }

    // Cancel a task
    function cancelTask(uint256 taskId) public {
        require(tasks[taskId].user == msg.sender, "Not task owner");
        tasks[taskId].active = false;
        emit TaskCancelled(taskId);
    }

    // Run a task (called by AgentKit or an off-chain agent)
    function runTask(uint256 taskId) public {
        Task storage task = tasks[taskId];
        require(task.active, "Inactive");
        require(block.timestamp >= task.nextExecution, "Not ready");

        if (task.taskType == TaskType.Swap) {
            // For token swaps, AgentKit handles actual swap logic off-chain
            // Optionally: pull ERC20 from user if pre-approved
            IERC20(task.token).transferFrom(task.user, address(this), task.amount);
        } else if (task.taskType == TaskType.NFTPurchase) {
            // For NFT purchase, AgentKit will trigger off-chain logic
            // Placeholder: emit event so agent can act
        } else if (task.taskType == TaskType.Notify) {
            // Just emit notification event
        }

        emit TaskExecuted(taskId, task.taskType, task.action);
        task.nextExecution = block.timestamp + task.interval;
    }
}
