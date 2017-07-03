pragma solidity ^0.4.2;

contract FairBet {
    
    uint pendingBets = 0;
    address nextBetter = 0x0;
    
    address[] firstBetters = new address[](0);
    address[] secondBetters = new address[](0);
    uint[] blockNumbers = new uint[](0);
    
    uint256 betAmount = 1000000000000000000;
    uint256 price = 1998000000000000000;
    uint256 fee = 1000000000000000;
    
    address owner = 0x4962a8a2af62F387Fd3D0142e7c02fbb9D68e222;
    
    mapping(address => uint) refunds;
    
    function FairBet() {}
    
    function bet() payable {
        if (betAmount != msg.value) throw; //We need you to bet same amount as others
        finalizeBets(); //Since bet result is unnown until next block hash, we have to finalize bets when next person bets.
        addBet(); //Here you are betting with others.
        payFee(); //Note that this fee is smaller then gas price.
    }
    
    function finalizeBets() private {
        removeFinalizedBets(getFinalizedBetsCount());
    }
    
    function getFinalizedBetsCount() private returns (uint) {
        uint finalizedBetsCount = 0;
        while (finalizedBetsCount < firstBetters.length && finalizeBet(finalizedBetsCount)) {
            finalizedBetsCount++;
        }
        return finalizedBetsCount;
    }
    
    function finalizeBet(uint index) private returns (bool) {
        if (blockNumbers[index] < block.number) {
            address winner = chooseWinner(index);
            tryPay(winner, price);
            return true;
        } else {
            return false;
        }
    }
    
    function chooseWinner(uint index) private returns (address) {
        bytes32 hash = getHashForBlock(blockNumbers[index]);
        if ((hash & 0x1) == 0x1) { //Check if hash ends with 1.
            return firstBetters[index];
        } else {
            return secondBetters[index];
        }
    }
    
    function getHashForBlock(uint blockNumber) private returns (bytes32) {
        uint reachableBlockNumber = block.number - ((block.number - blockNumber) % 255) - 1;
        return block.blockhash(reachableBlockNumber);
    }
    
    function removeFinalizedBets(uint finalizedBetsCount) private {
        uint newLenght = firstBetters.length - finalizedBetsCount;
        for (uint index = 0; index < newLenght; index++) {
            firstBetters[index] = firstBetters[index + finalizedBetsCount];
            secondBetters[index] = secondBetters[index + finalizedBetsCount];
            blockNumbers[index] = blockNumbers[index + finalizedBetsCount];
        }
        firstBetters.length = newLenght;
        secondBetters.length = newLenght;
        blockNumbers.length = newLenght;
    }
    
    function addBet() private {
        if (pendingBets == 0) {
            pendingBets++;
            nextBetter = msg.sender;
        } else {
            if (nextBetter == msg.sender) {
                pendingBets++;
            } else {
                pendingBets--;
                firstBetters.push(nextBetter);
                secondBetters.push(msg.sender);
                blockNumbers.push(block.number + 1); //Next, non exisinting blockhash will determine winner.
            }
        }
    }
    
    function payFee() private {
        tryPay(owner, fee);
    }
    
    function withdrawRefund() external {
        uint refund = refunds[msg.sender];
        refunds[msg.sender] = 0;
        tryPay(msg.sender, refund);
    }
    
    function tryPay(address beneficient, uint amount) private {
        if (!beneficient.send(amount)) {
            refunds[beneficient] += amount; 
        }
    }
}
