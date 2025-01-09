// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

contract MultiSigWallet{
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, uint256 amount, uint256 balance);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeTransaction(address indexed owner, uint256 indexed txIndex);

    struct Transaction{
        address from;
        address to;
        uint256 amount;
        bool executed;
        uint256 numConfirmations;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public minNumberConfirmationsRequired = 2;

    mapping(uint => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier txNotConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier txNotExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _addresses){
        require(_addresses.length > 3, "3 address required");

        _addresses = _addresses;

        for(uint i = 0; i < _addresses.length; i++){
            require(!isOwner[_addresses[i]], "owner not unique");

            address owner = _addresses[i];
            isOwner[owner] = true;
        }
    }

    function submitTransaction(address _to, uint256 _amount) public onlyOwner { 
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({
            from: msg.sender,
            to: _to,
            executed: false,
            amount: _amount,
            numConfirmations: minNumberConfirmationsRequired
        }));

        emit SubmitTransaction(msg.sender, txIndex, _amount, address(this).balance);
    }

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) txNotConfirmed(_txIndex) txNotExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(isOwner[transaction.from], "not owner");
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");

        isConfirmed[_txIndex][msg.sender] = true;
        transaction.numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) txNotExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= minNumberConfirmationsRequired, "not enough confirmations");
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.amount}("");
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) txNotExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransaction(msg.sender, _txIndex);
    }

    function getOwners() public view returns(address[] memory){
        return owners;
    }

    function getTransactionsCount() public view returns(uint){
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view txExists(_txIndex) returns(address, address, uint256, bool, uint256){
        Transaction storage transaction = transactions[_txIndex];
        return (transaction.from, transaction.to, transaction.amount, transaction.executed, transaction.numConfirmations);
    }
}