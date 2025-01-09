// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MultiSigWallet{
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, uint256 amount, uint256 balance);

    struct Transaction{
        address from;
        address to;
        uint256 amount;
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

    constructor(address[] memory _addresses){
        require(_addresses.length > 3, "3 address required");

        _addresses = _addresses;

        for(uint i = 0; i < _addresses.length; i++){
            require(!isOwner[_addresses[i]], "owner not unique");

            address owner = _addresses[i];
            isOwner[owner] = true;
        }
    }

    function submitTransaction(address _to, uint256 _amount) public onlyOwner{
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({
            from: msg.sender,
            to: _to,
            amount: _amount
        }));

        emit SubmitTransaction(msg.sender, txIndex, _amount, address(this).balance);
    }
}