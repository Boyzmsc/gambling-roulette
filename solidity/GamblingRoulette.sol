//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
contract GamblingRoulette {
    /// 참여자 구조체
	struct Participant {
		address addr;	// 투자자의 어드레스
		uint amount;	// 투자액
	}

    address payable public owner;   // 컨트랙트 소유자
	uint public numParticipants;    // 참여자 수

	uint public totalBet;		    // 총 베팅금
	uint public baseBet;	        // 기본 베팅금
    uint public increaseRate;	    // 베팅금 증가 비율
    uint public requireBet;	        // 최소 필요 베팅금

    mapping (uint => Participant) public participants;  // 참여자 관리를 위한 매핑
	
	modifier onlyOwner () {
		require(msg.sender == owner);
		_;
	}
	
	/// 생성자
	constructor () {
		owner = payable(msg.sender);
		numParticipants = 0;

		totalBet = 0;
        baseBet = 10000;
        increaseRate = 0;
        requireBet = 10000;
	}
	
	/// 베팅 시에 호출되는 함수
	function bet() payable public {
        // 베팅금이 최소 필요 베팅금 이상일 때 진행
        require(requireBet <= msg.value);
		
        // 참여자 정보 확인
        bool exist = false;
        for (uint i = 0; i < numParticipants; i++) {
            // 배열에 있으면 베팅금 업데이트
            if (participants[i].addr == msg.sender) {
                // 참여자 베팅금 업데이트
                participants[i].amount += msg.value;
                exist = true;
                break;
            }
        }

        // 배열에 없으면 새롭게 추가
        if (!exist) {
            Participant storage p = participants[numParticipants++];
            p.addr = msg.sender;
            p.amount = msg.value;
        }

        // 총 베팅금 업데이트
		totalBet += msg.value;
	}

    /// 베팅금 증가 비율 증가 (룰렛) 당첨 시
    function changeRate(uint rate) public {
        // 베팅금 증가 비율 업데이트
        increaseRate += rate;

        // 최소 필요 베팅금 업데이트
        // 정수만 지원하는 관계로 덧셈 수식 이용
        requireBet = baseBet + increaseRate * 100;
    }
	
    /// 특정 참여자에게 베팅금 전액 송금
    function sendBetToSomeone(address addr) public {
        // 특정 참여자가 배열에 있는지 확인 & 인덱스 확인
        uint idx;
        bool exist = false;
        for (uint i = 0; i < numParticipants; i++) {
            if (participants[i].addr == addr) {
                idx = i;
                exist = true;
                break;
            }
        }

        // 특정 참여자가 베팅을 했는지 검사
        require(exist);
        
        // 특정 참여자에게 총 베팅금 송금
        if(!payable(participants[idx].addr).send(totalBet)) {
			revert();
		}

        // 베팅 시스템 초기화
        numParticipants = 0;
		totalBet = 0;
        baseBet = 10000;
        increaseRate = 0;
        requireBet = 10000;
    }

    /// 컨트랙트의 잔액 출력
    function getBalance() view public returns(uint) {
		return address(this).balance;
	}

	/// 컨트랙트를 소멸시키기 위한 함수
	function kill() public onlyOwner {
		selfdestruct(owner);
	}
}
