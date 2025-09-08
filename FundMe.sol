// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping (address=>uint256) public fundersToAmount;

    address public owner;

    uint256 MINIMUM_VALUE = 1; // $USD
    uint256 TARGET = 10000;
    uint256 deploymentTimestamp;
    uint256 lockTime;

    AggregatorV3Interface internal dataFeed;

    constructor(uint256 _lockTime) {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        owner = msg.sender;
        deploymentTimestamp = block.timestamp;
        lockTime = _lockTime;
    }

    function fund() external payable {
        require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "Send more ETH");
        require(block.timestamp < deploymentTimestamp + lockTime, "Funding period has ended");
        fundersToAmount[msg.sender] = msg.value;
    }

     /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            uint80 roundId,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        require(roundId > 0, "Invalid round ID");
        require(answer > 0, "Invalid price");
        return answer;
    }
 
    
    function convertEthToUsd(uint256 ethAmount) internal  view returns(uint256) {
            int256 ethPrice = getChainlinkDataFeedLatestAnswer();
            require(ethPrice > 0, "Invalid Price");
            return uint256(ethPrice) * ethAmount / (1e8 * 1e18);
    }

    function transferOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    } 

    function getFund() external windowsClosed onlyOwner{
        require (convertEthToUsd(address(this).balance) >= TARGET, "Target is not reached");
   
       bool success;
       (success,) = payable (msg.sender).call{value: address(this).balance}("");
       require(success, "get Fund failed");

    }

    function refund() external windowsClosed  {
        require (convertEthToUsd(address(this).balance) < TARGET, "Target is  reached");

        require(fundersToAmount[msg.sender]!=0, "not attend fund");
      
        bool success;
        (success,) = payable (msg.sender).call{value:fundersToAmount[msg.sender]}("");
        require(success, "refund failed!");
        fundersToAmount[msg.sender] = 0;
    }

    modifier  windowsClosed(){
        require(block.timestamp >= deploymentTimestamp + lockTime, "Deadline of fund not reached");
        _;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }
 

}