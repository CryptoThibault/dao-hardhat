//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DAO {
  using Counters for Counters.Counter;
  IERC20 private _token;
  uint constant private _TIME_LIMIT = 3 days;

  enum Choice { Yes, No }
  enum Status { Running, Approved, Rejected }

  struct Proposal {
    string content;
    address author;
    uint256 createdAt;
    uint256 nbYes;
    uint256 nbNo;
    Status statu;
  }

  Counters.Counter private _id;
  mapping(uint => Proposal) private _proposals;
  mapping(address => uint) private _power;
  mapping(address => mapping(uint => uint)) private _powerUsed;

  constructor(address token_) {
    _token = IERC20(token_);
  }

  function lock(uint amount) public {
    _token.transferFrom(msg.sender, address(this), amount);
    _power[msg.sender] += amount;
  }

  function unlock(uint amount) public {
    require(amount <= _power[msg.sender]);
    _power[msg.sender] -= amount;
    _token.transfer(msg.sender, amount);
  }

  function createProposal(string memory content_) public returns (uint256) {
    _id.increment();
    uint id = _id.current();
    _proposals[id] = Proposal({
      content: content_,
      author: msg.sender,
      createdAt: block.timestamp,
      nbYes: 0,
      nbNo: 0,
      statu: Status.Running
    });
    return id;
  }

  function vote(uint id, Choice choice, uint power) public {
    require(proposalById(id).statu == Status.Running);
    require(block.timestamp < proposalById(id).createdAt + _TIME_LIMIT);
    require(power <= powerLeft(msg.sender, id));
    _powerUsed[msg.sender][id] += power;
    choice == Choice.Yes ? _proposals[id].nbYes += power : _proposals[id].nbNo += power;
    if (proposalById(id).nbYes - 1 >= stackTotal() / 2) {
      _proposals[id].statu = Status.Approved;
    } else if (proposalById(id).nbNo - 1 >= stackTotal() / 2) {
      _proposals[id].statu = Status.Rejected;
    }
  }

  function updateUnvoted(uint id) public {
    if (proposalById(id).statu == Status.Running && block.timestamp > proposalById(id).createdAt + _TIME_LIMIT) {
      _proposals[id].statu = Status.Rejected;
    }
  } 

  function proposalById(uint256 id) public view returns(Proposal memory) {
    return _proposals[id];
  }

  function stackTotal() public view returns (uint) {
    return _token.balanceOf(address(this));
  }

  function powerLeft(address account, uint id) public view returns (uint) {
    return _power[account] - _powerUsed[account][id];
  }
}