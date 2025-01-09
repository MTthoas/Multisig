// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/// @title MultiSigWallet
/// @notice Implements a multi-signature wallet for managing transactions with multiple owners.
/// @dev This contract allows for deposit, submission, confirmation, execution, and revocation of transactions.
contract MultiSigWallet {
    /// @notice Emitted when a deposit is made to the wallet.
    /// @param sender The address of the depositor.
    /// @param amount The amount deposited.
    /// @param balance The current balance of the wallet.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /// @notice Emitted when a transaction is submitted.
    /// @param owner The address of the owner who submitted the transaction.
    /// @param txIndex The index of the transaction in the transactions array.
    /// @param amount The amount to be transferred.
    /// @param balance The current balance of the wallet.
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, uint256 amount, uint256 balance);

    /// @notice Emitted when a transaction is confirmed.
    /// @param owner The address of the owner who confirmed the transaction.
    /// @param txIndex The index of the transaction in the transactions array.
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when a transaction is executed.
    /// @param owner The address of the owner who executed the transaction.
    /// @param txIndex The index of the transaction in the transactions array.
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when a transaction is revoked.
    /// @param owner The address of the owner who revoked the transaction.
    /// @param txIndex The index of the transaction in the transactions array.
    event RevokeTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Represents a transaction in the wallet.
    struct Transaction {
        address from; // The address of the owner who created the transaction.
        address to; // The address to which the funds will be sent.
        uint256 amount; // The amount to be transferred.
        bool executed; // Whether the transaction has been executed.
        uint256 numConfirmations; // The number of confirmations received for the transaction.
    }

    /// @notice List of wallet owners.
    address[] public owners;

    /// @notice Mapping to check if an address is an owner.
    mapping(address => bool) public isOwner;

    /// @notice Minimum number of confirmations required for a transaction to be executed.
    uint public minNumberConfirmationsRequired = 2;

    /// @notice Mapping to track if a transaction is confirmed by an owner.
    mapping(uint => mapping(address => bool)) public isConfirmed;

    /// @notice List of all transactions submitted to the wallet.
    Transaction[] public transactions;

    /// @notice Ensures that the caller is an owner of the wallet.
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    /// @notice Ensures that the transaction exists.
    /// @param _txIndex The index of the transaction to check.
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    /// @notice Ensures that the transaction is not already confirmed by the caller.
    /// @param _txIndex The index of the transaction to check.
    modifier txNotConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    /// @notice Ensures that the transaction is not already executed.
    /// @param _txIndex The index of the transaction to check.
    modifier txNotExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    /// @notice Initializes the wallet with a list of owners.
    /// @param _addresses List of addresses to be set as owners.
    constructor(address[] memory _addresses) {
        require(_addresses.length > 3, "3 address required");

        for (uint i = 0; i < _addresses.length; i++) {
            require(!isOwner[_addresses[i]], "owner not unique");

            address owner = _addresses[i];
            isOwner[owner] = true;
        }

        owners = _addresses;
    }

    /// @notice Submits a new transaction for approval.
    /// @param _to The address to send funds to.
    /// @param _amount The amount of funds to send.
    function submitTransaction(address _to, uint256 _amount) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({
            from: msg.sender,
            to: _to,
            executed: false,
            amount: _amount,
            numConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, _amount, address(this).balance);
    }

    /// @notice Confirms a transaction.
    /// @param _txIndex The index of the transaction to confirm.
    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) txNotConfirmed(_txIndex) txNotExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        isConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /// @notice Executes a transaction if it has enough confirmations.
    /// @param _txIndex The index of the transaction to execute.
    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) txNotExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= minNumberConfirmationsRequired, "not enough confirmations");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.amount}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /// @notice Revokes a confirmation for a transaction.
    /// @param _txIndex The index of the transaction to revoke.
    function revokeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) txNotExecuted(_txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransaction(msg.sender, _txIndex);
    }

    /// @notice Returns the list of wallet owners.
    /// @return List of wallet owners.
    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    /// @notice Returns the total number of transactions submitted to the wallet.
    /// @return Number of transactions.
    function getTransactionsCount() public view returns(uint) {
        return transactions.length;
    }

    /// @notice Returns the details of a specific transaction.
    /// @param _txIndex The index of the transaction to retrieve.
    /// @return from Address of the transaction creator.
    /// @return to Address of the transaction recipient.
    /// @return amount Amount of funds in the transaction.
    /// @return executed Whether the transaction has been executed.
    /// @return numConfirmations Number of confirmations the transaction has received.
    function getTransaction(uint _txIndex) public view txExists(_txIndex) returns(address, address, uint256, bool, uint256) {
        Transaction storage transaction = transactions[_txIndex];
        return (transaction.from, transaction.to, transaction.amount, transaction.executed, transaction.numConfirmations);
    }
}
